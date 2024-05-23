#include <Adafruit_NeoPixel.h>
#include <GyverPortal.h>
#include <TimeLib.h>
#include <ESP8266WiFi.h>
#include <ESP8266mDNS.h>
#include <DNSServer.h>
#include <ESP8266WebServer.h>
#include <WiFiManager.h>
#include "NTPClient.h"
#include "WiFiUdp.h"
#include <EEPROM.h>

String ssid = "";
String password = "";
#define onboardLed 2
ESP8266WebServer server(89);

// String serverDnsName = "babytimer";
String serverDnsName = "testtimer";

unsigned long myTimerMillisForUpdateValues;
unsigned long previousMillis = 0UL;
unsigned long timeInterval = 1000UL;
unsigned long manualTimerSetThreshold = 3000;
time_t currentEpochTime;
int pixelDivisionValue;

int counter = 0;

#define NUM_LEDS 38
#define DATA_PIN D4
#define BRIGHTNESS 50
#define LED_TYPE NEO_GRB // Adafruit_NeoPixel uses a different naming convention
#define FRAMES_PER_SECOND 120

Adafruit_NeoPixel strip = Adafruit_NeoPixel(NUM_LEDS, DATA_PIN, LED_TYPE);

const long utcOffsetInSeconds = 19800;
// Define NTP Client to get time
WiFiUDP ntpUDP;
NTPClient timeClient(ntpUDP, "pool.ntp.org", utcOffsetInSeconds);

int monthDay = 1;
int currentMonth = 1;
int currentYear = 2024;

int interval = 3;
int currentPixel = 0;
time_t operationEpochTime = 0;

bool isTimerStarted = false;
bool isManualTimerSet = false;

#define EEPROM_SIZE 512
int eepromTarget;
int eepromIntervalAddress = 0;
int eepromStoreEpochTimeAddress = 1;
int eepromStoreLogsArrayAddress = 2;

enum foodQuality {GOOD, ORDINARY, BAD};
String foodQualityGood = "😋";
String foodQualityOrdinary = "😐";
String foodQualityBad = "🤔";

String currentFoodQuality;
int currentFoodQualityIntValue = 0;

void setup() {
  Serial.begin(9600);

  // WiFiManager
  // Local intialization. Once its business is done, there is no need to keep it around
  WiFiManager wifiManager;
  // Uncomment and run it once, if you want to erase all the stored information
  // wifiManager.resetSettings();
  
  // set custom ip for portal
  //wifiManager.setAPConfig(IPAddress(10,0,1,1), IPAddress(10,0,1,1), IPAddress(255,255,255,0));
  wifiManager.setHostname(serverDnsName);

  // fetches ssid and pass from eeprom and tries to connect
  // if it does not connect it starts an access point with the specified name
  // here  "AutoConnectAP"
  // and goes into a blocking loop awaiting configuration
  wifiManager.autoConnect("AutoConnectAP");
  // or use this for auto generated name ESP + ChipID
  //wifiManager.autoConnect();
  
  // if you get here you have connected to the WiFi
  Serial.println("Connected.");

  // Set up mDNS responder:
  // - first argument is the domain name, in this example
  //   the fully-qualified domain name is "esp8266.local"
  // - second argument is the IP address to advertise
  //   we send our IP address on the WiFi network

  if (!MDNS.begin(serverDnsName)) {
    Serial.println("Error setting up MDNS responder!");
    while (1) {
      delay(1000);
    }
  }
  Serial.println("mDNS responder started");
  MDNS.addService("http", "tcp", 80);
  
  // ========================================================
  // WATCHOS Server

  pinMode(onboardLed, OUTPUT);
  digitalWrite(onboardLed, 0);

  server.on("/elapsed-time", handleTime);
  server.on("/reset-time", handleResetTimeFromApp);
  
  // server.on("/inline", [](){
  //   server.send(200, "text/plain", "this works as well");
  // });

  server.onNotFound(handleNotFound);

  server.begin();
  Serial.println("HTTP server started");

  // ========================================================
  //Init EEPROM
  EEPROM.begin(EEPROM_SIZE);

  EEPROM.get(eepromIntervalAddress, eepromTarget);
  Serial.print("eepromTarget: ");
  Serial.println(eepromTarget);
  if (isnan(eepromTarget) || eepromTarget == 255) {
    eepromTarget = interval;
    Serial.print("Set eepromTarget to: ");
    Serial.println(eepromTarget);

    EEPROM.put(eepromIntervalAddress, eepromTarget);
    EEPROM.commit();
  } else {
    interval = eepromTarget;
    Serial.print("eepromTarget is: ");
    Serial.println(eepromTarget);
  }
  
  // ========================================================
  timeClient.begin();
  // Set offset time in seconds to adjust for your timezone, for example:
  // GMT +1 = 3600
  // GMT +8 = 28800
  // GMT -1 = -3600
  // GMT 0 = 0
  timeClient.setTimeOffset(7200);

  // ========================================================
  strip.begin();
  strip.setBrightness(BRIGHTNESS);
  pixelsOff();
  strip.show(); // Initialize all pixels to 'off'
}

void loop() {
  server.handleClient();

  MDNS.update();
  timeClient.update();

  unsigned long currentMillis = millis();
    /* The Arduino executes this code once every second
    *  (timeInterval = 1000 (ms) = 1 second).
    */

  if (currentMillis - previousMillis > timeInterval) {
    currentEpochTime = timeClient.getEpochTime();
    updatePixels();
    previousMillis = currentMillis;
  }

  //has the variable changed since last time here?
  // if(previousManualTimeValue.encode() != setManualTimeValue.encode()) {

  //   //Get a time structure
  //   struct tm *ptm = gmtime ((time_t *)&currentEpochTime); 
  //   monthDay = ptm->tm_mday;
  //   currentMonth = ptm->tm_mon+1;
  //   currentYear = ptm->tm_year+1900;

  //   //has the 10 sec TIMER expired?
  //   if(millis() - myTimerMillisForUpdateValues > manualTimerSetThreshold) {
  //     valTime.set(setManualTimeValue.hour, setManualTimeValue.minute, setManualTimeValue.second);
  //     isManualTimerSet = true;

  //     Serial.println("~~~~~~~~~~~~~");
  //     Serial.print("valTime: ");
  //     Serial.println(valTime.encode());
  //     Serial.println("---------");
  //     Serial.print("isManualTimerSet: ");
  //     Serial.println(isManualTimerSet);
    
  //     //update to the new state
  //     previousManualTimeValue = setManualTimeValue;
  //   }
  // }
}

void stopTimer() {
  Serial.println("STOP");
  isTimerStarted = false;
  currentPixel = 0;
  pixelsOff();
}

void resetInterval() {
  int currentPixel = 0;
  pixelsOn(currentPixel);
  isTimerStarted = true;
  counter += 1;
}

// -----------------------------------------------------
// Pixels

void updatePixels() {
  int currentInterval;
  EEPROM.get(eepromIntervalAddress, currentInterval);
  pixelDivisionValue = (currentInterval * 360) / NUM_LEDS; // seconds per 1 pixel

  if (isTimerStarted) {
    if ((int(currentEpochTime) - int(operationEpochTime)) >= pixelDivisionValue) {
      operationEpochTime += pixelDivisionValue;
      currentPixel += 1;
    }

    if (currentPixel <= NUM_LEDS) {
      setPixel(currentPixel);
    } else if (currentPixel > NUM_LEDS && currentPixel <= NUM_LEDS * 2) {
      setOvertimePixel(currentPixel);
    }
  }
}

void setOvertimePixel(int pixel) {
  if (pixel <= NUM_LEDS * 2) {
    strip.setPixelColor(pixel - NUM_LEDS, strip.Color(80, 0, 20));
    strip.show();
    setPixelBorders();
  }
}

void setPixelBorders() {
  uint32_t color = strip.Color(0, 0, 0);
  if (currentFoodQuality == foodQualityGood) {
    color = strip.Color(0, 100, 0);
  } else if (currentFoodQuality == foodQualityOrdinary) {
    color = strip.Color(0, 0, 100);
  } else if (currentFoodQuality == foodQualityBad) {
    color = strip.Color(100, 0, 0);
  }
  strip.setPixelColor(0, color);
  strip.setPixelColor(NUM_LEDS - 1, color);
  strip.show();
}

void setPixel(int pixel) {
  strip.setPixelColor(pixel, strip.Color(0, 0, 0));
  strip.show();
  setPixelBorders();
}

void pixelsOff() {
  for (int i = 0; i < NUM_LEDS; i++) {
    strip.setPixelColor(i, strip.Color(0, 0, 0));
  }
  strip.show();
}

void pixelsOn(int fromPixel) {
  Serial.println("pixelsOn");
  for (int i = fromPixel; i < NUM_LEDS; i++) {
    strip.setPixelColor(i, strip.Color(0, 50, 50));
  }
  strip.show();
}

// ===============================================
// WATCHOS Server funcs

void handleTime() {
  // TODO: set global var
  String valTime = "TEST";
  // digitalWrite(onboardLed, 1);
  server.send(200, "text/plain", valTime);
  // digitalWrite(onboardLed, 0);
  Serial.print("Time: ");
  Serial.println(valTime);
}

void handleResetTimeFromApp() {
  server.send(200, "text/plain", "true");
  resetInterval();
  Serial.println("=================");
  Serial.println("Reset");
}

void handleNotFound(){
  digitalWrite(onboardLed, 1);
  String message = "File Not Found\n\n";
  message += "URI: ";
  message += server.uri();
  message += "\nMethod: ";
  message += (server.method() == HTTP_GET)?"GET":"POST";
  message += "\nArguments: ";
  message += server.args();
  message += "\n";
  for (uint8_t i=0; i<server.args(); i++){
    message += " " + server.argName(i) + ": " + server.arg(i) + "\n";
  }
  server.send(404, "text/plain", message);
  digitalWrite(onboardLed, 0);
}
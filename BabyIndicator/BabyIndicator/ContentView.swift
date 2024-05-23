//
//  ContentView.swift
//  BabyIndicator
//
//  Created by Anatolii Kasianov on 17.04.2024.
//

import SwiftUI

@available(iOS 17.0, *)
struct ContentView: View {
    @Environment(\.scenePhase) var scenePhase

    @State var feedingIntervalValue = 15 // 10800 = 3 hours in seconds
    
    @State var currentTimeValue = 0
    @State var currentTimeLabel = ""
    
    @State var primaryActionButton: PrimaryButton = PrimaryButton()
    @State var resetButton: ResetButton = ResetButton()
    @State var stopButton: StopButton = StopButton()
    
    @State var progressState: ProgressState = ProgressState()
    @State var timerState: TimerState = TimerState()

    //    @ObservedObject var stopwatch = Stopwatch()
    
    @ObservedObject var timerManager = TimerManager()
    @ObservedObject var networkManager = NetworkManager()
    @ObservedObject var audioManager = AudioManager()
    @ObservedObject var notificationManager = UserNotificationManager()

    var body: some View {
        VStack {
            Spacer()
            ZStack {
                CircularProgressView(timeRemaining: progressState.progressValue ?? 0,
                                     maxTimeValue: feedingIntervalValue,
                                     progressColor: Color(progressState.progressColor.color))
                Text(currentTimeLabel)
                    .font(.largeTitle)
                    .bold()
            }.frame(width: 250, height: 250)
            Spacer()
            HStack {
                Button(resetButton.title, systemImage: resetButton.imageIcon) {
                    resetButtonTapped()
                }.buttonStyle(.borderedProminent)
                Button(primaryActionButton.title, systemImage: primaryActionButton.imageIcon) {
                    primaryActionButtonTapped()
                }.buttonStyle(.bordered)
                Button(stopButton.title, systemImage: stopButton.imageIcon) {
                    stopButtonTapped()
                }.buttonStyle(.bordered)
            }
            
        }.onReceive(timerManager.$counter) { counter in
            currentTimeLabel = composeCurrentTimeLabel(timeInSeconds: progressState.progressValue ?? 0)
            
            NSLog("----------------------")
            NSLog("progressValue: \(String(describing: progressState.progressValue))")
            NSLog("status: \(String(describing: progressState.status))")
            NSLog("startTime: \(String(describing: timerState.startTime))")
            NSLog("pauseTime: \(String(describing: timerState.pauseTime))")
            NSLog("delta: \(String(describing: timerState.pauseDelta))")
            NSLog("----------------------")
            
            if progressState.status == .running {
                NSLog("currentTimeValue: \(currentTimeValue))")
                
                if currentTimeValue >= feedingIntervalValue {
                    audioManager.startVibro()
                }
                if currentTimeValue >= feedingIntervalValue * 2 {
                    stopProgress()
                    audioManager.startVibro()
                } else {
                    currentTimeValue += 1
                }
            }
            // Change progress bar color due to time interval is regular or extra
            if currentTimeValue < feedingIntervalValue {
                progressState.setColor(to: .blue)
                progressState.progressValue = currentTimeValue
            } else {
                progressState.setColor(to: .red)
                progressState.progressValue = currentTimeValue - feedingIntervalValue
            }
            
//            if currentTimeValue % 3 == 0 {
//                networkManager.getTimeFromServer()
//                NSLog(networkManager.currentTime)
//            }
            
            
        }.onChange(of: scenePhase) { oldPhase, newPhase in
            if newPhase == .active {
                NSLog("====== Active ======")
                restoreFromDefaults()
            } else if newPhase == .inactive {
                NSLog("====== Inactive ======")
//                storeStateToDefaults()
            } else if newPhase == .background {
                NSLog("====== Background ======")
                storeStateToDefaults()
            }
        }.onAppear {
            NSLog("====== onAppear ======")
            setInitialState()
            notificationManager.requestPermissions()
        }
    }

    func primaryActionButtonTapped() {
        NSLog("Primary Action Button Tapped")
        startPauseProgress()
    }
    
    func stopButtonTapped() {
        NSLog("Stop Button Tapped")
        stopProgress()
    }
    
    func resetButtonTapped() {
        NSLog("Reset Button Tapped")
        stopProgress()
        startPauseProgress()
    }
    
    func stopProgress() {
        progressState.status = .stopped
        timerState.startTime = nil
        setInitialState()
    }
    
    func startPauseProgress() {
        if progressState.status == .running {
            // PAUSE
            NSLog("was .running, now .paused")
            progressState.status = .paused
            primaryActionButton.setState(to: .start)
            timerState.pauseTime = Date()
            self.timerManager.pauseTimer()
           
            guard let startTime = timerState.startTime,
                let pauseTime = timerState.pauseTime else {
                return
            }
            timerState.pauseDelta += TimeInterval(pauseTime.timeIntervalSince(startTime as Date))
            
        } else if progressState.status == .stopped {
            // START
            NSLog("was .stopped, now .running")
            timerState.startTime = Date()
            progressState.status = .running
            primaryActionButton.setState(to: .pause)
            timerState.pauseTime = nil
            self.timerManager.startTimer()
            notificationManager.scheduleNotification(to: TimeInterval(feedingIntervalValue),
                                                     title: "Feed the baby",
                                                     subtitle: "It looks hungry")
        } else {
            // START
            NSLog("was .paused, now .running")
            progressState.status = .running
            primaryActionButton.setState(to: .pause)
            self.timerManager.startTimer()
            
            timerState.pauseTime = nil
            timerState.startTime = Date()
            currentTimeValue = Int(timerState.pauseDelta)
        }
    }
    
    func resetTimers() {
        NSLog("resetTimers")
        timerState.startTime = nil
        timerState.pauseTime = nil
        timerState.pauseDelta = 0.0
        timerManager.pauseTimer()
        
        progressState.resetState()
        progressState.progressValue = feedingIntervalValue
        currentTimeValue = 0
        
        storeStateToDefaults()
    }
    
    func setInitialState() {
        NSLog("setInitialState")
        resetTimers()
        resetUI()
    }
    
    func resetUI() {
        NSLog("resetUI")
        primaryActionButton.setState(to: .start)
        progressState.setColor(to: .blue)
    }
    
    func storeStateToDefaults() {
        NSLog("----------------------")
        NSLog("Store state to Defaults")
        progressState.storeToDefaults()
        timerState.storeToDefaults()
        NSLog("----------------------")
    }
    
    func restoreFromDefaults() {
        NSLog("----------------------")
        NSLog("Restore from Defaults")
        progressState.fetchFromDefaults()
        timerState.fetchFromDefaults()
        
        NSLog("progressValue: \(String(describing: progressState.progressValue))")
        NSLog("status: \(String(describing: progressState.status))")
        NSLog("startTime: \(String(describing: timerState.startTime))")
        NSLog("pauseTime: \(String(describing: timerState.pauseTime))")
        NSLog("delta: \(String(describing: timerState.pauseDelta))")
        NSLog("----------------------")
        
        // Correct currentTimeValue after restoring app from suspended state
        let now = Date()
        guard let startTime = timerState.startTime else {
            return
        }
        let timeSinceStarted = Int(now.timeIntervalSince(startTime as Date))
        currentTimeValue = timeSinceStarted + Int(timerState.pauseDelta)
    }
}

#Preview {
    ContentView()
}

/// Setup UI
extension ContentView {
    func composeCurrentTimeLabel(timeInSeconds: Int) -> String {
        let hours = timeInSeconds / 3600
        let minutes = (timeInSeconds % 3600) / 60
        let seconds = (timeInSeconds % 3600) % 60
        
        var hoursString = "\(hours)"
        var minutesString = "\(minutes)"
        var secondsString = "\(seconds)"
        
        if hours < 10 {
            hoursString = "0\(hours)"
        }
        if minutes < 10 {
            minutesString = "0\(minutes)"
        }
        if seconds < 10 {
            secondsString = "0\(seconds)"
        }
        return "\(hoursString):\(minutesString):\(secondsString)"
    }
}

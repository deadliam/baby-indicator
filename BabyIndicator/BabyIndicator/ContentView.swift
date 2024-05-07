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
    
    @State var timeRemainingValue = 10800 // 10800 = 3 hours in seconds
    @State var maxTimeValue = 10800 // 10800 = 3 hours in seconds
    
    @State var timeDelta: TimeInterval?
    @State var pauseDelta: TimeInterval?
    
    @State var timeRemainingLabel = ""
    
    @State var primaryActionButton: PrimaryButton = PrimaryButton()
    @State var resetButton: ResetButton = ResetButton()
    @State var stopButton: StopButton = StopButton()
    
    @State var progressState: ProgressState = ProgressState()
    @State var timerState: TimerState = TimerState()

    //    @ObservedObject var stopwatch = Stopwatch()
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack {
            Spacer()
            ZStack {
                CircularProgressView(timeRemaining: progressState.progressValue ?? 0,
                                     maxTimeValue: maxTimeValue,
                                     progressColor: Color(progressState.progressColor.color))
                Text(timeRemainingLabel)
                    .font(.largeTitle)
                    .bold()
            }.frame(width: 200, height: 200)
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
            
        }.onReceive(timer) { time in
            timeRemainingLabel = composeRemainingLabel(timeInSeconds: progressState.progressValue ?? 0)
            
            if progressState.status == .running {
                // Calculate time
                guard let startTime = timerState.startTime else {
                    return
                }
                let nowDate = Date()
                timeDelta = startTime.distance(to: nowDate)
                print("timeDelta: \(String(describing: timeDelta))")
                
                guard let timeDelta = timeDelta else {
                    return
                }
                let delta = Int(timeDelta)
                if timeRemainingValue > -maxTimeValue {
                    timeRemainingValue = maxTimeValue - delta
                }
            }
            // Change progress bar color due to time interval is regular or extra
            if timeRemainingValue > 0 {
                progressState.setColor(to: .blue)
                progressState.progressValue = timeRemainingValue
            } else {
                progressState.setColor(to: .red)
                progressState.progressValue = maxTimeValue + timeRemainingValue
            }
            
        }.onChange(of: scenePhase) { oldPhase, newPhase in
            if newPhase == .active {
                print("====== Active ======")
                restoreFromDefaults()
            } else if newPhase == .inactive {
                print("====== Inactive ======")
                storeStateToDefaults()
            } else if newPhase == .background {
                print("====== Background ======")
                storeStateToDefaults()
            }
        }.onAppear {
            print("====== onAppear ======")
            setInitialState()
        }
    }
    
    func storeStateToDefaults() {
        print("Store state to Defaults")
        progressState.saveStateToDefaults()
        timerState.storeToDefaults()
    }
    
    func restoreFromDefaults() {
        print("Restore from Defaults")
        progressState.fetchFromDefaults()
        timerState.fetchFromDefaults()
        
        print("progressColor: \(String(describing: progressState.progressColor))")
        print("progressValue: \(String(describing: progressState.progressValue))")
        print("status: \(String(describing: progressState.status))")
        print("startTime: \(String(describing: timerState.startTime))")
    }

    func resetButtonTapped() {
        print("Reset Button Tapped")
        stopProgress()
        startPauseProgress()
    }
    
    func primaryActionButtonTapped() {
        print("Primary Action Button Tapped")
        startPauseProgress()
    }
    
    func stopButtonTapped() {
        // STOP
        print("Stop Button Tapped")
        stopProgress()
    }
    
    func stopProgress() {
        progressState.status = .stopped
        timerState.startTime = nil
        setInitialState()
    }
    
    func startPauseProgress() {
        if progressState.status == .running {
            // PAUSE
            print("was .running, now .paused")
            progressState.status = .paused
            primaryActionButton.setState(to: .start)
            timerState.pauseTime = Date()
        } else if progressState.status == .stopped {
            // START
            print("was .stopped, now .running")
            timerState.startTime = Date()
            progressState.status = .running
            primaryActionButton.setState(to: .pause)
            timerState.pauseTime = nil
        } else {
            // START
            print("was .paused, now .running")
            progressState.status = .running
            primaryActionButton.setState(to: .pause)
            
            // Recalculate startTime after pause
//            guard let startTime = timerState.startTime,
//                  let pauseTime = timerState.pauseTime else {
//                return
//            }
//          
//            timerState.startTime = startTime.addingTimeInterval(pauseTime - startTime)
//            
//            print("timerState.startTime: \(timerState.startTime)")
//            timerState.pauseTime = nil
        }
    }
    
    func setInitialState() {
        print("setInitialState")
        resetTimers()
        resetUI()
    }
    
    func resetTimers() {
        print("resetTimers")
        timerState.startTime = nil
        progressState.resetState()
        progressState.progressValue = maxTimeValue
        timeRemainingValue = maxTimeValue
    }
    
    func resetUI() {
        print("resetUI")
        primaryActionButton.setState(to: .start)
        progressState.setColor(to: .blue)
    }
    
    func composeRemainingLabel(timeInSeconds: Int) -> String {
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
            secondsString = "0\(minutes)"
        }
        return "\(hoursString):\(minutesString):\(secondsString)"
    }

}

class TimerState {
    var startTime: Date?
    var pauseTime: Date?
    
    init(startTime: Date? = nil, pauseTime: Date? = nil) {
        self.startTime = startTime
        self.pauseTime = pauseTime
    }
    
    func storeToDefaults() {
        let defaults = UserDefaults.standard
        if let startTime = startTime {
            defaults.set(startTime, forKey: "startTime")
            defaults.synchronize()
        } else {
            defaults.removeObject(forKey: "startTime")
        }
        
        if let pauseTime = pauseTime {
            defaults.set(pauseTime, forKey: "pauseTime")
            defaults.synchronize()
        } else {
            defaults.removeObject(forKey: "pauseTime")
        }
    }
    
    func fetchFromDefaults() {
        startTime = UserDefaults.standard.object(forKey: "startTime") as? Date
        pauseTime = UserDefaults.standard.object(forKey: "pauseTime") as? Date
    }
}

class ProgressState: Codable {

    var status: TimerStatus?
    var progressColor: CodableColor
    var progressValue: Int?
    
    enum TimerStatus: String, Codable {
        case running
        case paused
        case stopped
    }
    
    enum CodingKeys: String, CodingKey {
        case status
        case progressColor
        case progressValue
    }
    
    init(status: TimerStatus = .stopped, progressColor: CodableColor = CodableColor(.blue), progressValue: Int = 0) {
        self.status = status
        self.progressColor = progressColor
        self.progressValue = progressValue
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.status = try container.decodeIfPresent(TimerStatus.self, forKey: .status)
        self.progressColor = try container.decode(CodableColor.self, forKey: .progressColor)
        self.progressValue = try container.decodeIfPresent(Int.self, forKey: .progressValue)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(status, forKey: .status)
        try container.encode(progressColor, forKey: .progressColor)
        try container.encode(progressValue, forKey: .progressValue)
    }
    
    func saveStateToDefaults() {
        let defaults = UserDefaults.standard
        do {
            let encodedData = try PropertyListEncoder().encode(self)
            defaults.set(encodedData, forKey: "progressState")
        } catch {
            print("Error encoding progress state: \(error)")
        }
    }
    
    func fetchFromDefaults() {
        let defaults = UserDefaults.standard
        if let savedData = defaults.data(forKey: "progressState") {
            do {
                let decodedState = try PropertyListDecoder().decode(ProgressState.self, from: savedData)
                self.status = decodedState.status
                self.progressColor = decodedState.progressColor
                self.progressValue = decodedState.progressValue
            } catch {
                print("Error decoding progress state: \(error)")
            }
        }
    }
    
    func resetState() {
        self.status = .stopped
        self.progressColor = CodableColor(.blue)
        self.progressValue = 0
        saveStateToDefaults()
    }
    
    func setColor(to: Color) {
        progressColor = CodableColor(UIColor(to))
    }
}

// Conform UIColor to Codable
struct CodableColor: Codable {
    let color: UIColor
    
    init(_ color: UIColor) {
        self.color = color
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let colorData = try container.decode(Data.self)
        if let color = try NSKeyedUnarchiver.unarchivedObject(ofClass: UIColor.self, from: colorData) {
            self.color = color
        } else {
            self.color = UIColor.black
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        let colorData = try NSKeyedArchiver.archivedData(withRootObject: color, requiringSecureCoding: false)
        try container.encode(colorData)
    }
}

class PrimaryButton {
    var title: String = TitleString.start.rawValue
    var imageIcon: String = IconString.playCircle.rawValue
    
    enum TitleString: String {
        case pause = "Pause"
        case start = "Start"
    }
    
    enum IconString: String {
        case playCircle = "play.circle"
        case pauseCircle = "pause.circle"
    }
    
    func setState(to: TitleString) {
        switch to {
        case .start:
            title = TitleString.start.rawValue
            imageIcon = IconString.playCircle.rawValue
        case .pause:
            title = TitleString.pause.rawValue
            imageIcon = IconString.pauseCircle.rawValue
        }
    }
}

class StopButton {
    var title: String = "Stop"
    var imageIcon: String = "stop"
}

class ResetButton {
    var title: String = "Reset"
    var imageIcon: String = "gobackward"
}

#Preview {
    ContentView()
}

struct CircularProgressView: View {
    let timeRemaining: Int
    let maxTimeValue: Int
    let progressColor: Color
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(
                    progressColor.opacity(0.5),
                    lineWidth: 30
                )
            Circle()
                .trim(from: 0, to: transform(progress: timeRemaining, maxValue: maxTimeValue))
                .stroke(
                    progressColor,
                    style: StrokeStyle(
                        lineWidth: 30,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90))
                .animation(.smooth, value: transform(progress: timeRemaining, maxValue: maxTimeValue))

        }
    }
    
    func transform(progress: Int, maxValue: Int) -> Double {
        print(progress)
        let transformedValue = Double(progress) / Double(maxValue)
        return max(min(transformedValue, 1.0), 0.0)
    }
}

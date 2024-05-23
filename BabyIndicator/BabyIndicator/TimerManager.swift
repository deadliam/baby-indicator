//
//  TimerManager.swift
//  BabyIndicator
//
//  Created by Anatolii Kasianov on 08.05.2024.
//

import Combine
import Foundation

class TimerManager: ObservableObject {
    @Published var isTimerRunning = false
    @Published var counter = 0
    
    var timer: Timer?
    
    init() {
        // Start the timer when initialized
        startTimer()
    }
    
    func startTimer() {
        // Create a new timer if not running
        if timer == nil {
            isTimerRunning = true
            timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
                guard let self = self else { return }
                self.counter += 1
            }
        }
    }
    
    func pauseTimer() {
        // Pause the timer if running
        if let timer = timer {
            timer.invalidate()
            self.timer = nil
            isTimerRunning = false
        }
    }
}

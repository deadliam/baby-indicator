//
//  TimerState.swift
//  BabyIndicator
//
//  Created by Anatolii Kasianov on 08.05.2024.
//

import SwiftUI

class TimerState {
    var startTime: Date?
    var pauseTime: Date?
    var pauseDelta: TimeInterval = 0
    
    init(startTime: Date? = nil, pauseTime: Date? = nil) {
        self.startTime = startTime
        self.pauseTime = pauseTime
    }
    
    func storeToDefaults() {
        let defaults = UserDefaults.standard
        if let startTime = startTime {
            defaults.set(startTime, forKey: "startTime")
        } else {
            defaults.removeObject(forKey: "startTime")
        }
        
        if let pauseTime = pauseTime {
            defaults.set(pauseTime, forKey: "pauseTime")
        } else {
            defaults.removeObject(forKey: "pauseTime")
        }
    
        defaults.set(pauseDelta, forKey: "delta")
        defaults.synchronize()
    }
    
    func fetchFromDefaults() {
        startTime = UserDefaults.standard.object(forKey: "startTime") as? Date
        pauseTime = UserDefaults.standard.object(forKey: "pauseTime") as? Date
        pauseDelta = UserDefaults.standard.object(forKey: "delta") as? TimeInterval ?? 0
    }
}

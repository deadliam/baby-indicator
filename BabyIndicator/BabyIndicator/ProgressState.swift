//
//  ProgressState.swift
//  BabyIndicator
//
//  Created by Anatolii Kasianov on 08.05.2024.
//

import SwiftUI

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
    
    func storeToDefaults() {
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
        storeToDefaults()
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

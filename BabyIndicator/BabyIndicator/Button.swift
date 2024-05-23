//
//  Button.swift
//  BabyIndicator
//
//  Created by Anatolii Kasianov on 08.05.2024.
//

import SwiftUI

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

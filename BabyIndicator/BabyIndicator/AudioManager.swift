//
//  AudioManager.swift
//  BabyIndicator
//
//  Created by Anatolii Kasianov on 22.05.2024.
//

import Foundation
import AVFoundation

class AudioManager: ObservableObject {
    var timer: Timer?
    var numberRepeat = 0
    var maxNumberRepeat = 20

    func startTimer() {
        timer = Timer.scheduledTimer(timeInterval: 2, target: self, selector: #selector(self.startVibro), userInfo: nil, repeats: true)
    }

    func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    @objc func startVibro() {
        startTimer()
        if numberRepeat <= maxNumberRepeat {
            numberRepeat += 1
            vibrateDevice()
        } else {
            stopTimer()
        }
    }

    func vibrateDevice() {
//        AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
        playPattern(select: 3)
    }
    
    func playPattern(select: Int) {
        if(select == 0){
            AudioServicesPlaySystemSound(SystemSoundID(1304))
        }else if(select == 1){
            AudioServicesPlaySystemSound(SystemSoundID(1329))
        }else if(select == 2){
            AudioServicesPlaySystemSound(SystemSoundID(1301))
        }else if(select == 3){
           AudioServicesPlaySystemSound(SystemSoundID(1027))
        }else if(select == 4){
           AudioServicesPlaySystemSound(SystemSoundID(1028))
        }else if(select == 5){
            let alert = SystemSoundID(1011)
            AudioServicesPlaySystemSoundWithCompletion(alert, nil)
        }else if(select == 6){
           AudioServicesPlaySystemSound(SystemSoundID(1333))
        }else if(select == 7){
           AudioServicesPlaySystemSound(SystemSoundID(4095))
        }
    }
}

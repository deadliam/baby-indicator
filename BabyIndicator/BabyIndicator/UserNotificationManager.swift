//
//  UserNotificationManager.swift
//  BabyIndicator
//
//  Created by Anatolii Kasianov on 22.05.2024.
//

import Foundation
import UserNotifications

class UserNotificationManager: ObservableObject {
    
    func scheduleNotification(to: TimeInterval, title: String, subtitle: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.subtitle = subtitle
        content.sound = UNNotificationSound.defaultCritical

        // show this notification "to" seconds from now
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: to, repeats: false)

        // choose a random identifier
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)

        // add our notification request
        UNUserNotificationCenter.current().add(request)
    }
    
    func requestPermissions() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { success, error in
            if success {
                print("All set!")
            } else if let error {
                print(error.localizedDescription)
            }
        }
    }
}

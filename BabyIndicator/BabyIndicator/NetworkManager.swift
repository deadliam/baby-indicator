//
//  NetworkManager.swift
//  BabyIndicator
//
//  Created by Anatolii Kasianov on 14.05.2024.
//

import Foundation

class NetworkManager: ObservableObject {
    
    var currentTime: String = "qqq"
    let serverEndpoint: String = "http://testtimer.local:89"
    
    func getTimeFromServer() {
        let url = URL(string: "\(serverEndpoint)/elapsed-time")!
        let task = URLSession.shared.dataTask(with: url) {(data, response, error) in
            guard let data = data else { return }
//            print(String(data: data, encoding: .utf8)!)
            self.currentTime = String(data: data, encoding: .utf8)!
        }
        task.resume()
    }
    
    func setTime() {
        print("executeResetRequest")
        self.currentTime = "00:00:00"
        let url = URL(string: "\(serverEndpoint)/reset-time")!
        let task = URLSession.shared.dataTask(with: url) {(data, response, error) in
            guard let data = data else { return }
            print(String(data: data, encoding: .utf8)!)
        }
        task.resume()
    }
}

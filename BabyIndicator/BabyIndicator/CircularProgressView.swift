//
//  CircularProgressView.swift
//  BabyIndicator
//
//  Created by Anatolii Kasianov on 08.05.2024.
//

import SwiftUI

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
        let transformedValue = Double(progress) / Double(maxValue)
        return max(min(transformedValue, 1.0), 0.0)
    }
}

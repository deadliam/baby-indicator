//
//  Extensions.swift
//  BabyIndicator
//
//  Created by Anatolii Kasianov on 06.05.2024.
//

import Foundation

extension Date {

    static func - (lhs: Date, rhs: Date) -> TimeInterval {
        return lhs.timeIntervalSinceReferenceDate - rhs.timeIntervalSinceReferenceDate
    }

}

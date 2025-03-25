//
//  LocalData.swift
//  LearnLanguagebyGivingThanks
//
//  Created by Matt Lam on 12/9/24.
//

import Foundation
import SwiftData

struct NotificationSchedule: Codable {
    var weekday: Int
    var hour: Int
    var minute: Int
    var repeatSchedule: RepeatSchedule
}

enum Day: String, CaseIterable, Codable {
    case Sunday, Monday, Tuesday, Wednesday, Thursday, Friday, Saturday
    
    var weekdayNumber: Int {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE" // Full day name
        if let date = dateFormatter.date(from: rawValue) {
            let calendar = Calendar.current
            return calendar.component(.weekday, from: date)
        }
        return 0
    }

    static func from(weekdayNumber: Int) -> Day? {
        switch weekdayNumber {
        case 1: return .Sunday
        case 2: return .Monday
        case 3: return .Tuesday
        case 4: return .Wednesday
        case 5: return .Thursday
        case 6: return .Friday
        case 7: return .Saturday
        default: return nil
        }
    }
    
    var string: String {
        rawValue
    }
}

enum RepeatSchedule: String, CaseIterable, Codable {
    case daily = "daily"
    case weekly = "weekly"
    
    init(from rawValue: String) {
        self = RepeatSchedule(rawValue: rawValue) ?? .daily
    }
}

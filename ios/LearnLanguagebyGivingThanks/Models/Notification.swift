//
//  LocalData.swift
//  LearnLanguagebyGivingThanks
//
//  Created by Matt Lam on 12/9/24.
//

import Foundation
import SwiftData

@Model
final class NotificationSchedule {
    var weekday: Int
    var hour: Int
    var minute: Int
    var repeatSchedule: RepeatSchedule

    init(weekday: Int, hour: Int, minute: Int, repeatSchedule: RepeatSchedule) {
        self.weekday = weekday
        self.hour = hour
        self.minute = minute
        self.repeatSchedule = repeatSchedule
    }
}

@Model
class UserSettings {
    var isReminderOn: Bool
    var selectedPrompt: QuestionPrompt?
    var language: Language
    
    init(isReminderOn: Bool = false, language: Language, selectedPrompt: QuestionPrompt? = nil) {
        self.isReminderOn = isReminderOn
        self.selectedPrompt = selectedPrompt
        self.language = language
    }
}

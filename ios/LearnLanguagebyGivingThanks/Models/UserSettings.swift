//
//  UserSettings.swift
//  LearnLanguagebyGivingThanks
//
//  Created by Matt Lam on 3/24/25.
//
import Foundation
import SwiftData

@Model
class UserSettings {
    var isReminderOn: Bool
    var selectedPrompt: QuestionPrompt?
    var language: Language
    var notificationSchedules: [NotificationSchedule]?
    
    init(isReminderOn: Bool = false, language: Language = .kr, selectedPrompt: QuestionPrompt? = nil, notificationSchedules: [NotificationSchedule]? = nil) {
        self.isReminderOn = isReminderOn
        self.selectedPrompt = selectedPrompt
        self.language = language
        self.notificationSchedules = notificationSchedules
    }
}

extension UserSettings {
    static var defaultSettings: UserSettings {
        return UserSettings()
    }
}

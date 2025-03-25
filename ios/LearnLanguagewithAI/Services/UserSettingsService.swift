//
//  UserSettingsService.swift
//  LearnLanguagebyGivingThanks
//
//  Created by Matt Lam on 1/11/25.
//

import Foundation
import SwiftData

class UserSettingsService {
    // Function to save to local data via SwiftData. Stores the notification schedule.
    func saveDataLocally(language: Language, selectedPrompt: QuestionPrompt, isReminderOn: Bool, context: ModelContext) {
        do {
            let userSettings = UserSettings(isReminderOn: isReminderOn, language: language, selectedPrompt: selectedPrompt)
            context.insert(userSettings)
            ViewLogger.log("UserSettingsService: Successfully saved language locally: \(language.description)")
        } catch {
            ViewLogger.log("UserSettingsService: Error saving language locally: \(error)")
        }
    }
}

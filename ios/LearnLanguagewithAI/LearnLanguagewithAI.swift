//
//  LearnLanguagebyGivingThanksApp.swift
//  LearnLanguagebyGivingThanks
//
//  Created by Matt Lam on 11/23/24.
//

import SwiftUI
import FirebaseCore
import SwiftData

class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    FirebaseApp.configure()
    return true
  }
}

@main
struct LearnLanguagewithAI: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    @State private var container: ModelContainer
    @State private var language: Language = .kr
    @State private var questionPrompt: QuestionPrompt = .gratitude

    init() {
        do {
            // Define schema for compatibility
            let schema = Schema([UserSettings.self])
            container = try ModelContainer(for: schema)
            let context = container.mainContext
            
            // Fetch or create user settings
            let settingsFetch = try context.fetch(FetchDescriptor<UserSettings>())
            
            if settingsFetch.isEmpty {
                let defaultSettings = UserSettings.defaultSettings
                context.insert(defaultSettings)
                try context.save()
                print("settingsFetch is empty: \(container.mainContext)")
                // Initialize with default values if no settings are found
            } else {
                // If settings are found, set language and questionPrompt
                if let userSetting = settingsFetch.first {
                    self._language = State(initialValue: userSetting.language) // Initialize with fetched value
                    self._questionPrompt = State(initialValue: userSetting.selectedPrompt) // Initialize with fetched value
                    print(userSetting.language, userSetting.selectedPrompt)
                }
            }
            
            // Initialize container state
            self._container = State(initialValue: container)
        } catch {
            fatalError("Failed to initialize ModelContainer: \(error.localizedDescription)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(container)
                .environment(ContentViewModel(language: language, questionPrompt: questionPrompt, modelContext: container.mainContext))
        }
    }
}

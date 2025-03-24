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
struct LearnLanguagebyGivingThanksApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    @State private var container: ModelContainer?

    init() {
        do {
            // Explicitly define schema for better compatibility
            let schema = Schema([UserSettings.self])
            let container = try ModelContainer(for: schema)
            let context = container.mainContext
            
            // Ensure a UserSettings instance exists
            let settingsFetch = try context.fetch(FetchDescriptor<UserSettings>())
            if settingsFetch.isEmpty {
                let defaultSettings = UserSettings.defaultSettings
                context.insert(defaultSettings)
                try context.save()
            }
            
            self._container = State(initialValue: container)
        } catch {
            print("Failed to initialize ModelContainer: \(error.localizedDescription)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            if let container = container {
                ContentView()
                    .modelContainer(container)
                    .environment(ContentViewModel(language: .kr, questionPrompt: QuestionPrompt.gratitude))
            } else {
                Text("Failed to load data. Please restart the app.")
            }
        }
    }
}

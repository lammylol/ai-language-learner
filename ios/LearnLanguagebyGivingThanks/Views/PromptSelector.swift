//
//  PromptSelector.swift
//  LearnLanguagebyGivingThanks
//
//  Created by Matt Lam on 3/24/25.
//

import SwiftUI
import SwiftData

struct PromptSelector: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.modelContext) private var context
    @Query var userSettings: [UserSettings]
    
    private var prompt: QuestionPrompt {
        userSettings.first?.selectedPrompt ?? QuestionPrompt.gratitude
    }
    @State private var selectedPrompt: QuestionPrompt? = QuestionPrompt.gratitude
    private var userSettingsService: UserSettingsService = UserSettingsService()

    @State var selectedDays: [String] = []
    
    var body: some View {
        VStack (alignment: .leading, spacing: 5) {
            Text("Select Your Prompt")
                .font(.subheadline)
                .bold()
            Menu {
                Picker("", selection: $selectedPrompt) {
                    ForEach(QuestionPrompt.allCases, id: \.self) { prompt in
                        Text(prompt.rawValue)
                            .tag(prompt)
                    }
                }
            } label: {
                HStack {
                    Text(userSettings.first?.selectedPrompt.rawValue ?? "What are you grateful for today?")
                        .font(.subheadline)
                        .foregroundStyle(Color.blue)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Spacer()
                }
            }
        }
        .onChange(of: selectedPrompt) { old, newValue in
            if let newValue = selectedPrompt {
                userSettings.first?.selectedPrompt = newValue
                
                // Save the updated context
                do {
                    try context.save() // Save the changes to the context
                } catch {
                    print("Failed to save context: \(error)")
                }
            }
        }
        .onAppear {
            selectedPrompt = prompt
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16) // Adds rounded corners with a radius
                .stroke(Color(.systemGray6), lineWidth: 1)
        )
        .multilineTextAlignment(.leading)
    }
}
//
//#Preview {
//    PromptSelector()
//        .modelContainer(for: [UserSettings.self], inMemory: true)
//}


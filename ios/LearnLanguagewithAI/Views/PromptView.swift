//
//  PromptingView.swift
//  LearnLanguagebyGivingThanks
//
//  Created by Matt Lam on 3/24/25.
//

import SwiftUI
import SwiftData

struct PromptView: View {
    @Query var userSettings: [UserSettings]

    @State var selectedDays: [String] = []
    @Binding var showDatePickerPopUp: Bool
    @State var showPromptSelector: Bool = false
    
    var body: some View {
        VStack (alignment: .leading) {
            HStack (alignment: .center) {
                borderedButton(text: "Choose a New Prompt", toggle: $showPromptSelector)
                borderedButton(text: userSettings.first?.isReminderOn == true ? "Change Schedule" : "Set Schedule", toggle: $showDatePickerPopUp)
                Spacer()
            }
            .padding(.leading, 1)
            
            if (showPromptSelector) {
                PromptSelector()
            }
        }
        .frame(maxWidth: .infinity)
    }
}

struct borderedButton: View {
    @Environment(\.colorScheme) var colorScheme
    
    var text: String
    var toggle: Binding<Bool>
    
    var body: some View {
        Button {
            toggle.wrappedValue.toggle()
        } label: {
            VStack {
                Text(text)
                    .font(.subheadline)
                    .foregroundColor(colorScheme == .dark ? .white : .black)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 15)
                    .background(
                        RoundedRectangle(cornerRadius: 25) // Adds rounded corners with a radius
                            .stroke(Color(.systemGray6), lineWidth: 2) // Adds a blue border
                            .fill(toggle.wrappedValue ? Color(.systemGray6) : (colorScheme == .dark ? Color.black : Color.white))
                    )
            }
        }
    }
}

#Preview {
    PromptView(showDatePickerPopUp: .constant(false))
        .modelContainer(for: [UserSettings.self], inMemory: true)
}

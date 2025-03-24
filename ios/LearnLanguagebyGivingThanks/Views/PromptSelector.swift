//
//  PromptSelector.swift
//  LearnLanguagebyGivingThanks
//
//  Created by Matt Lam on 3/24/25.
//

import SwiftUI
import SwiftData

struct PromptSelector: View {
    @Query var userSettings: [UserSettings]

    @State var selectedDays: [String] = []
    @Binding var showDatePickerPopUp: Bool
    
    var body: some View {
        HStack (alignment: .center) {
            Spacer()
            VStack (alignment: .trailing) {
                Button {
                    showDatePickerPopUp.toggle()
                } label: {
                    Text(userSettings.first?.isReminderOn == true ? "Change Schedule" : "Set Schedule")
                        .font(.callout)
                        .multilineTextAlignment(.trailing)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    PromptSelector(showDatePickerPopUp: .constant(false))
        .modelContainer(for: [UserSettings.self], inMemory: true)
}


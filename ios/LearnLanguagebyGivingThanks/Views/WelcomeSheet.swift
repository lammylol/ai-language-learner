//
//  WelcomeSheet.swift
//  LearnLanguagebyGivingThanks
//
//  Created by Matt Lam on 12/16/24.
//

import SwiftUI

struct WelcomeSheet: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Welcome!")
                .font(.largeTitle)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            
            // Display the app icon
            if let appIcon = UIImage(named: "appstore") {
                Image(uiImage: appIcon)
                    .resizable()
                    .frame(width: 200, height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(radius: 10)
            } else {
                Text("App icon not found.")
                    .foregroundColor(.red)
            }
            
            Text("We are glad you're here. We're here to help you learn a new language!")
                .multilineTextAlignment(.center)
                .fontWeight(.medium)

            Text("Set a language, choose a prompt, and set a daily reminder. Don't worry about making mistakes. \n\nWe'll make corrections and we'll even provide suggestions for what to say. Keep practicing and in just a few days, you'll have improved your language skills!")
                .multilineTextAlignment(.leading)
                .fontWeight(.regular)
            
            Button(action: {
                dismiss() // Dismiss the WelcomeSheet
            }) {
                Text("Get Started")
                    .fontWeight(.bold)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.top, 20)
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 20)
    }
}

#Preview {
    WelcomeSheet()
}

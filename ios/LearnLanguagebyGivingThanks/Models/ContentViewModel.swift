//
//  ContentViewModel.swift
//  LearnLanguagebyGivingThanks
//
//  Created by Matt Lam on 12/10/24.
//

import Combine
import SwiftUI

@Observable class ContentViewModel {
    var date: Int = Calendar.current.component(.day, from: Date()) {
        didSet {
            onDateChange()
        }
    }
    var messageModel: MessageModel
    var isFetching: Bool = false
    
    var language: Language
    var selectedLanguage: Language
    
    private var cancellables: Set<AnyCancellable> = []
    
    init(language: Language) {
        self.language = language
        self.messageModel = MessageModel(language: language)
        self.selectedLanguage = language
        
        // Check for date change on app resume
        NotificationCenter.default
            .publisher(for: UIApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                self?.updateDateIfNeeded()
            }
            .store(in: &cancellables)
    }
    
    /// Updates the `date` only if it has changed
    func updateDateIfNeeded() {
        let currentDay = Calendar.current.component(.day, from: Date())
        if date != currentDay {
            date = currentDay
        }
    }
    
    func onDateChange() {
        if messageModel.messages.last?.text.starts(with: "Hi there! I'm here to help you learn") == false {
            let messageText = "Hi there! I'm here to help you learn \(language.description.capitalized) by asking you what you're grateful for each day. Don't worry if you get it wrong; I'll be here to help you out! Let's begin.\n\nWhat are you grateful for today? \(language.welcomeMessage)"
            // Remove newlines and extra spaces
            let formattedText = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
            
            messageModel.addMessage(
                Message(
                    text: formattedText,
                    senderType: .bot
                )
            )
        }
    }
    
    func onLanguageChange() {
        messageModel.messages = []
        let messageText = "Hi there! I'm here to help you learn \(language.description.capitalized) by asking you what you're grateful for each day. Don't worry if you get it wrong; I'll be here to help you out! Let's begin.\n\nWhat are you grateful for today? \(language.welcomeMessage)"
        // Remove newlines and extra spaces
        let formattedText = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        messageModel.addMessage(
            Message(
                text: formattedText,
                senderType: .bot
            )
        )
    }
    
    // Captures processing. Only applies to visible messages in Chat, not AIMessageHistory.
    func onChangeOfFetching() {
        switch isFetching {
        case true:
            if messageModel.messages.last?.text != "Processing..." {
                messageModel.messages.append(Message(text: "Processing...", senderType: .bot))
            }
        case false:
            if messageModel.messages.last?.text == "Processing..." {
                messageModel.messages.removeLast()
            }
        }
    }
}

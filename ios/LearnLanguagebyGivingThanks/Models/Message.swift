//
//  MessageModel.swift
//  LearnLanguagebyGivingThanks
//
//  Created by Matt Lam on 11/25/24.
//

import Foundation

public struct Message: Codable, Identifiable {
    public var id = UUID()
    var text: String
    var senderType: SenderType
}

enum SenderType: String, Codable {
    case user = "user"
    case bot = "bot"
}

@Observable class MessageModel {
    public var messages: [Message] = []
    public var aiMessageHistory: [Message] = [] // this is to collect the message history sent back to chatGPT. Separate from the messages saved locally.
    public var aiMessageHistoryMaxCount: Int = 3
    
    public var language: Language
    
    init(language: Language) {
        self.language = language
        let messageText = "Hi there! I'm here to help you learn \(language.description.capitalized) by asking you what you're grateful for each day. Don't worry if you get it wrong; I'll be here to help you out! Let's begin.\n\nWhat are you grateful for today? \(language.welcomeMessage)"
        let formattedText = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        self.messages = [Message(text: formattedText, senderType: .bot)]
    }
    
    func addMessage(_ message: Message) {
        if aiMessageHistory.count > 3 {
            aiMessageHistory.removeFirst()
        }
        messages.append(message)
        aiMessageHistory.append(message)
    }
}

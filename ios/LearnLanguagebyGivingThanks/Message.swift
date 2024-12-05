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
    public var language: Language
    
    init(language: Language) {
        self.language = language
        self.messages = [Message(text: "Hi there! I'm here to help you learn \(language.description.capitalized) by asking you what you're grateful for each day. Don't worry if you get it wrong; I'll be here to help you out! Let's begin.\n\nWhat are you grateful for today? \(language.welcomeMessage)", senderType: .bot)]
    }
    
    func addMessage(_ message: Message) {
        if messages.count > 3 {
            messages.removeFirst()
        }
        messages.append(message)
    }
}

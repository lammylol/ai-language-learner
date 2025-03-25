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
    
    init(language: Language, questionPrompt: QuestionPrompt) {
        self.language = language
        
        let backgroundContext = questionPrompt.backgroundContext(from: language)
        let questionPrompt = "\(questionPrompt.rawValue) \(questionPrompt.translated(to: language))"
        
//        let formatted1 = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
//        let formatted2 = messagePrompt.trimmingCharacters(in: .whitespacesAndNewlines)
        self.messages = [Message(text: backgroundContext, senderType: .bot), Message(text: questionPrompt, senderType: .bot)]
    }
    
    func addMessage(_ message: Message) {
        if aiMessageHistory.count > 3 {
            aiMessageHistory.removeFirst()
        }
        messages.append(message)
        aiMessageHistory.append(message)
    }
}

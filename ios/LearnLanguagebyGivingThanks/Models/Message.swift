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

enum QuestionPrompt: String, Codable {
    case gratitude = "What are you grateful for today?"
    case activity = "What are you going to do today?"
    case feeling = "How are you feeling today?"
    
    func backgroundContext(from language: Language) -> String {
        switch self {
        case .gratitude, .activity, .feeling:
            return "Hi there! I'm here to help you learn \(language.description.capitalized) by asking you what you're grateful for each day. Don't worry if you get it wrong; I'll be here to help you out! Let's begin."
        }
    }
    
    func translated(to language: Language) -> String {
        switch self {
        case .gratitude:
            switch language {
            case .us:
                return "What are you grateful for today?"
            case .kr:
                return "오늘 당신이 무염하게 느낀 것은?"
            case .sp:
                return "¿Por qué estás agradecido hoy?"
            case .ch:
                return "今日，你为什么感激？"
            }
        
        case .activity:
            switch language {
            case .us:
                return "What are you going to do today?"
            case .kr:
                return "오늘 당신이 무염하게 느낀 것은?"
            case .sp:
                return "¿Por qué estás agradecido hoy?"
            case .ch:
                return "今日，你为什么感激？"
            }
            
        case .feeling:
            switch language {
            case .us:
                return "How are you feeling today?"
            case .kr:
                return "오늘 당신이 무염하게 느낀 것은?"
            case .sp:
                return "¿Por qué estás agradecido hoy?"
            case .ch:
                return "今日，你为什么感激？"
            }
        }
    }
}

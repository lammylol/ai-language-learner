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
    case user
    case bot
}

@Observable class MessageModel {
    public var messages: [Message] = []
    
    func addMessage(_ message: Message) {
        if messages.count > 3 {
            messages.removeFirst()
        }
        messages.append(message)
    }
}

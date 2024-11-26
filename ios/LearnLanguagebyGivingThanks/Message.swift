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

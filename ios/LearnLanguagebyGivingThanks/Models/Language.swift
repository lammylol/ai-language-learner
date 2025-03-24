//
//  Language.swift
//  LearnLanguagebyGivingThanks
//
//  Created by Matt Lam on 1/10/25.
//

enum Language: String, CaseIterable, Codable {
    case us
    case sp
    case kr
    case ch
    
    var localeIdentifier: String {
        switch self {
        case .us: return "en_US"
        case .sp: return "es_ES"
        case .kr: return "ko_KR"
        case .ch: return "zh_CN"
        }
    }
    
    var description: String {
        switch self {
        case .us: return "english"
        case .sp: return "spanish"
        case .kr: return "korean"
        case .ch: return "chinese"
        }
    }
    
//    var welcomeMessage: String {
//        switch self {
//        case .us: return ""
//        case .sp: return "¿Qué te gusta hoy?"
//        case .kr: return "오늘 무엇을 감사하세요?"
//        case .ch: return "今天感谢什么?"
//        }
//    }
    
    var enterMessage: String {
        switch self {
        case .us: return "Enter Message"
        case .sp: return "Enter Message. Escribe un mensaje!"
        case .kr: return "Enter Message. 메시지 입력!"
        case .ch: return "Enter Message. 输入消息!"
        }
    }
}

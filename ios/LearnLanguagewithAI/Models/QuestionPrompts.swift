//
//  QuestionPrompts.swift
//  LearnLanguagebyGivingThanks
//
//  Created by Matt Lam on 3/24/25.
//

import Foundation

enum QuestionPrompt: String, Codable, CaseIterable, Identifiable {
    case gratitude = "What are you grateful for?"
    case activity = "What are you going to do today?"
    case goal = "What is your goal for today?"
    case prayer = "What is your prayer for today?"
    case habitImprovement = "What is a habit you want to improve today?"
    case simpleJoy = "What is something simple that brings you joy?"
    case bestPartOfDay = "What was the best part of your day?"
    case newLearning = "What is something new you learned today?"
    case recentChallenge = "What is a challenge you faced today, and how did you overcome it?"

    var id: String { rawValue }

    static func randomPrompt() -> String {
        return QuestionPrompt.allCases.randomElement()?.rawValue ?? ""
    }

    func backgroundContext(from language: Language) -> String {
        return "Hi there! I'm here to help you learn \(language.description.capitalized) by asking you a prompt each day. Don't worry if you get it wrong; I'll be here to help you out! Let's begin."
    }

    func translated(to language: Language) -> String {
        switch self {
        case .gratitude:
            return translatedForGratitude(language: language)
        case .activity:
            return translatedForActivity(language: language)
        case .goal:
            return translatedForGoal(language: language)
        case .prayer:
            return translatedForPrayer(language: language)
        case .habitImprovement:
            return translatedForHabitImprovement(language: language)
        case .simpleJoy:
            return translatedForSimpleJoy(language: language)
        case .bestPartOfDay:
            return translatedForBestPartOfDay(language: language)
        case .newLearning:
            return translatedForNewLearning(language: language)
        case .recentChallenge:
            return translatedForRecentChallenge(language: language)
        }
    }

    // Each prompt has its own translation function based on the language.
    private func translatedForGratitude(language: Language) -> String {
        switch language {
        case .us: return "What are you grateful for today?"
        case .kr: return "오늘 당신이 감사한 것은 무엇인가요?"
        case .sp: return "¿Por qué estás agradecido hoy?"
        case .ch: return "今天你为什么感激？"
        }
    }

    private func translatedForActivity(language: Language) -> String {
        switch language {
        case .us: return "What are you going to do today?"
        case .kr: return "오늘 무엇을 할 예정인가요?"
        case .sp: return "¿Qué vas a hacer hoy?"
        case .ch: return "今天你打算做什么？"
        }
    }

    private func translatedForGoal(language: Language) -> String {
        switch language {
        case .us: return "What is your goal for today?"
        case .kr: return "오늘의 목표는 무엇인가요?"
        case .sp: return "¿Cuál es tu objetivo para hoy?"
        case .ch: return "今天你的目标是什么？"
        }
    }

    private func translatedForPrayer(language: Language) -> String {
        switch language {
        case .us: return "What is your prayer for today?"
        case .kr: return "오늘의 기도는 무엇인가요?"
        case .sp: return "¿Cuál es tu oración para hoy?"
        case .ch: return "今天你的祈祷是什么？"
        }
    }

    private func translatedForHabitImprovement(language: Language) -> String {
        switch language {
        case .us: return "What habit did you improve today?"
        case .kr: return "오늘 어떤 습관을 개선했나요?"
        case .sp: return "¿Qué hábito mejoraste hoy?"
        case .ch: return "今天你改善了什么习惯？"
        }
    }

    private func translatedForSimpleJoy(language: Language) -> String {
        switch language {
        case .us: return "What is something simple that brings you joy?"
        case .kr: return "당신에게 기쁨을 주는 간단한 것이 무엇인가요?"
        case .sp: return "¿Qué cosa simple te da alegría?"
        case .ch: return "什么简单的事情能带给你快乐？"
        }
    }

    private func translatedForBestPartOfDay(language: Language) -> String {
        switch language {
        case .us: return "What was the best part of your day?"
        case .kr: return "오늘 하루 중 가장 좋은 부분은 무엇인가요?"
        case .sp: return "¿Cuál fue la mejor parte de tu día?"
        case .ch: return "今天你一天中最棒的部分是什么？"
        }
    }

    private func translatedForNewLearning(language: Language) -> String {
        switch language {
        case .us: return "What is something new you learned today?"
        case .kr: return "오늘 새로 배운 것은 무엇인가요?"
        case .sp: return "¿Qué aprendiste de nuevo hoy?"
        case .ch: return "今天你学到了什么新知识？"
        }
    }

    private func translatedForRecentChallenge(language: Language) -> String {
        switch language {
        case .us: return "What is a challenge you faced today, and how did you overcome it?"
        case .kr: return "오늘 당신이 직면한 도전은 무엇이었고, 그것을 어떻게 극복했나요?"
        case .sp: return "¿Cuál fue el desafío que enfrentaste hoy y cómo lo superaste?"
        case .ch: return "今天你面对的挑战是什么？你是如何克服它的？"
        }
    }
}

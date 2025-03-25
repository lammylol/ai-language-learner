//
//  ContentViewModel.swift
//  LearnLanguagebyGivingThanks
//
//  Created by Matt Lam on 12/10/24.
//

import Combine
import SwiftUI
import SwiftData

@Observable class ContentViewModel {
    var date: Int = Calendar.current.component(.day, from: Date()) {
        didSet {
            onDateChange()
        }
    }
    var messageModel: MessageModel
    var isFetching: Bool = false
    var questionPrompt: QuestionPrompt
    
    var language: Language
    private var modelContext: ModelContext // Adding the context
    
    private var cancellables: Set<AnyCancellable> = []
    
    init(language: Language, questionPrompt: QuestionPrompt, modelContext: ModelContext) {
        self.modelContext = modelContext
        self.language = language
        self.questionPrompt = questionPrompt
        self.messageModel = MessageModel(language: language, questionPrompt: questionPrompt)
        
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
        if messageModel.messages.last?.text.starts(with: questionPrompt.rawValue) == false {

            messageModel.addMessage(
                Message(
                    text: questionPrompt.backgroundContext(from: language),
                    senderType: .bot
                )
            )
            
            let questionPrompt = questionPrompt.rawValue + " " + questionPrompt.translated(to: language)
            
            messageModel.addMessage(
                Message(
                    text: questionPrompt,
                    senderType: .bot
                )
            )
        }
    }
    
    func onLanguageorPromptChange() {
        messageModel.messages = []
        messageModel.addMessage(
            Message(
                text: questionPrompt.backgroundContext(from: language),
                senderType: .bot
            )
        )
        
        let questionPrompt = questionPrompt.rawValue + " " + questionPrompt.translated(to: language)
        
        messageModel.addMessage(
            Message(
                text: questionPrompt,
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

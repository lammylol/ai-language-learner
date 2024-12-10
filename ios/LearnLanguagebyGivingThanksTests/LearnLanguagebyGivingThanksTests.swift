//
//  LearnLanguagebyGivingThanksTests.swift
//  LearnLanguagebyGivingThanksTests
//
//  Created by Matt Lam on 11/23/24.
//

import Testing
@testable import LearnLanguagebyGivingThanks

struct LearnLanguagebyGivingThanksTests {
    var mockViewModel: ContentViewModel
    var mockLanguage: Language
    
    init() {
        self.mockViewModel = ContentViewModel(language: .kr)
        self.mockLanguage = .kr
    }
    
    mutating func reset() {
        mockViewModel = ContentViewModel(language: .kr)
        mockLanguage = .kr
    }

    @Test func testDateChangeWorks() async throws {
        // Write your test here and use APIs like `#expect(...)` to check expected conditions.
        // on date change, should expect a new prompt to appear.
    
        let initialPrompt = mockViewModel.messageModel.messages.first?.text.trimmingCharacters(in: .whitespacesAndNewlines)
        mockViewModel.messageModel.addMessage(Message(text: "Test", senderType: .user))
        
        mockViewModel.date += 1
        
        #expect(mockViewModel.messageModel.messages.count > 2)
        #expect(mockViewModel.messageModel.messages.last?.text == initialPrompt)
    }
}

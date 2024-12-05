//
//  ChatGPTAPI.swift
//  LearnLanguagebyGivingThanks
//
//  Created by Matt Lam on 11/23/24.
//

import Foundation
import FirebaseFunctions
import SwiftUI

class LanguageModelAPIService {
    lazy var functions = Functions.functions()
    
    func getAiApiResponse(messages: [Message], systemInstruction: String, completion: @escaping (Result<String, Error>) -> Void) {
        let data: [String: Any] = [
            "systemInstruction": systemInstruction,
            "messages": messages.map { message in
                [
                    "senderType": message.senderType.rawValue,
                    "text": message.text
                ]
            }
        ]
//        let data: [String: Any] = [
//            ForEach(messages, id: \.id) { message in
//                "\(message.text)"
//            }
//        ]
        
        functions.httpsCallable("processStringWithOpenAI").call(data) { result, error in
            if let error = error as NSError? {
                completion(.failure(error))
                print("Error calling function: \(error.localizedDescription)")
            }
            
            if let responseText = result?.data as? String {
                print("Successfully got response: \(responseText)")
                completion(.success(responseText))
            } else {
                print("Unexpected response format. Result data: \(result?.data ?? "nil")")
            }
        }
    }
    
    func languageHelper(systemInstruction: String, messages: [Message]) async throws -> String {
        return try await withCheckedThrowingContinuation { continuation in
            getAiApiResponse(messages: messages, systemInstruction: systemInstruction, completion: { result in
                switch result {
                case .success(let response):
                    DispatchQueue.main.async {
                        continuation.resume(returning: response)
                    }
                case .failure(let error):
                    DispatchQueue.main.async {
                        continuation.resume(throwing: error)
                    }
                }
            })
        }
    }
}

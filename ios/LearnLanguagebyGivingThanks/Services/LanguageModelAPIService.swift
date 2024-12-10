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
        
        functions.httpsCallable("processStringWithOpenAI").call(data) { result, error in
            if let error = error as NSError? {
                NetworkingLogger.log("LanguageModelAPIService: Error calling function: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            
            guard let responseText = result?.data as? String else {
                NetworkingLogger.log("LanguageModelAPIService: Unexpected response format. Result data: \(String(describing: result?.data))")
                completion(.failure(NSError(domain: "UnexpectedResponse", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unexpected response format."])))
                return
            }
            
            NetworkingLogger.log("LanguageModelAPIService: Successfully got response: \(responseText)")
            completion(.success(responseText))
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

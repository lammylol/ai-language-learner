//
//  ChatGPTAPI.swift
//  LearnLanguagebyGivingThanks
//
//  Created by Matt Lam on 11/23/24.
//

import Foundation
import FirebaseFunctions

class LanguageModelAPIService {
    lazy var functions = Functions.functions()
    
    func getAiApiResponse(systemInstruction: String, prompt: String, completion: @escaping (Result<String, Error>) -> Void) {
        let data: [String: Any] = [
            "systemInstruction": systemInstruction,
            "prompt": prompt
        ]
        
        functions.httpsCallable("processStringWithGenKit").call(data) { result, error in
            
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
    
    func languageHelper(systemInstruction: String, prompt: String) async throws -> String {
        return try await withCheckedThrowingContinuation { continuation in
            getAiApiResponse(systemInstruction: systemInstruction, prompt: prompt, completion: { result in
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

//
//  ChatGPTAPI.swift
//  LearnLanguagebyGivingThanks
//
//  Created by Matt Lam on 11/23/24.
//

import Foundation
import FirebaseFunctions
import FirebaseAnalytics
import FirebaseFirestore
import SwiftUI
import FirebaseAuth

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
        
        // Firebase tracking
        // Get or create a unique anonymous user ID
        let userID = Auth.auth().currentUser?.uid ?? UIDevice.current.identifierForVendor?.uuidString ?? "anonymous_device_id"
        
        // Reference to the Firestore collection
        let db = Firestore.firestore()
        let userRef = db.collection("user_api_call_counts").document(userID)
        
        // Increment the API call count for the user
        userRef.getDocument { (document, error) in
            if let document = document, document.exists {
                // Document exists, increment the count
                var currentCount = document.data()?["api_call_count"] as? Int ?? 0
                currentCount += 1
                userRef.updateData(["api_call_count": currentCount]) { error in
                    if let error = error {
                        print("Error updating document: \(error)")
                    } else {
                        print("API call count incremented")
                    }
                }
            } else {
                // Document doesn't exist, create it with initial count
                userRef.setData(["api_call_count": 1]) { error in
                    if let error = error {
                        print("Error creating document: \(error)")
                    } else {
                        print("API call count initialized")
                    }
                }
            }
        }
        
        // Log the API call event to Firebase Analytics
        Analytics.logEvent("api_call_made", parameters: [
            "userID": userID,
            "message": messages.last?.text ?? "na",
            "message_bucket_count": messages.count
        ])
        
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

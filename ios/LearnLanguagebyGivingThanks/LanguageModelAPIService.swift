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
    
    func getAiApiResponse(_ text: String, completion: @escaping (Result<String, Error>) -> Void) {
        functions.httpsCallable("processStringWithGenKit").call(["text": text]) { result, error in
            
            if let error = error as NSError? {
//                if error.domain == FunctionsErrorDomain {
//                    let code = FunctionsErrorCode(rawValue: error.code)
//                    let message = error.localizedDescription
//                    let details = error.userInfo[FunctionsErrorDetailsKey] as? String
//                }
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
}

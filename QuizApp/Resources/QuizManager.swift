//
//  QuizManager.swift
//  QuizApp
//
//  Created by McMoodie on 2021-05-20.
//

import Foundation
import Alamofire

final class QuizManager {
    
    static let shared = QuizManager()
    
    func fetchQuizzes(completionHandler: @escaping (Result<[Quiz], Error>) -> Void) {
        AF.request("https://opentdb.com/api.php?amount=1000&difficulty=easy&type=multiple", encoding: JSONEncoding.default)
            .responseDecodable(of: Quizzes.self) { response in
                
                // Success
                if let quizzes = response.value {
                    completionHandler(.success(quizzes.results))
                }
                
                // Error
                if let error = response.error {
                    print(error.localizedDescription)
                    completionHandler(.failure(QuizErrors.FailedToFetchQuizzes))
                }
            }
    }
    
    func setNewHighScore(newHighScore: Int, completion: @escaping (Result<Int, Error>) -> Void) {
        
        guard let username = UserDefaults.standard.value(forKey: "username") as? String, let highScore = UserDefaults.standard.value(forKey: "\(username)highScore") as? Int else {
            print("Could not set new high score...")
            completion(.failure(QuizErrors.FailedToSetHighScore))
            return
        }
        
        if newHighScore > highScore {
            UserDefaults.standard.setValue(newHighScore, forKey: "\(username)highScore")
            completion(.success(newHighScore))
        }
        
        completion(.success(highScore))
    }
    
    public enum QuizErrors: Error {
        case NotAHighScore
        case FailedToSetHighScore
        case FailedToFetchQuizzes
    }
}



//
//  QuizManager.swift
//  QuizApp
//
//  Created by McMoodie on 2021-05-20.
//

import Foundation
import Alamofire

final class QuizManager {
    
    var quizzes: [Quiz] = []
    
    func fetchQuizzes(completionHandler: @escaping () -> Void) {
        AF.request("https://opentdb.com/api.php?amount=50&category=9&difficulty=easy&type=multiple")
            .responseDecodable(of: MainResponse.self) { response in
                
                // Success
                if let mainResponse = response.value {
                    self.quizzes = mainResponse.Quizzes
                    completionHandler()
                }
                
                // Error
                if let error = response.error {
                    print(error.localizedDescription)
                }
            }
    }
    
    func allQuizzes() -> [Quiz] {
        return self.quizzes
    }
}



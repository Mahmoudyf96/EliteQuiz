//
//  Quizzes.swift
//  QuizApp
//
//  Created by McMoodie on 2021-05-20.
//

import Foundation

class MainResponse: Decodable {
    var Quizzes: [Quiz]
}

class Quiz: Decodable {
    var category: String
    var type: String
    var question: Bool
    var correct_answer: String
    var incorrect_answers: [String]
}

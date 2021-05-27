//
//  Quizzes.swift
//  QuizApp
//
//  Created by McMoodie on 2021-05-20.
//

import Foundation

class Quizzes: Decodable {
    var results: [Quiz]
}

class Quiz: Decodable {
    var category: String
    var type: String
    var difficulty: String
    var question: String
    var correct_answer: String
    var incorrect_answers: [String]
}

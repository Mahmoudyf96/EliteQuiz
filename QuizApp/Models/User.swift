//
//  User.swift
//  QuizApp
//
//  Created by McMoodie on 2021-05-21.
//

import Foundation

struct User {
    var username: String
    var emailAddress: String
    var highScore: Int
    
    var safeEmail: String {
        var safeEmail = emailAddress.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        return safeEmail
    }
    
    var profilePicFileName: String {
        return "\(safeEmail)_profile_pic.png"
    }
}

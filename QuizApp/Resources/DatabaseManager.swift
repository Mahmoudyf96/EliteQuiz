//
//  DatabaseManager.swift
//  QuizApp
//
//  Created by McMoodie on 2021-05-21.
//

import Foundation
import FirebaseDatabase

final class DatabaseManager {
    
    static let shared = DatabaseManager()
    
    private let database = Database.database().reference()

}

// MARK: - Account Management

extension DatabaseManager {
    
    public func userExists(with email: String,
                           completion: @escaping ((Bool) -> Void)) {
        database.child(email).observeSingleEvent(of: .value) { (dataSnapshot) in
            guard (dataSnapshot.value as? String) != nil else {
                completion(false)
                return
            }
            
            completion(true)
        }
    }
    
    ///Insert new user to database
    public func createUser(with user: User) {
        database.child(user.emailAddress).setValue([
            "username": user.username,
            "email": user.emailAddress,
            "highScore": user.highScore
        ])
    }
}

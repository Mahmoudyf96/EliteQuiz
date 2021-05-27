//
//  DatabaseManager.swift
//  QuizApp
//
//  Created by McMoodie on 2021-05-21.
//

import Foundation
import FirebaseDatabase
import MessageKit

final class DatabaseManager {
    
    static let shared = DatabaseManager()
    
    private let database = Database.database().reference()
    
    static func safeEmail(emailAddress: String) -> String {
        var safeEmail = emailAddress.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        return safeEmail
    }
}

// MARK: - Account Management

extension DatabaseManager {
    
    public func userExists(with email: String,
                           completion: @escaping ((Bool) -> Void)) {
        
        let safeEmail = DatabaseManager.safeEmail(emailAddress: email)
        
        database.child(safeEmail).observeSingleEvent(of: .value) { (dataSnapshot) in
            guard dataSnapshot.value as? [String: Any] != nil else {
                completion(false)
                return
            }
            
            completion(true)
        }
    }
    
    ///Insert new user to database
    public func createUser(with user: User, completion: @escaping (Bool) -> Void) {
        database.child(user.safeEmail).setValue([
            "username": user.username,
            "email": user.safeEmail,
            "highScore": user.highScore
        ]) { [weak self] error, _ in
            
            guard let strongSelf = self else {
                return
            }
            
            guard error == nil else {
                print("Failed to write to database")
                completion(false)
                return
            }
            
            strongSelf.database.child("users").observeSingleEvent(of: .value) { (dataSnapshot) in
                if var usersCollection = dataSnapshot.value as? [[String: Any]] {
                    //Append to users dictionary
                    let newElement = [
                        "name": user.username,
                        "email": user.safeEmail,
                        "highScore": user.highScore
                    ] as [String : Any]
                    
                    usersCollection.append(newElement)
                    
                    strongSelf.database.child("users").setValue(usersCollection) { (error, _) in
                        guard error == nil else {
                            completion(false)
                            return
                        }
                        completion(true)
                    }
                } else {
                    //Create the array
                    let newCollection: [[String: Any]] = [
                        [
                            "name": user.username,
                            "email": user.safeEmail,
                            "highScore": user.highScore
                        ]
                    ]
                    
                    strongSelf.database.child("users").setValue(newCollection) { (error, _) in
                        guard error == nil else {
                            completion(false)
                            return
                        }
                        completion(true)
                    }
                }
            }
        }
    }
    ///Fetch all users from database
    public typealias FetchUsersCompletion = (Result<[[String: Any]], Error>) -> Void
    public func fetchUsers(completion: @escaping FetchUsersCompletion) {
        database.child("users").observeSingleEvent(of: .value) { (dataSnapshot) in
            guard let allUsers = dataSnapshot.value as? [[String: Any]] else {
                completion(.failure(DatabaseErrors.failedToFetchUsers))
                return
            }
            
            completion(.success(allUsers))
        }
    }
    
    public enum DatabaseErrors: Error {
        case failedToFetchUsers
        case failedToFetchConvos
        case failedToFetchName
    }
}

// MARK: - Sending Messages to Global Chat

extension DatabaseManager {
    
    ///Creates a global chat
    public func createAGlobalChat(firstMessage: Message, completion: @escaping (Bool) -> Void) {
        
        let messageDate = firstMessage.sentDate
        let dateString = ChatVC.dateFormatter.string(from: messageDate)
        
        var message = ""
        
        switch firstMessage.kind {
        case .text(let messageText):
            message = messageText
        case .attributedText(_):
            break
        case .photo(_):
            break
        case .video(_):
            break
        case .location(_):
            break
        case .emoji(_):
            break
        case .audio(_):
            break
        case .contact(_):
            break
        case .linkPreview(_):
            break
        case .custom(_):
            break
        }
        
        guard let currentUserEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            completion(false)
            return
        }
        
        let safeEmail = DatabaseManager.safeEmail(emailAddress: currentUserEmail)
        
        let collectionMessage: [String: Any] = [
            "id": firstMessage.messageId,
            "type": firstMessage.kind.messageKindString,
            "content": message,
            "date": dateString,
            "sender_email": safeEmail,
            "is_read": false
        ]
        
        let value: [String: Any] = [
            "messages": [
                collectionMessage
            ]
        ]
        
        print("Creating global chat...")
        
        database.child("globalChat").setValue(value) { (error, _) in
            guard error == nil else {
                completion(false)
                return
            }
            
            completion(true)
        }
    }
    
    ///Fetches all messages from the global Chat
    public func fetchGlobalChatMessages(with id: String, completion: @escaping (Result<[Message], Error>) -> Void) {
        database.child("\(id)/messages").observe(.value) { (dataSnapshot) in
            guard let value = dataSnapshot.value as? [[String: Any]] else {
                completion(.failure(DatabaseErrors.failedToFetchConvos))
                return
            }
            
            let messages: [Message] = value.compactMap { (data) in
                
                guard let content = data["content"] as? String,
                      let highScore = data["high_score"] as? Int,
                      let dateString = data["date"] as? String,
                      let date = ChatVC.dateFormatter.date(from: dateString),
                      let messageId = data["id"] as? String,
                      let isRead = data["is_read"] as? Bool,
                      let name = data["name"] as? String,
                      let senderEmail = data["sender_email"] as? String,
                      let type = data["type"] as? String else {
                    return nil
                }
                
                var kind: MessageKind?
                if type == "photo" {
                    guard let imageURL = URL(string: content),
                          let placeHolder = UIImage(systemName: "paperclip") else {
                        return nil
                    }
                    let media = Media(url: imageURL,
                                      image: nil,
                                      placeholderImage: placeHolder,
                                      size: CGSize(width: 300, height: 300))
                    kind = .photo(media)
                    
                } else if type == "video" {
                    guard let videoURL = URL(string: content),
                          let placeHolder = UIImage(named: "Placeholder") else {
                        return nil
                    }
                    let media = Media(url: videoURL,
                                      image: nil,
                                      placeholderImage: placeHolder,
                                      size: CGSize(width: 300, height: 300))
                    kind = .video(media)
                } else {
                    kind = .text(content)
                }
                guard let finalKind = kind else {
                    return nil
                }
                
                let senderObject = Sender(photoURL: "",
                                          senderId: senderEmail,
                                          displayName: name,
                                          highScore: highScore)
                
                return Message(sender: senderObject,
                               messageId: messageId,
                               sentDate: date,
                               kind: finalKind)
            }
            
            completion(.success(messages))
        }
    }
    
    ///Sends a message to the global Chat
    public func sendMessageToGlobalChat(newMessage: Message, name: String, highScore: Int, completion: @escaping (Bool) -> Void) {
        
        // Add new message to messages
        database.child("global_chat/messages").observeSingleEvent(of: .value) { [weak self] (dataSnapshot) in
            
            guard let strongSelf = self else {
                return
            }
            
            guard var currentMessages = dataSnapshot.value as? [[String: Any]] else {
                completion(false)
                return
            }
            
            let messageDate = newMessage.sentDate
            let dateString = ChatVC.dateFormatter.string(from: messageDate)
            
            var message = ""
            
            switch newMessage.kind {
            case .text(let messageText):
                message = messageText
            case .attributedText(_):
                break
            case .photo(let mediaItem):
                if let mediaURL = mediaItem.url?.absoluteString {
                    message = mediaURL
                }
                break
            case .video(let mediaItem):
                if let mediaURL = mediaItem.url?.absoluteString {
                    message = mediaURL
                }
                break
            case .location(_):
                break
            case .emoji(_):
                break
            case .audio(_):
                break
            case .contact(_):
                break
            case .linkPreview(_):
                break
            case .custom(_):
                break
            }
            
            guard let currentUserEmail = UserDefaults.standard.value(forKey: "email") as? String else {
                completion(false)
                return
            }
            
            let safeEmail = DatabaseManager.safeEmail(emailAddress: currentUserEmail)
            
            let newMessageEntry: [String: Any] = [
                "id": newMessage.messageId,
                "type": newMessage.kind.messageKindString,
                "content": message,
                "date": dateString,
                "sender_email": safeEmail,
                "name": name,
                "high_score": highScore,
                "is_read": false
            ]
            
            currentMessages.append(newMessageEntry)
            
            strongSelf.database.child("global_chat/messages").setValue(currentMessages) { (error, _) in
                guard error == nil else {
                    completion(false)
                    return
                }
                
                completion(true)
            }
        }
        
    }
    
}

// MARK: - Sending Messages to another user

extension DatabaseManager {
    
    ///Creates a new conversation with target user email
    public func createNewConvo(with otherUserEmail: String, name: String, highScore: Int, firstMessage: Message, completion: @escaping (Bool) -> Void) {
        guard let currentUserEmail = UserDefaults.standard.value(forKey: "email") as? String,
              let currentName = UserDefaults.standard.value(forKey: "name") else {
            return
        }
        
        let safeEmail = DatabaseManager.safeEmail(emailAddress: currentUserEmail)
        let ref = database.child(safeEmail)
        
        ref.observeSingleEvent(of: .value) { [weak self] (dataSnapshot) in
            guard var userNode = dataSnapshot.value as? [String: Any] else {
                completion(false)
                print("User not found when creating convo...")
                return
            }
            
            let messageDate = firstMessage.sentDate
            let dateString = ChatVC.dateFormatter.string(from: messageDate)
            
            var message = ""
            
            switch firstMessage.kind {
            case .text(let messageText):
                message = messageText
            case .attributedText(_):
                break
            case .photo(_):
                break
            case .video(_):
                break
            case .location(_):
                break
            case .emoji(_):
                break
            case .audio(_):
                break
            case .contact(_):
                break
            case .linkPreview(_):
                break
            case .custom(_):
                break
            }
            
            let conversationId = "conversation_\(firstMessage.messageId)"
            let newConversationData: [String: Any] = [
                "id": conversationId,
                "other_user_email": otherUserEmail,
                "name": name,
                "latest_message": [
                    "date": dateString,
                    "message": message,
                    "is_read": false
                ]
            ]
            
            let recipientConversationData: [String: Any] = [
                "id": conversationId,
                "other_user_email": safeEmail,
                "name": currentName,
                "latest_message": [
                    "date": dateString,
                    "message": message,
                    "is_read": false
                ]
            ]
            
            //Update recipient Convo entry
            self?.database.child("\(otherUserEmail)/conversations").observeSingleEvent(of: .value) { [weak self] (dataSnapshot) in
                if var conversations = dataSnapshot.value as? [[String: Any]] {
                    conversations.append(recipientConversationData)
                    self?.database.child("\(otherUserEmail)/conversations").setValue(conversations)
                } else {
                    self?.database.child("\(otherUserEmail)/conversations").setValue([recipientConversationData])
                }
            }
            
            //Update current user Convo entry
            if var conversations = userNode["conversations"] as? [[String: Any]] {
                //Convo Array exists
                //We shall append new Convo
                conversations.append(newConversationData)
                userNode["conversation"] = conversations
                ref.setValue(userNode) { [weak self] (error, _) in
                    guard error == nil else {
                        completion(false)
                        return
                    }
                    
                    self?.finishCreatingConversation(conversationId: conversationId,
                                                     name: name, highScore: highScore,
                                                     firstMessage: firstMessage,
                                                     completion: completion)
                }
            } else {
                //Convo Array does not exist
                //We shall create it
                userNode["conversation"] = [
                    newConversationData
                ]
                
                ref.setValue(userNode) { [weak self] (error, _) in
                    guard error == nil else {
                        completion(false)
                        return
                    }
                    
                    self?.finishCreatingConversation(conversationId: conversationId,
                                                     name: name, highScore: highScore,
                                                     firstMessage: firstMessage,
                                                     completion: completion)
                }
            }
        }

    }
    
    ///Adds new conversation with first message to database
    private func finishCreatingConversation(conversationId: String, name: String, highScore: Int, firstMessage: Message, completion: @escaping (Bool) -> Void) {
        
        let messageDate = firstMessage.sentDate
        let dateString = ChatVC.dateFormatter.string(from: messageDate)
        
        var message = ""
        
        switch firstMessage.kind {
        case .text(let messageText):
            message = messageText
        case .attributedText(_):
            break
        case .photo(_):
            break
        case .video(_):
            break
        case .location(_):
            break
        case .emoji(_):
            break
        case .audio(_):
            break
        case .contact(_):
            break
        case .linkPreview(_):
            break
        case .custom(_):
            break
        }
        
        guard let currentUserEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            completion(false)
            return
        }
        
        let safeEmail = DatabaseManager.safeEmail(emailAddress: currentUserEmail)
        
        let collectionMessage: [String: Any] = [
            "id": firstMessage.messageId,
            "type": firstMessage.kind.messageKindString,
            "content": message,
            "date": dateString,
            "sender_email": safeEmail,
            "name": name,
            "high_score": highScore,
            "is_read": false
        ]
        
        let value: [String: Any] = [
            "messages": [
                collectionMessage
            ]
        ]
        
        print("Adding convo: \(conversationId)")
        
        database.child("\(conversationId)").setValue(value) { (error, _) in
            guard error == nil else {
                completion(false)
                return
            }
            
            completion(true)
        }
    }
    
    ///Fetches all conversations had by the user with passed in email
    public func getAllConvos(for email: String, completion: @escaping (Result<[Conversation], Error>) -> Void) {
        database.child("\(email)/conversations").observe(.value) { (dataSnapshot) in
            guard let value = dataSnapshot.value as? [[String: Any]] else {
                completion(.failure(DatabaseErrors.failedToFetchConvos))
                return
            }
            
            let conversations: [Conversation] = value.compactMap { (data) in
                
                guard let conversationId = data["id"] as? String,
                      let name = data["name"] as? String,
                      let otherUserEmail = data["other_user_email"] as? String,
                      let latestMessage = data["latest_message"] as? [String: Any],
                      let date = latestMessage["date"] as? String,
                      let message = latestMessage["message"] as? String,
                      let isRead = latestMessage["is_read"] as? Bool else {
                    return nil
                }
                
                let latestMessageObject = LatestMessage(date: date,
                                                        text: message,
                                                        isRead: isRead)
                
                return Conversation(id: conversationId,
                                    name: name,
                                    otherUserEmail: otherUserEmail,
                                    latestMessage: latestMessageObject)
            }
            
            completion(.success(conversations))
        }
    }
    
    ///Fetches all the messages from passed in conversation
    public func getAllMessagesFromConvo(with id: String, completion: @escaping (Result<[Message], Error>) -> Void) {
        database.child("\(id)/messages").observe(.value) { (dataSnapshot) in
            guard let value = dataSnapshot.value as? [[String: Any]] else {
                completion(.failure(DatabaseErrors.failedToFetchConvos))
                return
            }
            
            let messages: [Message] = value.compactMap { (data) in
                
                guard let content = data["content"] as? String,
                      let highScore = data["high_score"] as? Int,
                      let dateString = data["date"] as? String,
                      let date = ChatVC.dateFormatter.date(from: dateString),
                      let messageId = data["id"] as? String,
                      let isRead = data["is_read"] as? Bool,
                      let name = data["name"] as? String,
                      let senderEmail = data["sender_email"] as? String,
                      let type = data["type"] as? String else {
                    return nil
                }
                
                var kind: MessageKind?
                if type == "photo" {
                    guard let imageURL = URL(string: content),
                          let placeHolder = UIImage(systemName: "paperclip") else {
                        return nil
                    }
                    let media = Media(url: imageURL,
                                      image: nil,
                                      placeholderImage: placeHolder,
                                      size: CGSize(width: 300, height: 300))
                    kind = .photo(media)
                    
                } else {
                    kind = .text(content)
                }
                guard let finalKind = kind else {
                    return nil
                }
                
                
                let senderObject = Sender(photoURL: "",
                                          senderId: senderEmail,
                                          displayName: name,
                                          highScore: highScore)
                
                return Message(sender: senderObject,
                               messageId: messageId,
                               sentDate: date,
                               kind: finalKind)
            }
            
            completion(.success(messages))
        }
    }
    
    ///Sends message to passed in conversation
    public func sendMessageToConversation(to conversation: String, otherUserEmail: String, highScore: Int, name: String, newMessage: Message, completion: @escaping (Bool) -> Void) {
        // Add new message to messages
        // Update sender's latest message
        // Update recipient's latest message
        
        guard let myEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            completion(false)
            return
        }
        
        let currentEmail = DatabaseManager.safeEmail(emailAddress: myEmail)
        
        database.child("\(conversation)/messages").observeSingleEvent(of: .value) { [weak self] (dataSnapshot) in
            
            guard let strongSelf = self else {
                return
            }
            
            guard var currentMessages = dataSnapshot.value as? [[String: Any]] else {
                completion(false)
                return
            }
            
            let messageDate = newMessage.sentDate
            let dateString = ChatVC.dateFormatter.string(from: messageDate)
            
            var message = ""
            
            switch newMessage.kind {
            case .text(let messageText):
                message = messageText
            case .attributedText(_):
                break
            case .photo(_):
                break
            case .video(_):
                break
            case .location(_):
                break
            case .emoji(_):
                break
            case .audio(_):
                break
            case .contact(_):
                break
            case .linkPreview(_):
                break
            case .custom(_):
                break
            }
            
            guard let currentUserEmail = UserDefaults.standard.value(forKey: "email") as? String else {
                completion(false)
                return
            }
            
            let safeEmail = DatabaseManager.safeEmail(emailAddress: currentUserEmail)
            
            let newMessageEntry: [String: Any] = [
                "id": newMessage.messageId,
                "type": newMessage.kind.messageKindString,
                "content": message,
                "date": dateString,
                "sender_email": safeEmail,
                "name": name,
                "high_score": highScore,
                "is_read": false
            ]
            
            currentMessages.append(newMessageEntry)
            
            strongSelf.database.child("\(conversation)/messages").setValue(currentMessages) { (error, _) in
                guard error == nil else {
                    completion(false)
                    return
                }
                
                strongSelf.database.child("\(currentEmail)/conversations").observeSingleEvent(of: .value) { (dataSnapshot) in
                    guard var currentUserConversations = dataSnapshot.value as? [[String: Any]] else {
                        completion(false)
                        return
                    }
                    
                    let updatedValue: [String: Any] = [
                        "date": dateString,
                        "message": message,
                        "is_read": false
                    ]
                    
                    var targetConversation: [String: Any]?
                    var position = 0
                    
                    for conversations in currentUserConversations {
                        if let currentId = conversations["id"] as? String, currentId == conversation {
                            targetConversation = conversations
                            break
                        }
                        
                        position += 1
                    }
                    
                    targetConversation?["latest_message"] = updatedValue
                    guard let finalConversation = targetConversation else {
                        completion(false)
                        return
                    }
                    currentUserConversations[position] = finalConversation
                    strongSelf.database.child("\(currentEmail)/conversations").setValue(currentUserConversations) { (error, _) in
                        guard error == nil else {
                            completion(false)
                            return
                        }
                        
                        // Update latest message for recipient user
                        
                        strongSelf.database.child("\(otherUserEmail)/conversations").observeSingleEvent(of: .value) { (dataSnapshot) in
                            guard var otherUserConversations = dataSnapshot.value as? [[String: Any]] else {
                                completion(false)
                                return
                            }
                            
                            let updatedValue: [String: Any] = [
                                "date": dateString,
                                "message": message,
                                "is_read": false
                            ]
                            
                            var targetConversation: [String: Any]?
                            var position = 0
                            
                            for conversations in otherUserConversations {
                                if let currentId = conversations["id"] as? String, currentId == conversation {
                                    targetConversation = conversations
                                    break
                                }
                                
                                position += 1
                            }
                            
                            targetConversation?["latest_message"] = updatedValue
                            guard let finalConversation = targetConversation else {
                                completion(false)
                                return
                            }
                            otherUserConversations[position] = finalConversation
                            
                            strongSelf.database.child("\(currentEmail)/conversations").setValue(otherUserConversations) { (error, _) in
                                guard error == nil else {
                                    completion(false)
                                    return
                                }
                                
                                completion(true)
                            }
                        }
                    }
                }
            }
        }
    }
}

extension DatabaseManager {
    public func getDataFor(path: String, completion: @escaping (Result<Any, Error>) -> Void) {
        self.database.child("\(path)").observeSingleEvent(of: .value) { (dataSnapshot) in
            guard let value = dataSnapshot.value else {
                completion(.failure(DatabaseErrors.failedToFetchName))
                return
            }
            
            completion(.success(value))
        }
    }
}

struct Conversation {
    let id: String
    let name: String
    let otherUserEmail: String
    let latestMessage: LatestMessage
}

struct LatestMessage {
    let date: String
    let text: String
    let isRead: Bool
}

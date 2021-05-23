//
//  ChatViewController.swift
//  QuizApp
//
//  Created by McMoodie on 2021-05-20.
//

import UIKit
import MessageKit
import JGProgressHUD

struct Sender: SenderType {
    var photoURL: String
    var senderId: String
    var displayName: String
    var highScore: Int
}

struct Message: MessageType {
    var sender: SenderType
    var messageId: String
    var sentDate: Date
    var kind: MessageKind
}

class ChatVC: MessagesViewController {
    
    private let spinner = JGProgressHUD(style: .dark)
 
    let currentUser = Sender(photoURL: "",
                             senderId: "self",
                             displayName: "EliteSub",
                             highScore: 69)
    
    let chatBot = Sender(photoURL: "",
                         senderId: "chatbot",
                         displayName: "ChatBot",
                         highScore: 7)

    private var messages = [Message]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        fetchChat()
        
        messages.append(Message(sender: currentUser,
                               messageId: "1",
                               sentDate: Date(),
                               kind: .text("Hello World!")))
        
        messages.append(Message(sender: chatBot,
                               messageId: "2",
                               sentDate: Date(),
                               kind: .text("Hey buddy!")))

        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
    }

    func fetchChat() {
        
    }
    
}

extension ChatVC: MessagesDataSource, MessagesLayoutDelegate, MessagesDisplayDelegate {
    
    func currentSender() -> SenderType {
        return currentUser
    }
    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        messages[indexPath.section]
    }
    
    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        return messages.count
    }
}

//
//  ChatViewController.swift
//  QuizApp
//
//  Created by McMoodie on 2021-05-20.
//

import UIKit
import MessageKit

struct Sender: SenderType {
    var senderId: String
    var displayName: String
}

struct Message: MessageType {
    var sender: SenderType
    var messageId: String
    var sentDate: Date
    var kind: MessageKind
}

class ChatVC: MessagesViewController, MessagesDataSource, MessagesLayoutDelegate, MessagesDisplayDelegate {
 
    let currentUser = Sender(senderId: "self", displayName: "EliteSub")
    let chatBot = Sender(senderId: "chatbot", displayName: "ChatBot")

    var messages = [MessageType]()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        
        messages.append(
            Message(sender: currentUser,
                    messageId: "1",
                    sentDate: Date().addingTimeInterval(-86400),
                    kind: .text("Hello World!"))
        )
        messages.append(
            Message(sender: chatBot,
                    messageId: "2",
                    sentDate: Date().addingTimeInterval(-86000),
                    kind: .text("Hey Sub, how has your day been?"))
        )
        messages.append(
            Message(sender: currentUser,
                    messageId: "3",
                    sentDate: Date().addingTimeInterval(-85676),
                    kind: .text("Not bad! Yours?"))
        )
        messages.append(
            Message(sender: chatBot,
                    messageId: "4",
                    sentDate: Date().addingTimeInterval(-85400),
                    kind: .text("Could be better..."))
        )
        messages.append(
            Message(sender: currentUser,
                    messageId: "5",
                    sentDate: Date().addingTimeInterval(-85000),
                    kind: .text("Yea, That's life >.>"))
        )
    }
    
    func currentSender() -> SenderType {
        return currentUser
    }
    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        return messages[indexPath.section]
    }
    
    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        return messages.count
    }
    
    
}

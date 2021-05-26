//
//  ChatViewController.swift
//  QuizApp
//
//  Created by McMoodie on 2021-05-20.
//

import UIKit
import MessageKit
import InputBarAccessoryView
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

extension MessageKind {
    var messageKindString: String {
        switch self {
        case .text(_):
            return "text"
        case .attributedText(_):
            return "attributed_text"
        case .photo(_):
            return "photo"
        case .video(_):
            return "video"
        case .location(_):
            return "location"
        case .emoji(_):
            return "emoji"
        case .audio(_):
            return "audio"
        case .contact(_):
            return "contact"
        case .linkPreview(_):
            return "link_preview"
        case .custom(_):
            return "custom"
        }
    }
}

class ChatVC: MessagesViewController {
    
    public static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .long
        formatter.locale = .current
        return formatter
    }()
    
    private let spinner = JGProgressHUD(style: .dark)
    
    private var users = [[String: Any]]()
 
    private var currentUser: Sender? {
        guard let email = UserDefaults.standard.value(forKey: "email") as? String else {
            return nil
        }
        
        let safeEmail = DatabaseManager.safeEmail(emailAddress: email)
        
        return Sender(photoURL: "",
               senderId: safeEmail,
               displayName: "EliteSub",
               highScore: 69)
    }
    
    let chatBot = Sender(photoURL: "",
                         senderId: "chatbot",
                         displayName: "ChatBot",
                         highScore: 7)

    private var messages = [Message]()
    private let conversationId: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        fetchUsers()
        setupInputButton()

        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        messageInputBar.delegate = self
    }
    
    private func setupInputButton() {
        let button = InputBarButtonItem()
        button.setSize(CGSize(width: 35, height: 35), animated: false)
        button.setImage(UIImage(systemName: "paperclip"), for: .normal)
        button.onTouchUpInside { [weak self] _ in
            self?.presentInputActionSheet()
        }
        messageInputBar.setLeftStackViewWidthConstant(to: 36, animated: false)
        messageInputBar.setStackViewItems([button], forStack: .left, animated: false)
    }
    
    private func presentInputActionSheet() {
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        messageInputBar.inputTextView.becomeFirstResponder()
        if let conversationId = conversationId {
            listenForMessages(id: conversationId, shouldScrollToBottom: true)
            print("Listening to conversation ID: \(conversationId)")
        }
    }
    
    init() {
        self.conversationId = "global_chat"
        super.init(nibName: nil, bundle: nil)
        
        if let conversationId = conversationId {
            listenForMessages(id: conversationId, shouldScrollToBottom: true)
            print("Listening to conversation ID: \(conversationId)")
        }
    }
    
    required init?(coder: NSCoder) {
        self.conversationId = "global_chat"
        super.init(coder: coder)
    }
    
    private func listenForMessages(id: String, shouldScrollToBottom: Bool) {
        DatabaseManager.shared.fetchGlobalChatMessages(with: id) { [weak self] (result) in
            switch result {
            case .success(let messages):
                guard !messages.isEmpty else {
                    print("Chat is empty!")
                    return
                }
                
                self?.messages = messages
                DispatchQueue.main.async {
                    self?.messagesCollectionView.reloadDataAndKeepOffset()
                    
                    if shouldScrollToBottom {
                        self?.messagesCollectionView.scrollToLastItem()
                    }
                }
            case .failure(let error):
                print("Failed to listen to messages: \(error.localizedDescription)")
            }
        }
    }
    
    func fetchUsers() {
        DatabaseManager.shared.fetchUsers { [weak self] (result) in
            switch result {
            case .success(let usersCollection):
                // self?.hasFetched = true
                self?.users = usersCollection
                // self?.filerUsers(with: query)
                print("Fetched Users")
            case .failure(let error):
                print("Failed to fetch users: \(error)")
            } 
        }
    }
}

extension ChatVC: InputBarAccessoryViewDelegate {
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        guard !text.replacingOccurrences(of: " ", with: "").isEmpty,
              let currentUser = self.currentUser, let messageId = createMessageId() else {
            return
        }
        
        let message = Message(sender: currentUser,
                               messageId: messageId,
                               sentDate: Date(),
                               kind: .text(text))
        
        // Sending Message
        print("Sending... \(text)")
        
        DatabaseManager.shared.sendMessageToGlobalChat(newMessage: message, name: "Me", highScore: 0) { (success) in
            if success {
                print("Message sent")
            } else {
                print("Failed to send message")
            }
        }
    }
    
    private func createMessageId() -> String? {
        // Using the date, currentUserEmail, randomInt, we will come up with a unique message id
        guard let currentUserEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            return nil
        }
        
        let safeEmail = DatabaseManager.safeEmail(emailAddress: currentUserEmail)
        
        let dateString = Self.dateFormatter.string(from: Date())
        let newIdentifier = "\(safeEmail)_\(dateString)"
        
        print("Created messageId: \(newIdentifier)")
        return newIdentifier
    }
}
 

extension ChatVC: MessagesDataSource, MessagesLayoutDelegate, MessagesDisplayDelegate {
    
    func currentSender() -> SenderType {
        if let sender = currentUser {
            return sender
        }
        fatalError("Self Sender is nil, email should be cached")
    }
    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        messages[indexPath.section]
    }
    
    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        return messages.count
    }
}

// MARK: - Searching & Filtering User

// Must be accompanied with SearchVC and New Conversation Database Implementation

/*
 Searching & Filtering Users
 
extension ChatVC: UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let text = searchBar.text, !text.replacingOccurrences(of: " ", with: "").isEmpty else {
            return
        }
        
        results.removeAll()
        
        spinner.show(in: view)
        
        self.searchUsers(query: text)
    }
}
 
 DID NOT IMPLEMENT IN THIS APP, BUT COULD BE USED IN THE FUTURE
 */


/*
 Searching & Filtering Users

private var hasFetched = false
private var results = [[String: Any]]()

func searchUsers(query: String) {
    if hasFetched {
        filterUsers(with: query)
    } else {
        fetchUsers()
    }
}

func filterUsers(with term: String) {
    guard hasFetched else {
        return
    }
 
    self.spinner.dismiss()
    
    let results: [[String: Any]] = self.users.filter({
        guard let name = $0["name"] as? String else {
            return false
        }
        
        return name.hasPrefix(term.lowercased())
    })
    
    self.results = results
}

 DID NOT IMPLEMENT IN THIS APP, BUT COULD BE USED IN THE FUTURE
 */

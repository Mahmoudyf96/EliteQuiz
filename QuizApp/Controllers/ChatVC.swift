//
//  ChatViewController.swift
//  QuizApp
//
//  Created by McMoodie on 2021-05-20.
//

import UIKit
import MessageKit
import InputBarAccessoryView
import SDWebImage
import AVKit

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

struct Media: MediaItem {
    var url: URL?
    var image: UIImage?
    var placeholderImage: UIImage
    var size: CGSize
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
    
    private var highScore: Int = 0
    
    private var senderPhotoURL: URL?
    private var otherUserPhotoURL: URL?
    
    public static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .long
        formatter.locale = .current
        return formatter
    }()
    
    private var users = [[String: Any]]()
 
    private var currentUser: Sender? {
        guard let email = UserDefaults.standard.value(forKey: "email") as? String else {
            return nil
        }
        
        guard let username = UserDefaults.standard.value(forKey: "username") as? String else {
            return nil
        }
        
        let safeEmail = DatabaseManager.safeEmail(emailAddress: email)
        
        return Sender(photoURL: "",
               senderId: safeEmail,
               displayName: username,
               highScore: highScore)
    }

    private var messages = [Message]()
    private let conversationId: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        fetchUsers()
        setupInputButton()

        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        messagesCollectionView.messageCellDelegate = self
        
        messageInputBar.delegate = self
        
        self.navigationController?.navigationBar.setBackgroundImage(nil, for: .default)
        self.navigationController?.navigationBar.shadowImage = nil
        self.navigationController?.navigationBar.layoutIfNeeded()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.layoutIfNeeded()
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
        let actionSheet = UIAlertController(title: "Attach Media",
                                            message: "What would you like to attach?",
                                            preferredStyle: .actionSheet)
        
        actionSheet.addAction(UIAlertAction(title: "Photo", style: .default, handler: { [weak self] _ in
            self?.presentPhotoInputActionSheet()
        }))
        actionSheet.addAction(UIAlertAction(title: "Video", style: .default, handler: { [weak self] _ in
            self?.presentVideoInputActionSheet()
        }))
        actionSheet.addAction(UIAlertAction(title: "Audio", style: .default, handler: { _ in
            
        }))
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        present(actionSheet, animated: true)
    }
    
    private func presentPhotoInputActionSheet() {
        let actionSheet = UIAlertController(title: "Attach Photo",
                                            message: "Camera or Photo Library?",
                                            preferredStyle: .actionSheet)
        
        actionSheet.addAction(UIAlertAction(title: "Camera", style: .default, handler: { [weak self] _ in
            let picker = UIImagePickerController()
            picker.sourceType = .camera
            picker.delegate = self
            picker.allowsEditing = true
            self?.present(picker, animated: true)
        }))
        actionSheet.addAction(UIAlertAction(title: "Photo Library", style: .default, handler: { [weak self] _ in
            let picker = UIImagePickerController()
            picker.sourceType = .photoLibrary
            picker.delegate = self
            picker.allowsEditing = true
            self?.present(picker, animated: true)
        }))
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        present(actionSheet, animated: true)
    }
    
    private func presentVideoInputActionSheet() {
        let actionSheet = UIAlertController(title: "Attach Video",
                                            message: "Camera or Library?",
                                            preferredStyle: .actionSheet)
        
        actionSheet.addAction(UIAlertAction(title: "Camera", style: .default, handler: { [weak self] _ in
            let picker = UIImagePickerController()
            picker.sourceType = .camera
            picker.delegate = self
            picker.mediaTypes = ["public.movie"]
            picker.videoQuality = .typeMedium
            picker.allowsEditing = true
            self?.present(picker, animated: true)
        }))
        actionSheet.addAction(UIAlertAction(title: "Library", style: .default, handler: { [weak self] _ in
            let picker = UIImagePickerController()
            picker.sourceType = .photoLibrary
            picker.delegate = self
            picker.mediaTypes = ["public.movie"]
            picker.videoQuality = .typeMedium
            picker.allowsEditing = true
            self?.present(picker, animated: true)
        }))
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        present(actionSheet, animated: true)
    }
}



extension ChatVC: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: nil)
        guard let messageId = createMessageId(),
              let currentUser = currentUser else {
            print("Image was not uploaded")
            return
        }
        
        if let image = info[.editedImage] as? UIImage, let imageData = image.pngData() {
            let fileName = "photo_message" + messageId.replacingOccurrences(of: " ", with: "_") + ".png"
            
            // Upload Image
            StorageManager.shared.uploadMessagePic(with: imageData,
                                                   fileName: fileName) { [weak self] (result) in
                
                guard let strongSelf = self else {
                    return
                }
                
                switch result {
                case .success(let downloadURL):
                    // Send Image
                    print("Uploading photo: \(downloadURL)")
                    
                    guard let url = URL(string: downloadURL),
                          let placeHolder = UIImage(systemName: "paperclip"),
                          let username = UserDefaults.standard.value(forKey: "username") as? String else {
                        return
                    }
                    
                    let media = Media(url: url,
                                      image: nil,
                                      placeholderImage: placeHolder,
                                      size: .zero)
                    
                    let message = Message(sender: currentUser,
                                          messageId: messageId,
                                          sentDate: Date(),
                                          kind: .photo(media))
                    
                    DatabaseManager.shared.sendMessageToGlobalChat(newMessage: message,
                                                                   name: username,
                                                                   highScore: strongSelf.highScore) { (success) in
                        if success {
                            print("Image has been uploaded")
                        } else {
                            print("Failed to upload Image")
                        }
                    }
                    
                case .failure(let error):
                    print("Failed to upload photo to global chat: \(error.localizedDescription)")
                }
            }
        } else if let videoURL = info[.mediaURL] as? URL {
            let fileName = "video_message" + messageId.replacingOccurrences(of: " ", with: "_") + ".mov"
            
            // Upload Video
            StorageManager.shared.uploadMessageVid(with: videoURL,
                                                   fileName: fileName) { [weak self] (result) in
                
                guard let strongSelf = self else {
                    return
                }
                
                switch result {
                case .success(let downloadURL):
                    // Send Image
                    print("Uploading video: \(downloadURL)")
                    
                    guard let url = URL(string: downloadURL),
                          let placeHolder = UIImage(systemName: "paperclip"),
                          let username = UserDefaults.standard.value(forKey: "username") as? String else {
                        return
                    }
                    
                    let media = Media(url: url,
                                      image: nil,
                                      placeholderImage: placeHolder,
                                      size: .zero)
                    
                    let message = Message(sender: currentUser,
                                          messageId: messageId,
                                          sentDate: Date(),
                                          kind: .video(media))
                    
                    DatabaseManager.shared.sendMessageToGlobalChat(newMessage: message,
                                                                   name: username,
                                                                   highScore: strongSelf.highScore) { (success) in
                        if success {
                            print("Image has been uploaded")
                        } else {
                            print("Failed to upload Image")
                        }
                    }
                    
                case .failure(let error):
                    print("Failed to upload photo to global chat: \(error.localizedDescription)")
                }
            }
        }
    }
}

extension ChatVC: InputBarAccessoryViewDelegate {
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        guard !text.replacingOccurrences(of: " ", with: "").isEmpty,
              let currentUser = self.currentUser,
              let messageId = createMessageId(),
              let username = UserDefaults.standard.value(forKey: "username") as? String else {
            return
        }
        
        let message = Message(sender: currentUser,
                               messageId: messageId,
                               sentDate: Date(),
                               kind: .text(text))
        
        // Sending Message
        print("Sending... \(text)")
        
        DatabaseManager.shared.sendMessageToGlobalChat(newMessage: message, name: username, highScore: highScore) { [weak self] (success) in
            if success {
                self?.messageInputBar.inputTextView.text = nil
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
    
    func configureMediaMessageImageView(_ imageView: UIImageView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
        guard let message = message as? Message else {
            return
        }
        
        switch message.kind {
        case .photo(let media):
            guard let imageURL = media.url else {
                return
            }
            
            imageView.sd_setImage(with: imageURL, completed: nil)
        default:
            break
        }
    }
    
    func configureAvatarView(_ avatarView: AvatarView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
        
        let sender = message.sender
        
        if sender.senderId == currentUser?.senderId {
            // Display our avatar
            if let currentUserImageURL = self.senderPhotoURL {
                avatarView.sd_setImage(with: currentUserImageURL, completed: nil)
            } else {
                //Fetch URL
                guard let email = UserDefaults.standard.value(forKey: "email") as? String else {
                    return
                }
                
                let safeEmail = DatabaseManager.safeEmail(emailAddress: email)
                let filePath = "images/" + safeEmail + "_profile_pic.png"
                
                StorageManager.shared.downloadURL(for: filePath) { [weak self] (result) in
                    switch result {
                    case .success(let imageURL):
                        self?.senderPhotoURL = imageURL
                        DispatchQueue.main.async {
                            avatarView.sd_setImage(with: imageURL, completed: nil)
                        }
                    case .failure(let error):
                        print("Failed to fetch image: \(error.localizedDescription)")
                    }
                }
            }
        } else {
            // Display other user avatar
            if let otherUserImageURL = self.otherUserPhotoURL {
                avatarView.sd_setImage(with: otherUserImageURL, completed: nil)
            } else {
                //Fetch URL
                
                let safeEmail = sender.senderId
                let filePath = "images/" + safeEmail + "_profile_pic.png"
                
                StorageManager.shared.downloadURL(for: filePath) { (result) in
                    switch result {
                    case .success(let imageURL):
                        DispatchQueue.main.async {
                            avatarView.sd_setImage(with: imageURL, completed: nil)
                        }
                    case .failure(let error):
                        print("Failed to fetch image: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
}

extension ChatVC: MessageCellDelegate {
    func didTapImage(in cell: MessageCollectionViewCell) {
        guard let indexPath = messagesCollectionView.indexPath(for: cell) else {
            return
        }
        
        let message = messages[indexPath.section]
        
        switch message.kind {
        case .photo(let media):
            guard let imageURL = media.url else {
                return
            }
            
            let vc = PhotoViewerVC(with: imageURL)
            self.navigationController?.pushViewController(vc, animated: true)
        case .video(let media):
            guard let videoURL = media.url else {
                return
            }
            
            let vc = AVPlayerViewController()
            vc.player = AVPlayer(url: videoURL)
            present(vc, animated: true)
        default:
            break
        }
    }
    
    func didTapAvatar(in cell: MessageCollectionViewCell) {
        print("Tapping Avatar...")
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

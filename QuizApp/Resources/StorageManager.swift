//
//  StorageManager.swift
//  QuizApp
//
//  Created by McMoodie on 2021-05-23.
//

import Foundation
import FirebaseStorage

final class StorageManager {
    static let shared = StorageManager()
    
    private let storage = Storage.storage().reference()
    
    /*
     filepath: - /images/mahmoudyf96-gmail-com_profile_picture.png
     */
    
    public typealias UploadPictureCompletion = (Result<String, Error>) -> Void
    
    /// Uploads picture to firebase storage and returns completion with url string to download
    public func uploadProfilePic(with data: Data,
                                 fileName: String,
                                 completion: @escaping UploadPictureCompletion) {
        
        storage.child("images/\(fileName)").putData(data, metadata: nil) { [weak self] (metadata, error) in
            
            guard let strongSelf = self else {
                return
            }
            
            guard error == nil else {
                print("Failed to upload data to Firebase")
                completion(.failure(StorageErrors.failedToUpload))
                return
            }
            
            strongSelf.storage.child("images/\(fileName)").downloadURL { (url, error) in
                guard let url = url else {
                    print("Failed to get download URL")
                    completion(.failure(StorageErrors.failedToGetDownloadURL))
                    return
                }
                
                let urlString = url.absoluteString
                print("Download URL: \(urlString)")
                
                completion(.success(urlString))
            }
        }
    }
    
    /// Uploads picture to firebase storage and is meant for global chat
    public func uploadMessagePic(with data: Data,
                                 fileName: String,
                                 completion: @escaping UploadPictureCompletion) {
        storage.child("global_chat_images/\(fileName)").putData(data, metadata: nil) { [weak self] (metadata, error) in
            
            guard let strongSelf = self else {
                return
            }
            
            guard error == nil else {
                print("Failed to upload image data to Firebase")
                completion(.failure(StorageErrors.failedToUpload))
                return
            }
            
            strongSelf.storage.child("global_chat_images/\(fileName)").downloadURL { (url, error) in
                guard let url = url else {
                    print("Failed to get download URL")
                    completion(.failure(StorageErrors.failedToGetDownloadURL))
                    return
                }
                
                let urlString = url.absoluteString
                print("Download URL: \(urlString)")
                
                completion(.success(urlString))
            }
        }
    }
    
    /// Uploads video to firebase storage and is meant for global chat
    public func uploadMessageVid(with fileURL: URL,
                                 fileName: String,
                                 completion: @escaping UploadPictureCompletion) {
        storage.child("global_chat_videos/\(fileName)").putFile(from: fileURL, metadata: nil) { [weak self] (metadata, error) in
            
            guard let strongSelf = self else {
                return
            }
            
            guard error == nil else {
                print("Failed to upload video file to Firebase")
                completion(.failure(StorageErrors.failedToUpload))
                return
            }
            
            strongSelf.storage.child("global_chat_videos/\(fileName)").downloadURL { (url, error) in
                guard let url = url else {
                    print("Failed to get download URL")
                    completion(.failure(StorageErrors.failedToGetDownloadURL))
                    return
                }
                
                let urlString = url.absoluteString
                print("Download URL: \(urlString)")
                
                completion(.success(urlString))
            }
        }
    }
    
    public enum StorageErrors: Error {
        case failedToUpload
        case failedToGetDownloadURL
    }
    
    public func downloadURL(for path: String, completion: @escaping (Result<URL, Error>) -> Void) {
        let reference = storage.child(path)
        reference.downloadURL { (url, error) in
            guard let url = url, error == nil else {
                completion(.failure(StorageErrors.failedToGetDownloadURL))
                return
            }
            
            completion(.success(url))
        }
    }
}

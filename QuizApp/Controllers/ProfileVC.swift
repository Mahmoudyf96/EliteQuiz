//
//  ProfileVC.swift
//  QuizApp
//
//  Created by McMoodie on 2021-05-21.
//

import UIKit
import FirebaseAuth
import GoogleSignIn

class ProfileVC: UIViewController {

    @IBOutlet weak var displayChangeButton: UIBarButtonItem!
    
    @IBOutlet weak var logOutButton: UIButton!
    @IBOutlet weak var profilePic: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        displayChangeButton.image = UIImage(named: "Sun")?.scaleTo(CGSize(width: 20, height: 20))
        
        logOutButton.layer.cornerRadius = 5
        logOutButton.layer.masksToBounds = true
        
        profilePic = createProfilePic(imageView: profilePic)
        profilePic.layer.cornerRadius = 65
        profilePic.layer.borderWidth = 2
        profilePic.layer.borderColor = UIColor.black.cgColor
        profilePic.layer.masksToBounds = true
    }
    
    func createProfilePic(imageView: UIImageView) -> UIImageView {
        guard let email = UserDefaults.standard.value(forKey: "email") as? String else { return imageView }
        
        let safeEmail = DatabaseManager.safeEmail(emailAddress: email)
        let fileName = safeEmail + "_profile_pic.png"
        let filePath = "images/" + fileName
        
        StorageManager.shared.downloadURL(for: filePath) { [weak self] (result) in
            switch result {
            case .success(let url):
                print("download URL: \(url)")
                self?.downloadImage(imageView: imageView, url: url)
            case .failure(let error):
                print("Failed to download url: \(error)")
            }
        }
        
        return imageView
    }
    
    func downloadImage(imageView: UIImageView, url: URL) {
        URLSession.shared.dataTask(with: url) { (data, _, error) in
            guard let data = data, error == nil else {
                return
            }
            
            DispatchQueue.main.async {
                let image = UIImage(data: data)
                imageView.image = image
            }
        }.resume()
    }
    
    @IBAction func didTapDisplayChange(_ sender: UIBarButtonItem) {
        
    }
    
    @IBAction func didTapLogOut(_ sender: UIButton) {
        let actionSheet = UIAlertController(title: "",
                                            message: "Are you sure you want to log out?",
                                            preferredStyle: .actionSheet)
        
        actionSheet.addAction(UIAlertAction(title: "Log Out", style: .destructive, handler: { [weak self] _ in
            
            guard let strongSelf = self else { return }
            
            //Google Log out
            GIDSignIn.sharedInstance()?.signOut()
            
            do {
                try FirebaseAuth.Auth.auth().signOut()
                
                strongSelf.performSegue(withIdentifier: "LogoutSegue", sender: self)
            } catch {
                print("Could not log out")
            }
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Cancel",
                                            style: .cancel,
                                            handler: nil))
        
        present(actionSheet, animated: true)
    }
    
}

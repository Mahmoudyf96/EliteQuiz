//
//  ProfileVC.swift
//  QuizApp
//
//  Created by McMoodie on 2021-05-21.
//

import UIKit
import FirebaseAuth
import GoogleSignIn
import SDWebImage

class ProfileVC: UIViewController {

    @IBOutlet weak var logOutButton: UIButton!
    @IBOutlet weak var profilePic: UIImageView!
    @IBOutlet weak var highScoreLabel: UILabel!
    @IBOutlet weak var userHighscore: UILabel!
    @IBOutlet weak var usernameLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setProfileInfo()
        
        logOutButton.layer.cornerRadius = 5
        logOutButton.layer.masksToBounds = true
        
        profilePic = createProfilePic(imageView: profilePic)
        profilePic.layer.cornerRadius = 65
        profilePic.layer.borderWidth = 2
        profilePic.layer.borderColor = UIColor.black.cgColor
        profilePic.layer.masksToBounds = true
        
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.layoutIfNeeded()
    }
    
    func setProfileInfo() {
        guard let username = UserDefaults.standard.value(forKey: "username") as? String,
              let highScore = UserDefaults.standard.value(forKey: "\(username)highScore") as? Int else {
            print("Could not fetch Username/HighScore")
            return
        }
        
        usernameLabel.text = username
        userHighscore.text = "\(highScore)"
    }
    
    func createProfilePic(imageView: UIImageView) -> UIImageView {
        guard let email = UserDefaults.standard.value(forKey: "email") as? String else { return imageView }
        
        let safeEmail = DatabaseManager.safeEmail(emailAddress: email)
        let fileName = safeEmail + "_profile_pic.png"
        let filePath = "images/" + fileName
        
        StorageManager.shared.downloadURL(for: filePath) { (result) in
            switch result {
            case .success(let url):
                print("download URL: \(url)")
                imageView.sd_setImage(with: url, completed: nil)
            case .failure(let error):
                print("Failed to download url: \(error)")
            }
        }
        
        return imageView
    }
    
    @IBAction func didTapLogOut(_ sender: UIButton) {
        let actionSheet = UIAlertController(title: "",
                                            message: "Are you sure you want to log out?",
                                            preferredStyle: .actionSheet)
        
        actionSheet.addAction(UIAlertAction(title: "Log Out", style: .destructive, handler: { [weak self] _ in
            
            guard let strongSelf = self else { return }
            
            UserDefaults.standard.setValue(nil, forKey: "email")
            UserDefaults.standard.setValue(nil, forKey: "username")
            
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

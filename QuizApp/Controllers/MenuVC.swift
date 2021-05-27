//
//  MenuVC.swift
//  QuizApp
//
//  Created by McMoodie on 2021-05-20.
//

import UIKit
import FirebaseAuth

class MenuVC: UIViewController {

    @IBOutlet weak var chatButton: UIBarButtonItem!
    @IBOutlet weak var settingsButton: UIBarButtonItem!
    @IBOutlet weak var highScoreLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        validateAuth()
        setupMenu()

        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.layoutIfNeeded()
    }
    
    private func validateAuth() {
        if FirebaseAuth.Auth.auth().currentUser == nil {
            performSegue(withIdentifier: "LoginSegue", sender: self)
        }
    }
    
    private func setupMenu() {
        chatButton.image = UIImage(named: "ChatIcon")?.scaleTo(CGSize(width: 23, height: 23))
        settingsButton.image = UIImage(named: "Settings")?.scaleTo(CGSize(width: 20, height: 20))
        
        guard let username = UserDefaults.standard.value(forKey: "username") as? String,
              let highScore = UserDefaults.standard.value(forKey: "\(username)highScore") as? Int else {
            print("Could not fetch Username/HighScore")
            return
        }
        
        highScoreLabel.text = "\(highScore)"
    }
    
    override func viewDidAppear(_ animated: Bool) {
        setupMenu()
        super.viewDidAppear(animated)
    }
    
    @IBAction func didTapChat(_ sender: UIBarButtonItem) {
        performSegue(withIdentifier: "ChatSegue", sender: self)
    }
    
    @IBAction func didTapSettings(_ sender: Any) {
        performSegue(withIdentifier: "ProfileSegue", sender: self)
    }
    
    
    @IBAction func didTapPlay(_ sender: UIButton) {
        performSegue(withIdentifier: "QuizSegue", sender: self)
    }
    
    
}

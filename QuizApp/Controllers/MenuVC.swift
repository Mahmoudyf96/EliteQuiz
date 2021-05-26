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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        validateAuth()

        chatButton.image = UIImage(named: "Chat")?.scaleTo(CGSize(width: 23, height: 23))
        settingsButton.image = UIImage(named: "Settings")?.scaleTo(CGSize(width: 20, height: 20))
    }
    
    private func validateAuth() {
        if FirebaseAuth.Auth.auth().currentUser == nil {
            performSegue(withIdentifier: "LoginSegue", sender: self)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    @IBAction func didTapChat(_ sender: UIBarButtonItem) {
        performSegue(withIdentifier: "ChatSegue", sender: self)
    }
    
    @IBAction func didTapSettings(_ sender: Any) {
        performSegue(withIdentifier: "ProfileSegue", sender: self)
    }
    
    
    @IBAction func didTapPlay(_ sender: UIButton) {
        
    }
    
    
}

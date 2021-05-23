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
    @IBOutlet weak var displayButton: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        validateAuth()

        chatButton.image = UIImage(named: "Chat")?.scaleTo(CGSize(width: 30, height: 30))
        displayButton.image = UIImage(named: "Sun")?.scaleTo(CGSize(width: 30, height: 30))
        
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.layoutIfNeeded()
    }
    
    private func validateAuth() {
        if FirebaseAuth.Auth.auth().currentUser == nil {
            performSegue(withIdentifier: "LoginSegue", sender: self)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    @IBAction func chatPressed(_ sender: UIBarButtonItem) {
        performSegue(withIdentifier: "ChatSegue", sender: self)
    }
    
    @IBAction func displayPressed(_ sender: UIBarButtonItem) {
        
    }
    
    @IBAction func playPressed(_ sender: UIButton) {
        
    }

    
    
}

//
//  LoginVC.swift
//  QuizApp
//
//  Created by McMoodie on 2021-05-21.
//

import UIKit
import FirebaseAuth
import GoogleSignIn

class LoginVC: UIViewController {
    
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    
    @IBOutlet weak var loginPressed: UIButton!
    @IBOutlet weak var signInButton: GIDSignInButton!
    
    private var loginObserver: NSObjectProtocol?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loginObserver = NotificationCenter.default.addObserver(
            forName: .didLogInNotification,
            object: nil,
            queue: .main) { [weak self] _ in
            
            guard let strongSelf = self else { return }
            
            strongSelf.navigationController?.popToRootViewController(animated: true)
        }

        title = "Log In"
        view.backgroundColor = .white
        
        emailField.layer.cornerRadius = 5
        emailField.layer.borderWidth = 1
        emailField.layer.borderColor = UIColor.black.cgColor
        
        passwordField.layer.cornerRadius = 5
        passwordField.layer.borderWidth = 1
        passwordField.layer.borderColor = UIColor.black.cgColor
        
        loginPressed.layer.cornerRadius = 5
        
        emailField.delegate = self
        passwordField.delegate = self
        
        GIDSignIn.sharedInstance()?.presentingViewController = self
        signInButton.layer.cornerRadius = 5
        
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.layoutIfNeeded()
        
        self.navigationItem.setHidesBackButton(true, animated: false)
        
//        NotificationCenter.default.addObserver(self,
//                                               selector: #selector(keyboardWillShow(sender:)),
//                                               name: UIResponder.keyboardWillShowNotification,
//                                               object: nil)
//        NotificationCenter.default.addObserver(self,
//                                               selector: #selector(keyboardWillHide(sender:)),
//                                               name: UIResponder.keyboardWillHideNotification,
//                                               object: nil)
    }
    
    deinit {
        if let observer = loginObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
//    @objc func keyboardWillShow(sender: NSNotification) {
//        self.view.frame.origin.y = -150
//    }
//    
//    @objc func keyboardWillHide(sender: NSNotification) {
//        self.view.frame.origin.y = 0
//    }
    
    @IBAction func didTapRegister(_ sender: UIBarButtonItem) {
        performSegue(withIdentifier: "RegisterSegue", sender: self)
    }
    
    @IBAction func didTapLogin(_ sender: UIButton) {
        
        emailField.resignFirstResponder()
        passwordField.resignFirstResponder()
        
        guard let email = emailField.text, let password = passwordField.text, !email.isEmpty, !password.isEmpty, password.count >= 6 else {
            alertUserLoginError()
            return
        }
        
        //Firebase Login
        
        FirebaseAuth.Auth.auth().signIn(withEmail: email, password: password) { [weak self] (authResult, error) in
            
            guard let strongSelf = self else {
                return
            }
            
            guard let result = authResult, error == nil else {
                print(error!.localizedDescription)
                return
            }
            
            let user = result.user
            print("Logged in user: \(user)")
            
            strongSelf.navigationController?.popToRootViewController(animated: true)
        }
    }
    
    @IBAction func didTapGoogleSignIn(_ sender: UIButton) {
        
    }
    
    func alertUserLoginError() {
        let alert = UIAlertController(title: "Woops",
                                      message: "Enter login info correctly",
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Dismiss",
                                      style: .cancel,
                                      handler: nil))
        present(alert, animated: true)
    }
    
}

// MARK: - UITextFieldDelegate

extension LoginVC: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        if textField == emailField {
            passwordField.becomeFirstResponder()
        } else if textField == passwordField {
            didTapLogin(loginPressed)
        }
        
        return true
    }
}

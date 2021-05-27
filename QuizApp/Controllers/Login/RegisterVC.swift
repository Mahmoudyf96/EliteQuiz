//
//  RegisterVC.swift
//  QuizApp
//
//  Created by McMoodie on 2021-05-21.
//

import UIKit
import FirebaseAuth
import JGProgressHUD

class RegisterVC: UIViewController {
    
    @IBOutlet weak var usernameField: UITextField!
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var confirmPassField: UITextField!
    
    @IBOutlet weak var registerPressed: UIButton!
    @IBOutlet weak var profilePic: UIButton!
    
    private let spinner = JGProgressHUD(style: .dark)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Create Account"
        view.backgroundColor = .systemBackground
        
        profilePic.layer.cornerRadius = 65
        profilePic.layer.borderWidth = 2
        profilePic.layer.borderColor = UIColor.black.cgColor
        profilePic.layer.masksToBounds = true
        
        emailField.layer.cornerRadius = 5
        emailField.layer.borderWidth = 1
        emailField.layer.borderColor = UIColor.black.cgColor
        emailField.backgroundColor = .secondarySystemBackground
        
        passwordField.layer.cornerRadius = 5
        passwordField.layer.borderWidth = 1
        passwordField.layer.borderColor = UIColor.black.cgColor
        passwordField.backgroundColor = .secondarySystemBackground
        
        usernameField.layer.cornerRadius = 5
        usernameField.layer.borderWidth = 1
        usernameField.layer.borderColor = UIColor.black.cgColor
        usernameField.backgroundColor = .secondarySystemBackground
        
        confirmPassField.layer.cornerRadius = 5
        confirmPassField.layer.borderWidth = 1
        confirmPassField.layer.borderColor = UIColor.black.cgColor
        confirmPassField.backgroundColor = .secondarySystemBackground
        
        registerPressed.layer.cornerRadius = 5
        
        usernameField.delegate = self
        emailField.delegate = self
        passwordField.delegate = self
        confirmPassField.delegate = self
        
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.layoutIfNeeded()
        
        //        NotificationCenter.default.addObserver(self,
        //                                               selector: #selector(keyboardWillShow(sender:)),
        //                                               name: UIResponder.keyboardWillShowNotification,
        //                                               object: nil)
        //        NotificationCenter.default.addObserver(self,
        //                                               selector: #selector(keyboardWillHide(sender:)),
        //                                               name: UIResponder.keyboardWillHideNotification,
        //                                               object: nil)
    }
    
    //    @objc func keyboardWillShow(sender: NSNotification) {
    //        self.view.frame.origin.y = -150
    //    }
    //
    //    @objc func keyboardWillHide(sender: NSNotification) {
    //        self.view.frame.origin.y = 0
    //    }
    
    @IBAction func didTapChangeProfile(_ sender: UIButton) {
        presentPhotoActionSheet()
    }
    
    @IBAction func didTapRegister(_ sender: UIButton) {
        
        usernameField.resignFirstResponder()
        emailField.resignFirstResponder()
        passwordField.resignFirstResponder()
        confirmPassField.resignFirstResponder()
        
        guard let username = usernameField.text, let email = emailField.text, let password = passwordField.text, let confirmPass = confirmPassField.text, !username.isEmpty, !email.isEmpty, !password.isEmpty, !confirmPass.isEmpty, password.count >= 6, password == confirmPass else {
            self.alertUserRegisterError()
            return
        }
        
        spinner.show(in: view)
        
        //Firebase register
        
        DatabaseManager.shared.userExists(with: email) { [weak self] (exists) in
            
            guard let strongSelf = self else {
                return
            }
            
            DispatchQueue.main.async {
                strongSelf.spinner.dismiss()
            }
            
            guard !exists else {
                //User already exists
                self?.alertUserRegisterError(message: "Looks like the email address is already in use.")
                return
            }
            
            FirebaseAuth.Auth.auth().createUser(withEmail: email, password: password) { (authResult, error) in
                
                guard authResult != nil, error == nil else {
                    self?.alertUserRegisterError(message: "Looks like the email address is already in use.")
                    print("Error creating user")
                    return
                }
                
                UserDefaults.standard.setValue(email, forKey: "email")
                UserDefaults.standard.setValue(username, forKey: "username")
                UserDefaults.standard.setValue(0, forKey: "\(username)highScore")
                
                let eliteUser = User(username: username,
                                     emailAddress: email,
                                     highScore: 0)
                
                DatabaseManager.shared.createUser(with: eliteUser) { success in
                    if success {
                        //Upload Image
                        guard let image = strongSelf.profilePic.imageView?.image,
                              let data = image.pngData() else {
                            return
                        }
                        
                        let fileName = eliteUser.profilePicFileName
                        StorageManager.shared.uploadProfilePic(with: data,
                                                               fileName: fileName) { (result) in
                            switch result {
                            case .success(let downloadURL):
                                UserDefaults.standard.setValue(downloadURL, forKey: "profilePicURL")
                                print(downloadURL)
                            case .failure(let error):
                                print("Storage manager error: \(error)")
                            }
                        }
                    }
                }
                
                strongSelf.navigationController?.popToRootViewController(animated: true)
            }
        }
    }
    
    func alertUserRegisterError(message: String = "Enter all of the information correctly") {
        let alert = UIAlertController(title: "Woops",
                                      message: message,
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Dismiss",
                                      style: .cancel,
                                      handler: nil))
        present(alert, animated: true)
    }
}

// MARK: - UITextFieldDelegate

extension RegisterVC: UITextFieldDelegate, UINavigationControllerDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        if textField == usernameField {
            emailField.becomeFirstResponder()
        } else if textField == emailField {
            passwordField.becomeFirstResponder()
        } else if textField == passwordField {
            confirmPassField.becomeFirstResponder()
        } else if textField == confirmPassField {
            didTapRegister(registerPressed)
        }
        
        return true
    }
    
}

// MARK: - UIImagePickerController

extension RegisterVC: UIImagePickerControllerDelegate {
    
    func presentPhotoActionSheet() {
        let actionSheet = UIAlertController(title: "Profile Picture",
                                            message: "Camera or Image?",
                                            preferredStyle: .actionSheet)
        
        actionSheet.addAction(UIAlertAction(title: "Cancel",
                                            style: .cancel,
                                            handler: nil))
        
        actionSheet.addAction(UIAlertAction(title: "Camera",
                                            style: .default,
                                            handler: { [weak self] _ in
                                                self?.presentCamera()
                                            }))
        actionSheet.addAction(UIAlertAction(title: "Image",
                                            style: .default,
                                            handler: { [weak self] _ in
                                                self?.presentPhotoPicker()
                                            }))
        
        present(actionSheet, animated: true)
    }
    
    func presentCamera() {
        let vc = UIImagePickerController()
        vc.sourceType = .camera
        vc.delegate = self
        vc.allowsEditing = true
        present(vc, animated: true)
    }
    
    func presentPhotoPicker() {
        let vc = UIImagePickerController()
        vc.sourceType = .photoLibrary
        vc.delegate = self
        vc.allowsEditing = true
        present(vc, animated: true)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let selectedImage = info[UIImagePickerController.InfoKey.editedImage] as? UIImage else { return }
        self.profilePic.setImage(selectedImage, for: .normal)
        
        picker.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}

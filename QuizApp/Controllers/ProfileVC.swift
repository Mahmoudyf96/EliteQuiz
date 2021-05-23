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
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var displayChangeButton: UIBarButtonItem!
    
    let data = ["Log Out"]

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.register(UITableViewCell.self,
                           forCellReuseIdentifier: "cell")
        tableView.delegate = self
        tableView.dataSource = self
        
        displayChangeButton.image = UIImage(named: "Sun")?.scaleTo(CGSize(width: 20, height: 20))
    }
    
    @IBAction func didTapDisplayChange(_ sender: UIBarButtonItem) {
        
    }
}

extension ProfileVC: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = data[indexPath.row]
        cell.textLabel?.textAlignment = .center
        cell.textLabel?.textColor = .red
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let actionSheet = UIAlertController(title: "",
                                      message: "Are you sure you want to log out?",
                                      preferredStyle: .actionSheet)
        
        actionSheet.addAction(UIAlertAction(title: "Log Out",
                                            style: .destructive,
                                            handler: { [weak self] _ in
                                                
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

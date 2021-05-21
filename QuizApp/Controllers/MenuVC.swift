//
//  MenuVC.swift
//  QuizApp
//
//  Created by McMoodie on 2021-05-20.
//

import UIKit

class MenuVC: UIViewController {

    @IBOutlet weak var chatButton: UIBarButtonItem!
    @IBOutlet weak var displayButton: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        chatButton.image = UIImage(named: "Chat")?.scaleTo(CGSize(width: 30, height: 30))
        displayButton.image = UIImage(named: "Sun")?.scaleTo(CGSize(width: 30, height: 30))
        
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.layoutIfNeeded()
        
        // Do any additional setup after loading the view.
    }
    
    @IBAction func chatPressed(_ sender: UIBarButtonItem) {
        performSegue(withIdentifier: "ChatSegue", sender: self)
    }
    
    @IBAction func displayPressed(_ sender: UIBarButtonItem) {
        
    }
    
    @IBAction func playPressed(_ sender: UIButton) {
        
    }

    
    
}

// MARK: - Extensions

extension UIImage {
    func scaleTo(_ newSize: CGSize) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
        self.draw(in: CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height))
        let newImage: UIImage? = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage ?? self
    }
}

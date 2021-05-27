//
//  GameOverVC.swift
//  QuizApp
//
//  Created by McMoodie on 2021-05-21.
//

import UIKit

class GameOverVC: UIViewController {

    @IBOutlet weak var scoreLabel: UILabel!
    @IBOutlet weak var playAgainButton: UIButton!
    @IBOutlet weak var endGameButton: UIButton!
    
    var score: Int = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()

        playAgainButton.layer.cornerRadius = 25
        endGameButton.layer.cornerRadius = 25
        
        scoreLabel.text = "\(score)"
        
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.layoutIfNeeded()
        
        self.navigationItem.setHidesBackButton(true, animated: false)
    }
    
    @IBAction func playAgain(_ sender: UIButton) {
        self.performSegue(withIdentifier: "playAgainSegue", sender: self)
    }
    
    @IBAction func endGame(_ sender: UIButton) {
        navigationController?.popToRootViewController(animated: true)
    }
}

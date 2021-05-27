//
//  ViewController.swift
//  QuizApp
//
//  Created by McMoodie on 2021-05-20.
//

import UIKit

class QuizzesVC: UIViewController {

    @IBOutlet weak var question: UILabel!
    @IBOutlet weak var answerOne: UIButton!
    @IBOutlet weak var answerTwo: UIButton!
    @IBOutlet weak var answerThree: UIButton!
    @IBOutlet weak var currentScore: UILabel!
    @IBOutlet weak var exitButton: UIButton!
    @IBOutlet weak var resultImage: UIImageView!
    
    var score: Int = 0
    private var position = 0
    
    private var eliteQuizzes = [Quiz]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        resultImage.image = UIImage()
        
        QuizManager.shared.fetchQuizzes { [weak self] (result) in
            switch result {
            case .success(let quizzes):
                print("All Quizzes: \(quizzes)")
                self?.eliteQuizzes = quizzes
                self?.setupQuestion()
            case .failure(let error):
                print("Failed to Fetch: \(error.localizedDescription)")
            }
        }
        
        exitButton.imageView?.image = UIImage(named: "Close")?.scaleTo(CGSize(width: 50, height: 50))
        
        question.layer.cornerRadius = 25
        question.layer.masksToBounds = true
        answerOne.layer.cornerRadius = 25
        answerTwo.layer.cornerRadius = 25
        answerThree.layer.cornerRadius = 25
        
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.layoutIfNeeded()
        
        self.navigationItem.setHidesBackButton(true, animated: false)
    }
    
    private func setupQuestion() {
        question.text = eliteQuizzes[position].question.htmlToUtf8()
        answerOne.setTitle(eliteQuizzes[position].incorrect_answers[1].htmlToUtf8(), for: .normal)
        answerTwo.setTitle(eliteQuizzes[position].incorrect_answers[2].htmlToUtf8(), for: .normal)
        answerThree.setTitle(eliteQuizzes[position].correct_answer.htmlToUtf8(), for: .normal)
    }
    
    @IBAction func didTapAnswerOne(_ sender: UIButton) {
        
        guard let answerOne = answerOne.title(for: .normal) else {
            return
        }
        
        checkForCorrectAnswer(attemptedAnswer: answerOne)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.nextQuestion()
        }
    }
    
    @IBAction func didTapAnswerTwo(_ sender: UIButton) {
        guard let answerTwo = answerTwo.title(for: .normal) else {
            return
        }
        
        checkForCorrectAnswer(attemptedAnswer: answerTwo)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.nextQuestion()
        }
    }
    
    @IBAction func didTapAnswerThree(_ sender: UIButton) {
        guard let answerThree = answerThree.title(for: .normal) else {
            return
        }
        
        checkForCorrectAnswer(attemptedAnswer: answerThree)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.nextQuestion()
        }
    }
    
    private func nextQuestion() {
        resultImage.image = UIImage()
        if position == 49 {
            QuizManager.shared.fetchQuizzes { [weak self] (result) in
                switch result {
                case .success(let quizzes):
                    print("All Quizzes: \(quizzes)")
                    self?.eliteQuizzes = quizzes
                    self?.setupQuestion()
                case .failure(let error):
                    print("Failed to Fetch: \(error.localizedDescription)")
                }
            }
            position = 0
        }
        position += 1
        setupQuestion()
        answerOne.isEnabled = true
        answerTwo.isEnabled = true
        answerThree.isEnabled = true
        exitButton.isEnabled = true
    }
    
    private func checkForCorrectAnswer(attemptedAnswer: String) {
        if attemptedAnswer == eliteQuizzes[position].correct_answer {
            resultImage.image = UIImage(named: "Correct")
            score += 1
            currentScore.text = "\(score)"
            QuizManager.shared.setNewHighScore(newHighScore: score) { (result) in
                switch result {
                case .success(let highScore):
                    print("Adjusting High Score -> \(highScore)")
                case .failure(let error):
                    print("Could not adjust High Score\n\(error.localizedDescription)")
                }
            }
            answerOne.isEnabled = false
            answerTwo.isEnabled = false
            answerThree.isEnabled = false
            exitButton.isEnabled = false
        } else {
            resultImage.image = UIImage(named: "Wrong")
            answerOne.isEnabled = false
            answerTwo.isEnabled = false
            answerThree.isEnabled = false
            exitButton.isEnabled = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                self.performSegue(withIdentifier: "GameOverSegue", sender: self)
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "GameOverSegue" {
            let vc = segue.destination as? GameOverVC
            vc?.score = self.score
        }
    }
    
    @IBAction func exitButton(_ sender: UIButton) {
        presentExitActionSheet()
    }
    
    private func presentExitActionSheet() {
        let actionSheet = UIAlertController(title: "Exit Quiz",
                                            message: "Are you sure you want to exit the quiz?",
                                            preferredStyle: .actionSheet)
        
        actionSheet.addAction(UIAlertAction(title: "Leave", style: .default, handler: { [weak self] _ in
            
            guard let strongSelf = self else {
                return
            }
            
            QuizManager.shared.setNewHighScore(newHighScore: strongSelf.score) { (result) in
                switch result {
                case .success(let newHighScore):
                    print("New High Score!! -> \(newHighScore)")
                case .failure(let error):
                    print("Better luck Next time :/\n\(error.localizedDescription)")
                }
            }
            
            self?.navigationController?.popToRootViewController(animated: true)
            
        }))
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(actionSheet, animated: true)
    }
}


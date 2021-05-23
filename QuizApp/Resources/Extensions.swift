//
//  Extensions.swift
//  QuizApp
//
//  Created by McMoodie on 2021-05-21.
//

import UIKit

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

extension Notification.Name {
    static let didLogInNotification = Notification.Name("didLogInNotification")
}



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

extension String {
    func htmlToUtf8() -> String {
        let encodedData = self.data(using: .utf8)
        let attributedOptions: [NSAttributedString.DocumentReadingOptionKey: Any] = [
            .documentType: NSAttributedString.DocumentType.html,
            .characterEncoding: String.Encoding.utf8.rawValue
        ]
        
        do {
            let attributedString = try NSAttributedString(data: encodedData!, options: attributedOptions, documentAttributes: nil)
            let decodedString = attributedString.string
            return decodedString
        } catch {
            // error...
        }
        
        return String()
    }
}


//
//  ClearCircle.swift
//  Ketchup
//
//  Created by Jack Robinson on 7/28/24.
//

import Foundation
import UIKit
extension UIImage {
    static func clearCircle(radius: CGFloat, lineWidth: CGFloat, color: UIColor = .clear) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(CGSize(width: radius * 2, height: radius * 2), false, 0.0)
        defer { UIGraphicsEndImageContext() }
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        
        context.setLineWidth(lineWidth)
        context.setStrokeColor(color.cgColor)
        let rectangle = CGRect(x: lineWidth / 2, y: lineWidth / 2, width: radius * 2 - lineWidth, height: radius * 2 - lineWidth)
        context.addEllipse(in: rectangle)
        context.strokePath()
        
        return UIGraphicsGetImageFromCurrentImageContext()?.withRenderingMode(.alwaysOriginal)
    }
}





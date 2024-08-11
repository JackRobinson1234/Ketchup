//
//  TriggerHaptics.swift
//  Ketchup
//
//  Created by Jack Robinson on 8/10/24.
//

import Foundation
import UIKit
func triggerHapticFeedback(style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
    let generator = UIImpactFeedbackGenerator(style: style)
    generator.prepare()
    generator.impactOccurred()
}

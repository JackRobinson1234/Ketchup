//
//  Badges.swift
//  Ketchup
//
//  Created by Joe Ciminelli on 8/28/24.
//

import Foundation
import SwiftUI

// Enum to represent the different types of badges
enum BadgeType: String, Codable, Equatable, Hashable {
    case basic
    case advanced
    case limited
}

// Enum to represent the different types of badges
enum BadgeTier: String, Codable, Equatable, Hashable, Comparable {
    case unlocked
    case diamond
    case gold
    case silver
    case bronze
    case locked

    var rank: Int {
        switch self {
        case .unlocked: return 5
        case .diamond: return 4
        case .gold: return 3
        case .silver: return 2
        case .bronze: return 1
        case .locked: return 0
        }
    }
    
    static func < (lhs: BadgeTier, rhs: BadgeTier) -> Bool {
        return lhs.rank < rhs.rank
    }
    
    var displayName: String {
        switch self {
        case .unlocked:
            return "Unlocked"
        case .diamond:
            return "Diamond"
        case .gold:
            return "Gold"
        case .silver:
            return "Silver"
        case .bronze:
            return "Bronze"
        case .locked:
            return "Locked"
        }
    }
}

// Struct to represent individual criteria progress
struct BadgeCriteriaProgressItem: Codable, Equatable, Hashable {
    var task: String
    var current: Int
    var required: Int
}

// Struct to represent a badge
struct Badge: Identifiable, Codable, Equatable, Hashable {
    var id: String {
        return name
    }
    var name: String  // Name of the badge
    var type: BadgeType  // Type of the badge (basic, advanced, limited)
    var progress: [BadgeCriteriaProgressItem]  // Progress towards unlocking the badge
    var imageUrl: String?  // Optional: URL to the badge image, if available
    var tier: BadgeTier
    var rgbValues: [Double]
    var backgroundColor: Color {
        guard rgbValues.count == 3 else {
            return Color.clear
        }
        return Color(
            red: rgbValues[0] / 255.0,
            green: rgbValues[1] / 255.0,
            blue: rgbValues[2] / 255.0,
            opacity: tier == .locked ? 0.0 : 0.2 // No background for locked badges
        )
    }
    
    var textColor: Color {
        guard rgbValues.count == 3 else {
            return Color.black // Default color
        }
        return Color(
            red: rgbValues[0] / 255.0,
            green: rgbValues[1] / 255.0,
            blue: rgbValues[2] / 255.0,
            opacity: 1.0 // Full opacity for text
        )
    }
    
    
    static var badgeRules: [String: String] = [
        "Foodie": "Post reviews to level up this badge!",
        "Influencer": "Recieve engagement across your posts to level up this badge!",
        "Socialite": "Make some friends on Ketchup to level up this badge!"
    ]

    var rules: String {
        return Badge.badgeRules[name] ?? "No description available."
    }

    init(name: String, type: BadgeType, progress: [BadgeCriteriaProgressItem], imageUrl: String? = nil, tier: BadgeTier, rgbValues: [Double]) {
        self.name = name
        self.type = type
        self.progress = progress
        self.imageUrl = imageUrl
        self.tier = tier
        self.rgbValues = rgbValues
    }
}











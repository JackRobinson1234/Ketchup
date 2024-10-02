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
    var imageName: String
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
            opacity: tier == .locked ? 0.0 : 0.0 // No background for locked badges
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
    
    
    static var badgeDescriptions: [String: String] = [
        "Foodie": "Post reviews to level up this badge!",
        "Influencer": "Recieve engagement across your posts to level up this badge!",
        "Socialite": "Make some friends on Ketchup to level up this badge!",
        "Streaker": "Maintain streaks to level up this badge!",
        "Sampler": "Try 7 different cuisines in 7 days to unlock this badge! (Starts Monday and resets end of Sunday)",
        "Sigma": "Be the first to review a restuarant to unlock this badge!",
        "Viral": "Recieve 50 likes on a single post to unlock this badge!",
        "Yapper": "Reply to 50 comments to unlock this badge!",
        "Beta User": "A special badge given to those who participated in the Ketchup Beta.",
        "Launch": "A special badge only open for the first two weeks of launch! (Closes Oct 20th)"
    ]

    var description: String {
        return Badge.badgeDescriptions[name] ?? "No description available."
    }

    init(name: String, type: BadgeType, progress: [BadgeCriteriaProgressItem], imageName: String, tier: BadgeTier, rgbValues: [Double]) {
        self.name = name
        self.type = type
        self.progress = progress
        self.imageName = imageName
        self.tier = tier
        self.rgbValues = rgbValues
    }
}











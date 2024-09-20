//
//  Badges.swift
//  Ketchup
//
//  Created by Joe Ciminelli on 8/28/24.
//

import Foundation

// Enum to represent the different types of badges
enum BadgeType: String, Codable, Equatable, Hashable {
    case basic
    case advanced
    case limited
}

// Enum to represent the different types of badges
enum BadgeTier: String, Codable, Equatable, Hashable {
    case locked
    case bronze
    case silver
    case gold
    case diamond
    case unlocked
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
    
    
    static var badgeRules: [String: String] = [
        "Foodie": "Maximum 10 posts per day count towards Badge",
        "Influencer": "Someone bookmarking and un-bookmarking only counts as 1 (same for likes)"
    ]

    var rules: String {
        return Badge.badgeRules[name] ?? "No rules defined."
    }

    init(name: String, type: BadgeType, progress: [BadgeCriteriaProgressItem], imageUrl: String? = nil, tier: BadgeTier) {
        self.name = name
        self.type = type
        self.progress = progress
        self.imageUrl = imageUrl
        self.tier = tier
    }
}











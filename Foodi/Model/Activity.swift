//
//  Activity.swift
//  Foodi
//
//  Created by Jack Robinson on 5/1/24.
//

import Foundation
import Firebase
import SwiftUI

struct Activity: Identifiable, Codable {
    let id: String
    var username: String
    var postId: String?
    let timestamp: Timestamp
    let type: ActivityType
    let uid: String
    var user: User?
    var image: String?
    var restaurantId: String?
    var collectionId: String?
    var name: String?
}

enum ActivityType: Int, Codable {
    case newPost
    case newCollection
    case newCollectionItem
    
    var activityMessage: String {
        switch self {
        case .newPost: return " uploaded a Post"
        case .newCollection: return " created a new Collection"
        case .newCollectionItem: return " added a new Collection Item."
        
        }
    }
}

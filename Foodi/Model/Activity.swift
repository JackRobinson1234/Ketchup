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
    var image: String?
    var restaurantId: String?
    var collectionId: String?
    var name: String
    var postType: String?
    var profileImageUrl: String?
}

enum ActivityType: Int, Codable {
    case newPost
    case newCollection
    case newCollectionItem
}

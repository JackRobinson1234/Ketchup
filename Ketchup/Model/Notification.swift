//
//  Notification.swift
//  Foodi
//
//  Created by Jack Robinson on 2/1/24.
//

import Foundation
import Firebase
import FirebaseFirestoreInternal

struct Notification: Identifiable, Codable {
    let id: String
    var postId: String?
    let timestamp: Timestamp
    let type: NotificationType
    let uid: String
    var user: User?
    var postThumbnail: String?
    var username: String?
    var profileImageUrl: String?
    var text: String?
    var restaurantName: String?
    var restaurantId: String?
}

enum NotificationType: Int, Codable {
    case postLike
    case comment
    case follow
    case reviewLike
    
    var notificationMessage: String {
        switch self {
        case .postLike: return " liked one of your posts."
        case .comment: return " commented on one of your posts."
        case .follow: return " started following you."
        case .reviewLike: return " liked your review of "
        }
    }
}

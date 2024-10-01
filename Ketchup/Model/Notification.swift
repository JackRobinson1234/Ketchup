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
    var pollId: String?
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
    var commentId: String?
    var collectionId: String?
    var collectionCoverImage: [String]?
    var inviteStatus: InviteStatus?
    var collectionName: String?
    
}

enum NotificationType: Int, Codable {
    case postLike
    case comment
    case follow
    case reviewLike
    case commentMention
    case postCaptionMention
    case postWentWithMention
    case commentLike
    case commentReply
    case collectionLike
    case postBookmark
    case newUser  // New case for new user notifications
    case collectionInvite
    case collectionInviteAccepted
    case newCollectionItem
    case welcomeReferral  // New case for welcome notification to new user
    case newReferral
    var notificationMessage: String {
        switch self {
        case .postLike: return " liked one of your posts."
        case .comment: return " commented on one of your posts."
        case .follow: return " started following you."
        case .reviewLike: return " liked your review of "
        case .commentMention: return " mentioned you in a comment: "
        case .postCaptionMention: return " mentioned you in a post caption: "
        case .postWentWithMention: return " tagged you in a post."
        case .commentLike: return " liked your comment: "
        case .commentReply: return " replied to your comment: "
        case .collectionLike: return " liked your collection: "
        case .postBookmark: return " bookmarked your post."
        case .newUser: return " joined Ketchup!"
        case .collectionInvite: return " invited you to collaborate on a collection: "
        case .collectionInviteAccepted: return " accepted your invitation to collaborate on: "
        case .newCollectionItem: return " added an item to "
        case .welcomeReferral: return "Welcome to Ketchup! Do you want to follow the person who referred you?"
        case .newReferral: return "mentioned you as a referral!"

        }
    }
}

enum InviteStatus: Int, Codable {
    case pending
    case accepted
    case rejected
}

//
//  Comment.swift
//  Foodi
//
//  Created by Jack Robinson on 1/31/24.
//

import Foundation
import Firebase


struct Comment: Identifiable, Codable, Equatable, Hashable {
    var id: String
    let postOwnerUid: String
    let commentText: String
    let postId: String
    let timestamp: Timestamp
    let commentOwnerUid: String
    let commentOwnerUsername: String
    let commentOwnerProfileImageUrl: String?
    var mentionedUsers: [PostUser]?
    var likes: Int
    var didLike: Bool
    var replyTo: ReplyTo?
    var replyCount: Int
    var isHighlighted: Bool = false // Not to be encoded/decoded

    struct ReplyTo: Codable, Hashable {
        let commentId: String
        let username: String
        let userId: String
    }
    
    // Custom CodingKeys to exclude isHighlighted
    enum CodingKeys: String, CodingKey {
        case id
        case postOwnerUid
        case commentText
        case postId
        case timestamp
        case commentOwnerUid
        case commentOwnerUsername
        case commentOwnerProfileImageUrl
        case mentionedUsers
        case likes
        case didLike
        case replyTo
        case replyCount
    }
}

// PostUser struct (if not already defined)


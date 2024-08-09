//
//  Comment.swift
//  Foodi
//
//  Created by Jack Robinson on 1/31/24.
//

import Foundation
import Firebase


struct Comment: Identifiable, Codable, Equatable, Hashable {
    let id: String
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

    struct ReplyTo: Codable, Hashable {
        let commentId: String
        let username: String
        let userId: String
    }
}


// PostUser struct (if not already defined)


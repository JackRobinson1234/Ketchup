//
//  PollComment.swift
//  Ketchup
//
//  Created by Jack Robinson on 9/28/24.
//

import Foundation
struct PollComment: Identifiable, Codable {
    var id: String?
    let pollId: String
    let commentText: String
    let commentOwnerUid: String
    let commentOwnerUsername: String
    let commentOwnerProfileImageUrl: String?
    let timestamp: Date
    var likes: Int
    var didLike: Bool? = false
    var isHighlighted: Bool? = false
    var replyTo: ReplyTo?
    var mentionedUsers: [PostUser]? // Assuming you're using the same PostUser model
}

struct ReplyTo: Codable {
    let commentId: String
    let username: String
}

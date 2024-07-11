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
    var user: User?
}

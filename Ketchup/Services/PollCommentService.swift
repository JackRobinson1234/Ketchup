//
//  PollCommentService.swift
//  Ketchup
//
//  Created by Jack Robinson on 9/28/24.
//

import Foundation
import FirebaseFirestoreInternal
//class PollCommentService {
//    static let shared = PollCommentService()
//    private let db = Firestore.firestore()
//
//    func uploadComment(commentText: String, poll: Poll, mentionedUsers: [PostUser], replyTo: PollComment?) async throws -> PollComment? {
//        guard let user = await AuthService.shared.userSession else { return nil }
//        guard let pollId = poll.id else { return nil }
//        
//        let commentsRef = db.collection("polls").document(pollId).collection("comments").document()
//        let timestamp = Date()
//        let commentId = commentsRef.documentID
//        
//        let pollComment = PollComment(
//            id: commentId,
//            pollId: pollId,
//            commentText: commentText,
//            commentOwnerUid: user.id,
//            commentOwnerUsername: user.username,
//            commentOwnerProfileImageUrl: user.profileImageUrl,
//            timestamp: timestamp,
//            likes: 0,
//            replyTo: replyTo != nil ? ReplyTo(commentId: replyTo!.id ?? "", username: replyTo!.commentOwnerUsername) : nil,
//            mentionedUsers: mentionedUsers
//        )
//        
//        try commentsRef.setData(from: pollComment)
//        
//        // Update poll's comment count
//        let pollRef = db.collection("polls").document(pollId)
//        try await pollRef.updateData(["commentCount": FieldValue.increment(Int64(1))])
//        
//        return pollComment
//    }
//    
//    func fetchComments(poll: Poll) async throws -> [PollComment] {
//        guard let pollId = poll.id else { return [] }
//        let snapshot = try await db.collection("polls").document(pollId).collection("comments").order(by: "timestamp").getDocuments()
//        return try snapshot.documents.compactMap { try $0.data(as: PollComment.self) }
//    }
//    
//    func deleteComment(comment: PollComment, poll: Poll) async throws {
//        guard let pollId = poll.id, let commentId = comment.id else { return }
//        let commentRef = db.collection("polls").document(pollId).collection("comments").document(commentId)
//        try await commentRef.delete()
//        
//        // Update poll's comment count
//        let pollRef = db.collection("polls").document(pollId)
//        try await pollRef.updateData(["commentCount": FieldValue.increment(Int64(-1))])
//    }
//    
//    func likeComment(_ comment: PollComment, poll: Poll) async throws {
//        guard let pollId = poll.id, let commentId = comment.id, let userId = await AuthService.shared.userSession?.id else { return }
//        let likesRef = db.collection("polls").document(pollId).collection("comments").document(commentId).collection("likes").document(userId)
//        try await likesRef.setData([:])
//        let commentRef = db.collection("polls").document(pollId).collection("comments").document(commentId)
//        try await commentRef.updateData(["likes": FieldValue.increment(Int64(1))])
//    }
//    
//    func unlikeComment(_ comment: PollComment, poll: Poll) async throws {
//        guard let pollId = poll.id, let commentId = comment.id, let userId = await AuthService.shared.userSession?.id else { return }
//        let likesRef = db.collection("polls").document(pollId).collection("comments").document(commentId).collection("likes").document(userId)
//        try await likesRef.delete()
//        let commentRef = db.collection("polls").document(pollId).collection("comments").document(commentId)
//        try await commentRef.updateData(["likes": FieldValue.increment(Int64(-1))])
//    }
//    
//    func checkIfUserLikedComment(_ comment: PollComment, poll: Poll) async throws -> Bool {
//        guard let pollId = poll.id, let commentId = comment.id, let userId = await AuthService.shared.userSession?.id else { return false }
//        let likesRef = db.collection("polls").document(pollId).collection("comments").document(commentId).collection("likes").document(userId)
//        let snapshot = try await likesRef.getDocument()
//        return snapshot.exists
//    }
//}

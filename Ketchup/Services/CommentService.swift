//
//  CommentService.swift
//  Foodi
//
//  Created by Jack Robinson on 1/31/24.
//
import Foundation
import Firebase

class CommentService {
    static let shared = CommentService()
    private init() {}
    
    func fetchComments(for commentable: Commentable) async throws -> [Comment] {
        let commentsCollection = Firestore.firestore().collection(commentable.commentsCollectionPath)
        let comments = try await commentsCollection
            .order(by: "timestamp", descending: false)
            .getDocuments(as: Comment.self)
        return comments
    }
    
    func uploadComment(
        commentText: String,
        to commentable: Commentable,
        mentionedUsers: [PostUser],
        replyTo: Comment? = nil,
        originalCommentId: String? = nil
    ) async throws -> Comment? {
        let ref = Firestore.firestore().collection(commentable.commentsCollectionPath).document()
        guard let currentUid = Auth.auth().currentUser?.uid,
              let currentUser = await AuthService.shared.userSession else { return nil }
        
        var replyToData: Comment.ReplyTo?
        if let replyTo = replyTo {
            replyToData = Comment.ReplyTo(
                commentId: originalCommentId ?? replyTo.id,
                username: replyTo.commentOwnerUsername,
                userId: replyTo.commentOwnerUid
            )
        }
        
        let comment = Comment(
            id: ref.documentID,
            postOwnerUid: commentable.ownerUid ?? "",
            commentText: commentText,
            postId: commentable.id,
            timestamp: Timestamp(),
            commentOwnerUid: currentUid,
            commentOwnerUsername: currentUser.username,
            commentOwnerProfileImageUrl: currentUser.profileImageUrl,
            mentionedUsers: mentionedUsers,
            likes: 0,
            didLike: false,
            replyTo: replyToData,
            replyCount: 0
        )

        
        guard let commentData = try? Firestore.Encoder().encode(comment) else {
            return nil
        }
        
        try await ref.setData(commentData)
        
        if let originalCommentId = originalCommentId ?? replyTo?.id {
            try await incrementReplyCount(for: originalCommentId, in: commentable)
        }
        
        return comment
    }
    
    func incrementReplyCount(for commentId: String, in commentable: Commentable) async throws {
        let commentRef = Firestore.firestore().collection(commentable.commentsCollectionPath).document(commentId)
        try await commentRef.updateData(["replyCount": FieldValue.increment(Int64(1))])
    }
    
    func deleteComment(comment: Comment, from commentable: Commentable) async throws {
        let commentRef = Firestore.firestore().collection(commentable.commentsCollectionPath).document(comment.id)
        
        // First, delete all replies to this comment
        let replies = try await fetchReplies(for: comment, in: commentable)
        for reply in replies {
            try await deleteComment(comment: reply, from: commentable)
        }
        
        // Then delete the comment document itself
        try await commentRef.delete()
    }
    
    private func fetchReplies(for comment: Comment, in commentable: Commentable) async throws -> [Comment] {
        let commentsCollection = Firestore.firestore().collection(commentable.commentsCollectionPath)
        let snapshot = try await commentsCollection
            .whereField("replyTo.commentId", isEqualTo: comment.id)
            .getDocuments()
        return try snapshot.documents.compactMap { try $0.data(as: Comment.self) }
    }
    
    func likeComment(_ comment: Comment, in commentable: Commentable) async throws {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let commentLikesRef = Firestore.firestore().collection(commentable.commentsCollectionPath)
            .document(comment.id)
            .collection("comment-likes")
            .document(uid)
        try await commentLikesRef.setData([:])
    }
    
    func unlikeComment(_ comment: Comment, in commentable: Commentable) async throws {
        guard comment.likes > 0 else { return }
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let commentLikesRef = Firestore.firestore().collection(commentable.commentsCollectionPath)
            .document(comment.id)
            .collection("comment-likes")
            .document(uid)
        try await commentLikesRef.delete()
    }
    
    func checkIfUserLikedComment(_ comment: Comment, in commentable: Commentable) async throws -> Bool {
        guard let uid = Auth.auth().currentUser?.uid else { return false }
        let commentLikesRef = Firestore.firestore().collection(commentable.commentsCollectionPath)
            .document(comment.id)
            .collection("comment-likes")
            .document(uid)
        let snapshot = try await commentLikesRef.getDocument()
        return snapshot.exists
    }
}

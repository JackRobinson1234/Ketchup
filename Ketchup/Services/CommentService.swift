//
//  CommentService.swift
//  Foodi
//
//  Created by Jack Robinson on 1/31/24.
//
import Foundation
import Firebase

class CommentService {
    static let shared = CommentService() // Singleton instance
    private init() {}
    
    func fetchComments(post: Post) async throws -> [Comment] {
        let commentsCollection = FirestoreConstants.PostsCollection.document(post.id).collection("post-comments")
        let comments = try await commentsCollection
            .order(by: "timestamp", descending: false)
            .getDocuments(as: Comment.self)
        return comments
    }
    
    func uploadComment(commentText: String, post: Post, mentionedUsers: [PostUser]) async throws -> Comment? {
        let ref = FirestoreConstants.PostsCollection.document(post.id).collection("post-comments").document()
        guard let currentUid = Auth.auth().currentUser?.uid,
              let currentUser = await AuthService.shared.userSession else { return nil }
        
        let comment = Comment(
            id: ref.documentID,
            postOwnerUid: post.user.id,
            commentText: commentText,
            postId: post.id,
            timestamp: Timestamp(),
            commentOwnerUid: currentUid,
            commentOwnerUsername: currentUser.username,
            commentOwnerProfileImageUrl: currentUser.profileImageUrl,
            mentionedUsers: mentionedUsers,
            likes: 0,
            didLike: false
        )
        
        guard let commentData = try? Firestore.Encoder().encode(comment) else {
            return nil
        }
        
        try await ref.setData(commentData)
        return comment
    }
    
    func deleteComment(comment: Comment, post: Post) async throws {
        let commentRef = FirestoreConstants.PostsCollection.document(post.id)
            .collection("post-comments").document(comment.id)
        
        // Delete the comment document from Firestore
        try await commentRef.delete()
        
        // Optionally, update UI or perform additional tasks after deletion
    }
    func likeComment(_ comment: Comment, post: Post) async throws {
            guard let uid = Auth.auth().currentUser?.uid else { return }
            async let _ = try FirestoreConstants.PostsCollection.document(post.id)
                .collection("post-comments").document(comment.id)
                .collection("comment-likes").document(uid).setData([:])
            async let _ = try FirestoreConstants.UserCollection.document(uid)
                .collection("user-comment-likes").document(comment.id).setData([:])
        }
        
        func unlikeComment(_ comment: Comment, post: Post) async throws {
            guard comment.likes > 0 else { return }
            guard let uid = Auth.auth().currentUser?.uid else { return }
            async let _ = try FirestoreConstants.PostsCollection.document(post.id)
                .collection("post-comments").document(comment.id)
                .collection("comment-likes").document(uid).delete()
            async let _ = try FirestoreConstants.UserCollection.document(uid)
                .collection("user-comment-likes").document(comment.id).delete()
        }
        
        func checkIfUserLikedComment(_ comment: Comment, post: Post) async throws -> Bool {
            guard let uid = Auth.auth().currentUser?.uid else { return false }
            let snapshot = try await FirestoreConstants.PostsCollection.document(post.id)
                .collection("post-comments").document(comment.id)
                .collection("comment-likes").document(uid).getDocument()
            return snapshot.exists
        }
}

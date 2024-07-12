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
        do {
            let commentsCollection = FirestoreConstants.PostsCollection.document(post.id).collection("post-comments")
            let comments = try await commentsCollection
                .order(by: "timestamp", descending: true)
                .getDocuments(as: Comment.self)
            let userComments = try await self.fetchCommentUserData(comments: comments)
            return userComments
        } catch {
            print("error fetching comments")
        }
        return []
    }
    
    func fetchCommentUserData(comments: [Comment]) async throws -> [Comment] {
        var updatedComments = [Comment]()
        
        for comment in comments {
            do {
                let user = try await UserService.shared.fetchUser(withUid: comment.commentOwnerUid)
                var updatedComment = comment
                updatedComment.user = user
                updatedComments.append(updatedComment)
            } catch {
                print("Error fetching user for comment:", error.localizedDescription)
                // Handle or throw the error as needed
            }
        }
        
        return updatedComments
    }
    
    func uploadComment(commentText: String, post: Post, taggedUsers: [String: String]) async throws -> Comment? {
        let ref = FirestoreConstants.PostsCollection.document(post.id).collection("post-comments").document()
        guard let currentUid = Auth.auth().currentUser?.uid else { return nil }
        
        var comment = Comment(
            id: ref.documentID,
            postOwnerUid: post.user.id,
            commentText: commentText,
            postId: post.id,
            timestamp: Timestamp(),
            commentOwnerUid: currentUid,
            taggedUsers: taggedUsers
        )
        
        guard let commentData = try? Firestore.Encoder().encode(comment) else {
            return nil
        }
        
        async let _ = try ref.setData(commentData)
        
        if let currentUser = await AuthService.shared.userSession {
            comment.user = currentUser
        }
        return comment
    }
    
    func deleteComment(comment: Comment, post: Post) async throws {
        let commentRef = FirestoreConstants.PostsCollection.document(post.id)
            .collection("post-comments").document(comment.id)
        
        // Delete the comment document from Firestore
        try await commentRef.delete()
        
        // Optionally, update UI or perform additional tasks after deletion
    }
}

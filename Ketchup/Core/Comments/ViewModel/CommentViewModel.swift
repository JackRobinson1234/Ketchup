//
//  CommentViewModel.swift
//  Foodi
//
//  Created by Jack Robinson on 1/31/24.
//

import Foundation
import Combine
import SwiftUI
@MainActor
class CommentViewModel: ObservableObject {
    @Published var comments = [Comment]()
    @Published var commentText: String = "" {
           didSet {
               if commentText.count > 300 {
                   commentText = String(commentText.prefix(300))
                   charLimitReached = true
               } else {
                   charLimitReached = false
               }
           }
       }
    @Published var charLimitReached: Bool = false
    @Published var showEmptyView = false
    
    @Binding var post: Post
    @Published var showOptionsSheet: Bool = false
    @Published var selectedComment: Comment?
    @Published var selectedUserComment: Comment?
    var commentCountText: String {
        return "\(comments.count) comments"
    }
    init(post: Binding<Post>) {
        self._post = post
    }
    
    //MARK: fetchComments
    /// fetches comments for the current post
    func fetchComments() async throws {
        do {
            self.comments = try await CommentService.shared.fetchComments(post: post)
            showEmptyView = comments.isEmpty
        }
        catch {
            print("DEBUG: Failed to fetch comments with error: \(error.localizedDescription)")
        }
    }
    //MARK: uploadComment
    /// uploads the text as a comment to the corresponding post
    func uploadComment() async {
        guard !commentText.isEmpty else { return }
        do {
            guard let comment = try await CommentService.shared.uploadComment(commentText: commentText, post: post) else { return }
            commentText = ""
            comments.insert(comment, at: 0)
            $post.wrappedValue.commentCount += 1
            if showEmptyView { showEmptyView.toggle() }
        } catch {
            print("DEBUG: Failed to upload comment with error \(error.localizedDescription)")
        }
    }
    //MARK: deleteComment
    /// deletes the comment from firebase, decrements the current post in views comment count (cloud function does the firebase decrement), and removes from the comment array
    /// - Parameter comment: Comment to be deleted
    func deleteComment(comment: Comment) async throws {
        guard let index = comments.firstIndex(of: comment) else {
            return // Comment not found in the array
        }
        // Delete the comment from Firestore
        try await CommentService.shared.deleteComment(comment: comment, post: self.post)
        
        // Update the local comments array and post comment count
        comments.remove(at: index)
        $post.wrappedValue.commentCount -= 1
    }
}

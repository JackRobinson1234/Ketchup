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
    @Published var commentText = ""
    @Published var showEmptyView = false
    @Published var currentUser: User?
    
    @Binding var post: Post
    
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
}

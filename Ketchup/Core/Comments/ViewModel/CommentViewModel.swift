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
            checkForTagging()
        }
    }
    @Published var charLimitReached: Bool = false
    @Published var showEmptyView = false
    @Published var showOptionsSheet: Bool = false
    @Published var selectedComment: Comment?
    @Published var selectedUserComment: Comment?
    @Published var taggedUsers: [User] = []
    @Published var filteredTaggedUsers: [User] = []
    @Published var isTagging: Bool = false

    @Binding var post: Post
    var commentCountText: String {
        return "\(comments.count) comments"
    }

    init(post: Binding<Post>) {
        self._post = post
        fetchFollowingUsers()
    }
    
    // Fetch comments for the current post
    func fetchComments() async throws {
        do {
            self.comments = try await CommentService.shared.fetchComments(post: post)
            showEmptyView = comments.isEmpty
        } catch {
            print("DEBUG: Failed to fetch comments with error: \(error.localizedDescription)")
        }
    }
    
    // Delete the comment from firebase
    func deleteComment(comment: Comment) async throws {
        guard let index = comments.firstIndex(of: comment) else {
            return // Comment not found in the array
        }
        try await CommentService.shared.deleteComment(comment: comment, post: self.post)
        comments.remove(at: index)
        $post.wrappedValue.commentCount -= 1
    }
    
    // Fetch the users the current user is following (used for suggestion)
    private func fetchFollowingUsers() {
        Task {
            do {
                let users = try await UserService.shared.fetchFollowingUsers()
                DispatchQueue.main.async {
                    self.taggedUsers = users
                }
            } catch {
                print("Error fetching following users: \(error)")
            }
        }
    }
    
    func checkForTagging() {
        let words = commentText.split(separator: " ")

        if commentText.last == " " {
            isTagging = false
            filteredTaggedUsers = []
            return
        }

        guard let lastWord = words.last, lastWord.hasPrefix("@") else {
            isTagging = false
            filteredTaggedUsers = []
            return
        }

        let searchQuery = String(lastWord.dropFirst()).lowercased()
        if searchQuery.isEmpty {
            filteredTaggedUsers = taggedUsers
        } else {
            filteredTaggedUsers = taggedUsers.filter { $0.username.lowercased().contains(searchQuery) }
        }

        isTagging = !filteredTaggedUsers.isEmpty
    }

    func uploadComment() async {
        guard !commentText.isEmpty else { return }
        
        // Extract usernames from comment text and create the taggedUsers dictionary
        var taggedUsersDict: [String: String] = [:]
        let words = commentText.split(separator: " ")
        for word in words {
            if word.hasPrefix("@") {
                let username = String(word.dropFirst())
                if let user = taggedUsers.first(where: { $0.username == username }) {
                    taggedUsersDict[user.username] = user.id
                } else {
                    // Fetch user by username if not found in suggestions
                    if let fetchedUser = try? await UserService.shared.fetchUser(byUsername: username) {
                        taggedUsersDict[fetchedUser.username] = fetchedUser.id
                    } else {
                        // Mark as invalid if user is not found
                        taggedUsersDict[username] = "invalid"
                    }
                }
            }
        }
        
        do {
            guard let comment = try await CommentService.shared.uploadComment(commentText: commentText, post: post, taggedUsers: taggedUsersDict) else { return }
            commentText = ""
            comments.insert(comment, at: 0)
            $post.wrappedValue.commentCount += 1
            if showEmptyView { showEmptyView.toggle() }
        } catch {
            print("DEBUG: Failed to upload comment with error \(error.localizedDescription)")
        }
    }
}







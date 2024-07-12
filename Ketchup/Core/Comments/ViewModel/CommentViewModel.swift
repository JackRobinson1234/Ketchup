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
    
    @Published var taggedUserRanges: [NSRange: String] = [:]
    
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
    
    // Fetch the users the current user is following
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
        guard let lastWord = words.last, lastWord.hasPrefix("@") else {
            isTagging = false
            filteredTaggedUsers = []
            updateTaggedUserRanges()
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

    func updateTaggedUserRanges() {
        let pattern = "@[A-Za-z0-9_]+"
        let regex = try! NSRegularExpression(pattern: pattern, options: [])
        let matches = regex.matches(in: commentText, options: [], range: NSRange(location: 0, length: commentText.utf16.count))

        taggedUserRanges.removeAll()

        for match in matches {
            let usernameRange = match.range(at: 0)
            let username = (commentText as NSString).substring(with: usernameRange)
            taggedUserRanges[usernameRange] = username
        }
    }

    func uploadComment() async {
        guard !commentText.isEmpty else { return }
        do {
            guard let comment = try await CommentService.shared.uploadComment(commentText: commentText, post: post) else { return }
            commentText = ""
            comments.insert(comment, at: 0)
            $post.wrappedValue.commentCount += 1
            if showEmptyView { showEmptyView.toggle() }
            updateTaggedUserRanges()
        } catch {
            print("DEBUG: Failed to upload comment with error \(error.localizedDescription)")
        }
    }
}



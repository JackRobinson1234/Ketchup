import Foundation
import Combine
import SwiftUI

@MainActor

class CommentViewModel: ObservableObject {
    @Published var comments = [Comment]()
    @Published var replies: [String: [Comment]] = [:]
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
    @Published var replyingTo: Comment?
    @Published var lastAddedCommentId: String?
    @Published var shouldFocusTextField: Bool = false
    
    @Binding var post: Post
    var commentCountText: String {
        return "\(comments.count) comments"
    }
    
    init(post: Binding<Post>) {
        self._post = post
    }
    func initiateReply(to comment: Comment) {
        let originalComment = findOriginalComment(for: comment)
        replyingTo = comment
        commentText = "@\(comment.commentOwnerUsername) "
        shouldFocusTextField = true
    }
    private func findOriginalComment(for comment: Comment) -> Comment {
        if let replyTo = comment.replyTo {
            return comments.first { $0.id == replyTo.commentId } ?? comment
        }
        return comment
    }
    
    func cancelReply() {
        replyingTo = nil
        commentText = ""
        shouldFocusTextField = false
    }
    
    
    // Fetch comments for the current post
    func fetchComments() async throws {
        self.comments = try await CommentService.shared.fetchComments(post: post)
        await checkIfUserLikedComments()
        organizeReplies()
    }
    
    private func organizeReplies() {
        replies.removeAll()
        for comment in comments {
            if let replyTo = comment.replyTo {
                if replies[replyTo.commentId] == nil {
                    replies[replyTo.commentId] = []
                }
                replies[replyTo.commentId]?.append(comment)
            }
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
    
    // Like a comment
    func like(_ comment: Comment) async {
            do {
                try await CommentService.shared.likeComment(comment, post: post)
                updateCommentLikeStatus(comment, didLike: true, likesChange: 1)
            } catch {
                print("DEBUG: Failed to like comment with error \(error.localizedDescription)")
            }
        }
        
        func unlike(_ comment: Comment) async {
            do {
                try await CommentService.shared.unlikeComment(comment, post: post)
                updateCommentLikeStatus(comment, didLike: false, likesChange: -1)
            } catch {
                print("DEBUG: Failed to unlike comment with error \(error.localizedDescription)")
            }
        }
        
        private func updateCommentLikeStatus(_ comment: Comment, didLike: Bool, likesChange: Int) {
            if let index = comments.firstIndex(where: { $0.id == comment.id }) {
                comments[index].didLike = didLike
                comments[index].likes += likesChange
            } else {
                for (key, var repliesArray) in replies {
                    if let replyIndex = repliesArray.firstIndex(where: { $0.id == comment.id }) {
                        repliesArray[replyIndex].didLike = didLike
                        repliesArray[replyIndex].likes += likesChange
                        replies[key] = repliesArray
                        break
                    }
                }
            }
        }
    
    func checkIfUserLikedComments() async {
        guard !comments.isEmpty else { return }
        var updatedComments = comments
        for i in 0..<updatedComments.count {
            do {
                let comment = updatedComments[i]
                let didLike = try await CommentService.shared.checkIfUserLikedComment(comment, post: post)
                updatedComments[i].didLike = didLike
            } catch {
                print("DEBUG: Failed to check if user liked comment")
            }
        }
        
        self.comments = updatedComments
    }
    
    func fetchFollowingUsers() {
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
        
        isTagging = true
    }
    
    func checkForAlgoliaTagging() -> String{
        let words = commentText.split(separator: " ")
        
        if commentText.last == " " {
            isTagging = false
            filteredTaggedUsers = []
            return ""
        }
        
        guard let lastWord = words.last, lastWord.hasPrefix("@") else {
            isTagging = false
            filteredTaggedUsers = []
            return ""
        }
        
        let searchQuery = String(lastWord.dropFirst()).lowercased()
        if searchQuery.isEmpty {
            filteredTaggedUsers = taggedUsers
        } else {
            filteredTaggedUsers = taggedUsers.filter { $0.username.lowercased().contains(searchQuery) }
        }
        isTagging = true
        return searchQuery
    }
    
    func parseMentionedUsers(from text: String) async -> [PostUser] {
        var mentionedUserArray: [PostUser] = []
        let words = text.split(separator: " ")
        
        for word in words where word.hasPrefix("@") {
            let username = String(word.dropFirst())
            if let user = taggedUsers.first(where: { $0.username == username }) {
                mentionedUserArray.append(PostUser(id: user.id,
                                                   fullname: user.fullname,
                                                   profileImageUrl: user.profileImageUrl,
                                                   privateMode: user.privateMode,
                                                   username: user.username))
            } else {
                // Fetch user by username if not found in suggestions
                if let fetchedUser = try? await UserService.shared.fetchUser(byUsername: username) {
                    mentionedUserArray.append(PostUser(id: fetchedUser.id,
                                                       fullname: fetchedUser.fullname,
                                                       profileImageUrl: fetchedUser.profileImageUrl,
                                                       privateMode: fetchedUser.privateMode,
                                                       username: fetchedUser.username))
                } else {
                    mentionedUserArray.append(PostUser(id: "invalid",
                                                       fullname: "invalid",
                                                       profileImageUrl: nil,
                                                       privateMode: false,
                                                       username: username))
                }
            }
        }
        
        return mentionedUserArray
    }
    
    func uploadComment() async {
        guard !commentText.isEmpty else { return }
        
        do {
            let mentionedUsers = await parseMentionedUsers(from: commentText)
            let originalComment = replyingTo.flatMap(findOriginalComment)
            
            guard let comment = try await CommentService.shared.uploadComment(
                commentText: commentText,
                post: post,
                mentionedUsers: mentionedUsers,
                replyTo: replyingTo,
                originalCommentId: originalComment?.id
            ) else { return }
            
            DispatchQueue.main.async {
                self.lastAddedCommentId = comment.id
                if let replyTo = comment.replyTo {
                    if self.replies[replyTo.commentId] == nil {
                        self.replies[replyTo.commentId] = []
                    }
                    self.replies[replyTo.commentId]?.append(comment)
                    // Update the reply count of the original comment
                    if let index = self.comments.firstIndex(where: { $0.id == replyTo.commentId }) {
                        self.comments[index].replyCount += 1
                    }
                } else {
                    self.comments.append(comment)
                }
                self.$post.wrappedValue.commentCount += 1
                if self.showEmptyView { self.showEmptyView = false }
                self.commentText = ""
                self.replyingTo = nil
                self.shouldFocusTextField = false
            }
        } catch {
            print("DEBUG: Failed to upload comment with error \(error.localizedDescription)")
        }
    }
}







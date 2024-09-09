import Foundation
import FirebaseFirestoreInternal
import Combine
import SwiftUI

@MainActor
class CommentViewModel: ObservableObject {
    @Published var organizedComments: [(comment: Comment, replies: [Comment])] = []
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
    @Published var replyingTo: (comment: Comment, replyToUser: String)?
    @Published var lastAddedCommentId: String?
    @Published var shouldFocusTextField: Bool = false
    @Binding var post: Post
    var commentCountText: String {
        return "\(post.commentCount) comments"
    }
    
    init(post: Binding<Post>) {
        self._post = post
    }
    func initiateReply(to comment: Comment, replyToUser: String) {
        /// if replying to a reply, this logic handles that by resetting the id to the very original comment
        var updatedComment = comment
        if let originalCommentId =  comment.replyTo?.commentId {
            updatedComment.id = originalCommentId
        }
        replyingTo = (updatedComment, replyToUser)
        commentText = "@\(replyToUser) "
        shouldFocusTextField = true
        highlightComment(comment.id)
        
    }
    
    func cancelReply() {
        replyingTo = nil
        commentText = ""
        shouldFocusTextField = false
    }
    
    
    
    
    // Fetch comments for the current post
    func fetchComments() async throws {
        let fetchedComments = try await CommentService.shared.fetchComments(post: post)
        
        await checkIfUserLikedComments(comments: fetchedComments)
        showEmptyView = organizedComments.isEmpty
        await MainActor.run {
            self.lastAddedCommentId = self.organizedComments.last?.comment.id
        }
    }
    
    private func organizeComments(_ comments: [Comment]) {
        var topLevelComments: [(comment: Comment, replies: [Comment])] = []
        var repliesDictionary: [String: [Comment]] = [:]
        
        for comment in comments {
            if let replyTo = comment.replyTo {
                if repliesDictionary[replyTo.commentId] == nil {
                    repliesDictionary[replyTo.commentId] = []
                }
                repliesDictionary[replyTo.commentId]?.append(comment)
            } else {
                topLevelComments.append((comment: comment, replies: []))
            }
        }
        
        for (index, topLevelComment) in topLevelComments.enumerated() {
            if let replies = repliesDictionary[topLevelComment.comment.id] {
                topLevelComments[index].replies = replies.sorted(by: { $0.timestamp.dateValue() < $1.timestamp.dateValue() })
            }
        }
        
        DispatchQueue.main.async {
            // Sort top-level comments in ascending order (oldest to newest)
            self.organizedComments = topLevelComments.sorted(by: { $0.comment.timestamp.dateValue() < $1.comment.timestamp.dateValue() })
        }
        //print("Setting new comment ID")
        //lastAddedCommentId = organizedComments.last?.comment.id
        }
    
    
    // Delete the comment from firebase
    
    func deleteComment(comment: Comment) async throws {
        try await CommentService.shared.deleteComment(comment: comment, post: self.post)
        
        DispatchQueue.main.async {
            if let index = self.organizedComments.firstIndex(where: { $0.comment.id == comment.id }) {
                // This is a main comment, delete it along with all its replies
                let commentsToRemoveCount = 1 + self.organizedComments[index].replies.count
                self.organizedComments.remove(at: index)
                self.$post.wrappedValue.commentCount -= commentsToRemoveCount
            } else {
                // This is a reply, find and remove it from the appropriate replies list
                for i in 0..<self.organizedComments.count {
                    if let replyIndex = self.organizedComments[i].replies.firstIndex(where: { $0.id == comment.id }) {
                        self.organizedComments[i].replies.remove(at: replyIndex)
                        self.$post.wrappedValue.commentCount -= 1
                        break
                    }
                }
            }
            //self.lastAddedCommentId = self.organizedComments.last?.comment.id
            
        }
        
    }
    
    
    // Like a comment
    
    func like(_ comment: Comment) async {
        do {
            try await CommentService.shared.likeComment(comment, post: post)
            await MainActor.run {
                updateCommentLikeStatus(comment, didLike: true, likesChange: 1)
            }
        } catch {
            //print("DEBUG: Failed to like comment with error \(error.localizedDescription)")
        }
    }
    
    func unlike(_ comment: Comment) async {
        do {
            try await CommentService.shared.unlikeComment(comment, post: post)
            await MainActor.run {
                updateCommentLikeStatus(comment, didLike: false, likesChange: -1)
            }
        } catch {
            //print("DEBUG: Failed to unlike comment with error \(error.localizedDescription)")
        }
    }
    
    private func updateCommentLikeStatus(_ comment: Comment, didLike: Bool, likesChange: Int) {
        for i in 0..<organizedComments.count {
            if organizedComments[i].comment.id == comment.id {
                organizedComments[i].comment.didLike = didLike
                organizedComments[i].comment.likes += likesChange
                break
            }
            for j in 0..<organizedComments[i].replies.count {
                if organizedComments[i].replies[j].id == comment.id {
                    organizedComments[i].replies[j].didLike = didLike
                    organizedComments[i].replies[j].likes += likesChange
                    break
                }
            }
        }
    }
    
    func checkIfUserLikedComments(comments: [Comment]) async {
        var updatedComments = comments
        for i in 0..<updatedComments.count {
            do {
                let comment = updatedComments[i]
                let didLike = try await CommentService.shared.checkIfUserLikedComment(comment, post: post)
                updatedComments[i].didLike = didLike
            } catch {
                //print("DEBUG: Failed to check if user liked comment")
            }
        }
        await MainActor.run {
            organizeComments(updatedComments)
        }
    }
    
    
    func fetchFollowingUsers() {
        Task {
            do {
                let users = try await UserService.shared.fetchFollowingUsers()
                DispatchQueue.main.async {
                    self.taggedUsers = users
                }
            } catch {
                //print("Error fetching following users: \(error)")
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
            
            guard let comment = try await CommentService.shared.uploadComment(
                commentText: commentText,
                post: post,
                mentionedUsers: mentionedUsers,
                replyTo: replyingTo?.comment
            ) else { return }
            
            DispatchQueue.main.async {
                
                if let replyingTo = self.replyingTo {
                    if let index = self.organizedComments.firstIndex(where: { $0.comment.id == replyingTo.comment.id }) {
                        self.organizedComments[index].replies.append(comment)
                    }
                } else {
                    // Append the new comment at the bottom of the list
                    self.organizedComments.append((comment: comment, replies: []))
                }
                self.$post.wrappedValue.commentCount += 1
                if self.showEmptyView { self.showEmptyView = false }
                self.commentText = ""
                self.replyingTo = nil
                self.shouldFocusTextField = false
                self.lastAddedCommentId = comment.id
                // Highlight the newly added comment
                Task {
                    
                }
            }
            await MainActor.run {
                self.highlightComment(comment.id)
            }
        } catch {
            //print("DEBUG: Failed to upload comment with error \(error.localizedDescription)")
        }
    }
    func highlightComment(_ commentId: String) {
        for i in 0..<self.organizedComments.count {
            if self.organizedComments[i].comment.id == commentId {
                withAnimation(.easeIn(duration: 0.3)) {
                    self.organizedComments[i].comment.isHighlighted = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    withAnimation(.easeOut(duration: 0.3)) {
                        self.organizedComments[i].comment.isHighlighted = false
                    }
                }
                break
            }
            for j in 0..<self.organizedComments[i].replies.count {
                if self.organizedComments[i].replies[j].id == commentId {
                    withAnimation(.easeIn(duration: 0.3)) {
                        self.organizedComments[i].replies[j].isHighlighted = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        withAnimation(.easeOut(duration: 0.3)) {
                            self.organizedComments[i].replies[j].isHighlighted = false
                        }
                    }
                    break
                }
            }
        }
    }
}

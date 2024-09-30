//
//  PollCommentsViewModel.swift
//  Ketchup
//
//  Created by Jack Robinson on 9/28/24.
//

import Foundation
import SwiftUI
//@MainActor
//class PollCommentViewModel: ObservableObject {
//    @Published var organizedComments: [(comment: PollComment, replies: [PollComment])] = []
//    @Published var commentText: String = "" {
//        didSet {
//            if commentText.count > 300 {
//                commentText = String(commentText.prefix(300))
//                charLimitReached = true
//            } else {
//                charLimitReached = false
//            }
//            checkForTagging()
//        }
//    }
//    @Published var charLimitReached: Bool = false
//    @Published var showEmptyView = false
//    @Published var showOptionsSheet: Bool = false
//    @Published var selectedComment: PollComment?
//    @Published var selectedUserComment: PollComment?
//    @Published var taggedUsers: [User] = []
//    @Published var filteredTaggedUsers: [User] = []
//    @Published var isTagging: Bool = false
//    @Published var replyingTo: (comment: PollComment, replyToUser: String)?
//    @Published var lastAddedCommentId: String?
//    @Published var shouldFocusTextField: Bool = false
//    @Binding var poll: Poll
//    
//    var commentCountText: String {
//        return "\(poll.commentCount) comments"
//    }
//    
//    init(poll: Binding<Poll>) {
//        self._poll = poll
//    }
//    
//    func initiateReply(to comment: PollComment, replyToUser: String) {
//        var updatedComment = comment
//        if let originalCommentId = comment.replyTo?.commentId {
//            updatedComment.id = originalCommentId
//        }
//        replyingTo = (updatedComment, replyToUser)
//        commentText = "@\(replyToUser) "
//        shouldFocusTextField = true
//        highlightComment(comment.id ?? "")
//    }
//    
//    func cancelReply() {
//        replyingTo = nil
//        commentText = ""
//        shouldFocusTextField = false
//    }
//    
//    func fetchComments() async throws {
//        let fetchedComments = try await PollCommentService.shared.fetchComments(poll: poll)
//        await checkIfUserLikedComments(comments: fetchedComments)
//        showEmptyView = organizedComments.isEmpty
//        await MainActor.run {
//            self.lastAddedCommentId = self.organizedComments.last?.comment.id
//        }
//    }
//    
//    private func organizeComments(_ comments: [PollComment]) {
//        var topLevelComments: [(comment: PollComment, replies: [PollComment])] = []
//        var repliesDictionary: [String: [PollComment]] = [:]
//        
//        for comment in comments {
//            if let replyTo = comment.replyTo {
//                if repliesDictionary[replyTo.commentId] == nil {
//                    repliesDictionary[replyTo.commentId] = []
//                }
//                repliesDictionary[replyTo.commentId]?.append(comment)
//            } else {
//                topLevelComments.append((comment: comment, replies: []))
//            }
//        }
//        
//        for (index, topLevelComment) in topLevelComments.enumerated() {
//            if let replies = repliesDictionary[topLevelComment.comment.id ?? ""] {
//                topLevelComments[index].replies = replies.sorted(by: { $0.timestamp < $1.timestamp })
//            }
//        }
//        
//        DispatchQueue.main.async {
//            self.organizedComments = topLevelComments.sorted(by: { $0.comment.timestamp < $1.comment.timestamp })
//        }
//    }
//    
//    func deleteComment(comment: PollComment) async throws {
//        try await PollCommentService.shared.deleteComment(comment: comment, poll: self.poll)
//        
//        DispatchQueue.main.async {
//            if let index = self.organizedComments.firstIndex(where: { $0.comment.id == comment.id }) {
//                let commentsToRemoveCount = 1 + self.organizedComments[index].replies.count
//                self.organizedComments.remove(at: index)
//                self.$poll.wrappedValue.commentCount -= commentsToRemoveCount
//            } else {
//                for i in 0..<self.organizedComments.count {
//                    if let replyIndex = self.organizedComments[i].replies.firstIndex(where: { $0.id == comment.id }) {
//                        self.organizedComments[i].replies.remove(at: replyIndex)
//                        self.$poll.wrappedValue.commentCount -= 1
//                        break
//                    }
//                }
//            }
//        }
//    }
//    
//    func like(_ comment: PollComment) async {
//        do {
//            try await PollCommentService.shared.likeComment(comment, poll: poll)
//            await MainActor.run {
//                updateCommentLikeStatus(comment, didLike: true, likesChange: 1)
//            }
//        } catch {
//            print("Failed to like comment: \(error.localizedDescription)")
//        }
//    }
//    
//    func unlike(_ comment: PollComment) async {
//        do {
//            try await PollCommentService.shared.unlikeComment(comment, poll: poll)
//            await MainActor.run {
//                updateCommentLikeStatus(comment, didLike: false, likesChange: -1)
//            }
//        } catch {
//            print("Failed to unlike comment: \(error.localizedDescription)")
//        }
//    }
//    
//    private func updateCommentLikeStatus(_ comment: PollComment, didLike: Bool, likesChange: Int) {
//        for i in 0..<organizedComments.count {
//            if organizedComments[i].comment.id == comment.id {
//                organizedComments[i].comment.didLike = didLike
//                organizedComments[i].comment.likes += likesChange
//                break
//            }
//            for j in 0..<organizedComments[i].replies.count {
//                if organizedComments[i].replies[j].id == comment.id {
//                    organizedComments[i].replies[j].didLike = didLike
//                    organizedComments[i].replies[j].likes += likesChange
//                    break
//                }
//            }
//        }
//    }
//    
//    func checkIfUserLikedComments(comments: [PollComment]) async {
//        var updatedComments = comments
//        for i in 0..<updatedComments.count {
//            do {
//                let comment = updatedComments[i]
//                let didLike = try await PollCommentService.shared.checkIfUserLikedComment(comment, poll: poll)
//                updatedComments[i].didLike = didLike
//            } catch {
//                print("Failed to check if user liked comment")
//            }
//        }
//        await MainActor.run {
//            organizeComments(updatedComments)
//        }
//    }
//    
//    func fetchFollowingUsers() {
//        Task {
//            do {
//                let users = try await UserService.shared.fetchFollowingUsers()
//                DispatchQueue.main.async {
//                    self.taggedUsers = users
//                }
//            } catch {
//                print("Error fetching following users: \(error)")
//            }
//        }
//    }
//    
//    func checkForTagging() {
//        let words = commentText.split(separator: " ")
//        
//        if commentText.last == " " {
//            isTagging = false
//            filteredTaggedUsers = []
//            return
//        }
//        
//        guard let lastWord = words.last, lastWord.hasPrefix("@") else {
//            isTagging = false
//            filteredTaggedUsers = []
//            return
//        }
//        
//        let searchQuery = String(lastWord.dropFirst()).lowercased()
//        if searchQuery.isEmpty {
//            filteredTaggedUsers = taggedUsers
//        } else {
//            filteredTaggedUsers = taggedUsers.filter { $0.username.lowercased().contains(searchQuery) }
//        }
//        
//        isTagging = true
//    }
//    
//    func parseMentionedUsers(from text: String) async -> [PostUser] {
//        var mentionedUserArray: [PostUser] = []
//        let words = text.split(separator: " ")
//        
//        for word in words where word.hasPrefix("@") {
//            let username = String(word.dropFirst())
//            if let user = taggedUsers.first(where: { $0.username == username }) {
//                mentionedUserArray.append(PostUser(id: user.id,
//                                                   fullname: user.fullname,
//                                                   profileImageUrl: user.profileImageUrl,
//                                                   privateMode: user.privateMode,
//                                                   username: user.username))
//            } else {
//                if let fetchedUser = try? await UserService.shared.fetchUser(byUsername: username) {
//                    mentionedUserArray.append(PostUser(id: fetchedUser.id,
//                                                       fullname: fetchedUser.fullname,
//                                                       profileImageUrl: fetchedUser.profileImageUrl,
//                                                       privateMode: fetchedUser.privateMode,
//                                                       username: fetchedUser.username))
//                } else {
//                    mentionedUserArray.append(PostUser(id: "invalid",
//                                                       fullname: "invalid",
//                                                       profileImageUrl: nil,
//                                                       privateMode: false,
//                                                       username: username))
//                }
//            }
//        }
//        
//        return mentionedUserArray
//    }
//    
//    func uploadComment() async {
//        guard !commentText.isEmpty else { return }
//        
//        do {
//            let mentionedUsers = await parseMentionedUsers(from: commentText)
//            
//            guard let comment = try await PollCommentService.shared.uploadComment(
//                commentText: commentText,
//                poll: poll,
//                mentionedUsers: mentionedUsers,
//                replyTo: replyingTo?.comment
//            ) else { return }
//            
//            DispatchQueue.main.async {
//                if let replyingTo = self.replyingTo {
//                    if let index = self.organizedComments.firstIndex(where: { $0.comment.id == replyingTo.comment.id }) {
//                        self.organizedComments[index].replies.append(comment)
//                    }
//                } else {
//                    self.organizedComments.append((comment: comment, replies: []))
//                }
//                self.$poll.wrappedValue.commentCount += 1
//                if self.showEmptyView { self.showEmptyView = false }
//                self.commentText = ""
//                self.replyingTo = nil
//                self.shouldFocusTextField = false
//                self.lastAddedCommentId = comment.id
//            }
//            await MainActor.run {
//                self.highlightComment(comment.id ?? "")
//            }
//        } catch {
//            print("Failed to upload comment: \(error.localizedDescription)")
//        }
//    }
//    
//    func highlightComment(_ commentId: String) {
//        for i in 0..<self.organizedComments.count {
//            if self.organizedComments[i].comment.id == commentId {
//                withAnimation(.easeIn(duration: 0.3)) {
//                    self.organizedComments[i].comment.isHighlighted = true
//                }
//                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
//                    withAnimation(.easeOut(duration: 0.3)) {
//                        self.organizedComments[i].comment.isHighlighted = false
//                    }
//                }
//                break
//            }
//            for j in 0..<self.organizedComments[i].replies.count {
//                if self.organizedComments[i].replies[j].id == commentId {
//                    withAnimation(.easeIn(duration: 0.3)) {
//                        self.organizedComments[i].replies[j].isHighlighted = true
//                    }
//                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
//                        withAnimation(.easeOut(duration: 0.3)) {
//                            self.organizedComments[i].replies[j].isHighlighted = false
//                        }
//                    }
//                    break
//                }
//            }
//        }
//    }
//}

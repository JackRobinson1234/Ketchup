//
//  ProfileUserListsViewModel.swift
//  Foodi
//
//  Created by Jack Robinson on 4/22/24.
//
import Foundation
import Firebase
import FirebaseAuth
import SwiftUI
@MainActor
class ProfileUserListViewModel: ObservableObject {
    @Published var users = [User]()
    @Published var isLoading = false
    @Published var hasMoreUsers = true
    @Published var error: Error?
    
    private let config: UserListConfig
    private var lastDocument: QueryDocumentSnapshot?
    private let limit = 20
    private let userService = UserService.shared
    
    init(config: UserListConfig) {
        self.config = config
        fetchUsers()
    }
    
    func fetchUsers() {
        guard !isLoading, hasMoreUsers else { return }
        isLoading = true
        
        Task {
            do {
                let (newUsers, lastDoc) = try await fetchUsersForConfig()
                await MainActor.run {
                    self.users.append(contentsOf: newUsers)
                    self.lastDocument = lastDoc
                    self.hasMoreUsers = newUsers.count == self.limit
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.error = error
                    self.isLoading = false
                }
            }
        }
    }
    
    private func fetchUsersForConfig() async throws -> ([User], QueryDocumentSnapshot?) {
        let query = configureQuery()
        let snapshot = try await query.getDocuments()
        
        let users = try await withThrowingTaskGroup(of: User?.self) { group in
            for document in snapshot.documents {
                group.addTask {
                    try? await self.userService.fetchUser(withUid: document.documentID)
                }
            }
            
            var fetchedUsers = [User]()
            for try await user in group {
                if let user = user {
                    fetchedUsers.append(user)
                }
            }
            return fetchedUsers
        }
        
        return (users, snapshot.documents.last)
    }
    
    private func configureQuery() -> Query {
        var query: Query
        switch config {
        case .followers(let uid):
            query = FirestoreConstants.FollowersCollection.document(uid).collection("user-followers")
        case .following(let uid):
            query = FirestoreConstants.FollowingCollection.document(uid).collection("user-following")
        case .likes(let postId):
            query = FirestoreConstants.PostsCollection.document(postId).collection("post-likes")
        }
        
        query = query.limit(to: limit)
        if let lastDocument = lastDocument {
            query = query.start(afterDocument: lastDocument)
        }
        
        return query
    }
    
    func checkIfUserIsFollowed(user: User) async throws -> Bool {
        // If we've already checked the follow status, return the stored value
      
        
        // If we haven't checked yet, fetch the status from the server
        let isFollowed = try await userService.checkIfUserIsFollowed(uid: user.id)
        
        // Update the user in the users array
        if let index = users.firstIndex(where: { $0.id == user.id }) {
            DispatchQueue.main.async {
                self.users[index].isFollowed = isFollowed
            }
        }
        
        return isFollowed
    }
    
    func updateUserFollowStatus(user: User, isFollowed: Bool) {
        if let index = users.firstIndex(where: { $0.id == user.id }) {
            DispatchQueue.main.async {
                self.users[index].isFollowed = isFollowed
            }
        }
    }
    
    func follow(userId: String) async throws {
        try await userService.follow(uid: userId)
        updateFollowStatus(for: userId, isFollowed: true)
    }
    
    func unfollow(userId: String) async throws {
        try await userService.unfollow(uid: userId)
        updateFollowStatus(for: userId, isFollowed: false)
    }
    
    private func updateFollowStatus(for userId: String, isFollowed: Bool) {
        if let index = users.firstIndex(where: { $0.id == userId }) {
            DispatchQueue.main.async {
                self.users[index].isFollowed = isFollowed
            }
        }
    }
}
enum UserListConfig: Hashable {
    case followers(uid: String)
    case following(uid: String)
    case likes(uid: String)
    
    
    var navigationTitle: String {
        switch self {
        case .followers: return "Followers"
        case .following: return "Following"
        case .likes: return "Likes"
        }
    }
}
    

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
    //@State var searchText = ""
    @Published var users = [User]()
    private let config: UserListConfig
    private var userLastDoc: QueryDocumentSnapshot?
    init(config: UserListConfig) {
        self.config = config
        fetchUsers(forConfig: config)
    }
    //MARK: fetchUsers(forConfig:)
    /// called from the init, calls the correct function depending on which list you want
    /// - Parameter config: UserListConfig that specifies which kind of list to display
    func fetchUsers(forConfig config: UserListConfig) {
        Task {
            switch config {
            case .followers(let uid):
                try await fetchFollowerUsers(forUid: uid)
            case .following(let uid):
                try await fetchFollowingUsers(forUid: uid)
            case .likes(let postId):
                try await fetchPostLikesUsers(forPostId: postId)
                
            }
        }
    }
    //MARK: fetchPostLikesUsers
    /// fetches which users liked a certain post
    /// - Parameter postId: <#postId description#>
    private func fetchPostLikesUsers(forPostId postId: String) async throws {
        guard let snapshot = try? await FirestoreConstants.PostsCollection.document(postId).collection("post-likes").getDocuments() else { return }
        try await fetchUsers(snapshot)
    }
    //MARK: fetchFollowerUsers
    /// Fetches the list of followers for a certain user
    /// - Parameter uid: fetches all followers for this user
    private func fetchFollowerUsers(forUid uid: String) async throws {
        guard let snapshot = try? await FirestoreConstants.FollowersCollection.document(uid).collection("user-followers").getDocuments() else { return }
        try await fetchUsers(snapshot)
    }
    //MARK: fetchFollowingUsers
    /// fetches the list users that the user is following
    /// - Parameter uid: fetches all followingfor this user
    private func fetchFollowingUsers(forUid uid: String) async throws {
        guard let snapshot = try? await FirestoreConstants.FollowingCollection.document(uid).collection("user-following").getDocuments() else { return }
        try await fetchUsers(snapshot)
    }
    //MARK: fetchUsers
    /// fetches the user objects that are fetched from the list
    private func fetchUsers(_ snapshot: QuerySnapshot?) async throws {
        guard let documents = snapshot?.documents else { return }
        for doc in documents {
            let user = try await UserService.shared.fetchUser(withUid: doc.documentID)
            users.append(user)
        }
    }
    
    //MARK: filteredUsers
    /// filters users by username
    /// - Parameter query: <#query description#>
    /// - Returns: <#description#>
    func filteredUsers(_ query: String) -> [User] {
        let lowercasedQuery = query.lowercased()
        return users.filter({
            $0.fullname.lowercased().contains(lowercasedQuery) ||
            $0.username.lowercased().contains(lowercasedQuery)
        })
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
    

//
//  ProfileVIewModel.swift
//  Foodi
//
//  Created by Jack Robinson on 2/1/24.
//

import AVFoundation
import SwiftUI

@MainActor
class ProfileViewModel: ObservableObject {
    @Published var posts = [Post]()
    @Published var user = User(id: "", username: "", fullname: "", privateMode: false)
    private let uid: String
    private let postService: PostService
    private var didCompleteFollowCheck = false
    private var didCompleteStatsFetch = false
    
    init(uid: String, postService: PostService) {
        self.uid = uid
        self.postService = postService
    }
    
    func fetchUser() async {
        do {
            self.user = try await UserService.shared.fetchUser(withUid: uid)
            try await fetchUserPosts()
        } catch {
            print("DEBUG: Failed to fetch user \(uid) with error: \(error.localizedDescription)")
        }
    }
    func fetchCurrentUser() async {
        do{
            if let currentUser = AuthService.shared.userSession {
                self.user = currentUser
            }
            try await fetchUserPosts()
        }
        catch {
            print("DEBUG: Failed to fetch currentuser with error: \(error.localizedDescription)")
        }
    }
}

// MARK: - Following

extension ProfileViewModel {
    func follow() {
            Task {
                try await UserService.shared.follow(uid: user.id)
                user.isFollowed = true
                user.stats.followers += 1
            }
    }
    func unfollow() {
            Task {
                try await UserService.shared.unfollow(uid: user.id)
                user.isFollowed = false
                user.stats.followers -= 1
            }
        }
    
    func checkIfUserIsFollowed() async {
            guard !user.isCurrentUser, !didCompleteFollowCheck else { return }
            user.isFollowed = await UserService.shared.checkIfUserIsFollowed(uid: user.id)
            self.didCompleteFollowCheck = true
        }
    
}

// MARK: - Posts

extension ProfileViewModel {
    func fetchUserPosts() async throws {
        
            do {
                self.posts = try await postService.fetchUserPosts(user: user)
            } catch {
                print("DEBUG: Failed to fetch posts with error: \(error.localizedDescription)")
            }
        }
    
    
    func fetchUserLikedPosts() async throws {
            do {
                self.posts = try await postService.fetchUserLikedPosts(user: user)
            } catch {
                print("DEBUG: Failed to fetch posts with error: \(error.localizedDescription)")
            }
        
    }
}


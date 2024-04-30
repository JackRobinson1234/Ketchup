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
    @Published var user = User(id: "", username: "", email: "", fullname: "")
    private let uid: String
    private let userService: UserService
    private let postService: PostService
    private var didCompleteFollowCheck = false
    private var didCompleteStatsFetch = false
    
    init(uid: String, userService: UserService, postService: PostService) {
        self.uid = uid
        self.userService = userService
        self.postService = postService
    }
    
    func fetchUser() async {
        do {
            self.user = try await userService.fetchUser(withUid: uid)
            await fetchUserPosts()
        } catch {
            print("DEBUG: Failed to fetch user \(uid) with error: \(error.localizedDescription)")
        }
    }
    func fetchCurrentUser() async {
        do{
            self.user = try await userService.fetchCurrentUser()
            await fetchUserPosts()
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
                try await userService.follow(uid: user.id)
                user.isFollowed = true
                user.stats.followers += 1
                NotificationManager.shared.uploadFollowNotification(toUid: user.id)
            }
    }
    func unfollow() {
            Task {
                try await userService.unfollow(uid: user.id)
                user.isFollowed = false
                user.stats.followers -= 1
            }
        }
    
    func checkIfUserIsFollowed() async {
            guard !user.isCurrentUser, !didCompleteFollowCheck else { return }
            user.isFollowed = await userService.checkIfUserIsFollowed(uid: user.id)
            self.didCompleteFollowCheck = true
        }
    
}

// MARK: - Stats

/*extension ProfileViewModel {
    func fetchUserStats() async {
            guard !didCompleteStatsFetch else {print("DEBUG: User stats have already been fetched \(user.stats)")
                return
            }
            
            do {
                user.stats = try await userService.fetchUserStats(uid: user.id)
                didCompleteStatsFetch = true
            } catch {
                print("DEBUG: Failed to fetch user stats with error \(error.localizedDescription)")
            }
        }
    
}*/

// MARK: - Posts

extension ProfileViewModel {
    func fetchUserPosts() async {
        
            do {
                self.posts = try await postService.fetchUserPosts(user: user)
            } catch {
                print("DEBUG: Failed to fetch posts with error: \(error.localizedDescription)")
            }
        }
    
    
    func fetchUserLikedPosts() async {
            do {
                self.posts = try await postService.fetchUserLikedPosts(user: user)
            } catch {
                print("DEBUG: Failed to fetch posts with error: \(error.localizedDescription)")
            }
        
    }
}


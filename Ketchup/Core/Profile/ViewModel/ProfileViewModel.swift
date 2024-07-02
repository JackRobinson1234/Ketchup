//
//  ProfileVIewModel.swift
//  Foodi
//
//  Created by Jack Robinson on 2/1/24.
//

import AVFoundation
import SwiftUI
import ClusterMap
import MapKit
@MainActor
class ProfileViewModel: ObservableObject {
    let clusterManager = ClusterManager<RestaurantMapAnnotation>()
    var annotations: [RestaurantMapAnnotation] = []
    var clusters: [ExampleClusterAnnotation] = []
    @Published var posts = [Post]()
    @Published var likedPosts = [Post]()
    @Published var user = User(id: "", username: "", fullname: "", privateMode: false)
    private let uid: String
    private var didCompleteFollowCheck = false
    private var didCompleteStatsFetch = false
    var mapSize: CGSize = .zero
    @Published var currentRegion: MKCoordinateRegion = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 34.0549, longitude: -118.2426), span: MKCoordinateSpan(latitudeDelta: 0.03, longitudeDelta: 0.03))
    init(uid: String) {
        self.uid = uid

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
    func refreshCurrentUser() async throws {
        do {
            self.user = try await UserService.shared.fetchCurrentUser()
            try await fetchUserPosts()
            try await fetchUserLikedPosts()
            AuthService.shared.userSession = self.user
        } catch {
            print("Failed to refresh the current user")
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
            self.posts = try await PostService.shared.fetchUserPosts(user: user)
            //                feedViewModel.posts = posts
        } catch {
            print("DEBUG: Failed to fetch posts with error: \(error.localizedDescription)")
        }
    }
    
    
    func fetchUserLikedPosts() async throws {
        do {
            self.likedPosts = try await PostService.shared.fetchUserLikedPosts(user: user)
            //                feedViewModel.posts = likedPosts
        } catch {
            print("DEBUG: Failed to fetch posts with error: \(error.localizedDescription)")
        }
        
    }
    
    func clearNotificationAlerts() async throws {
        do {
            user.notificationAlert = 0
            AuthService.shared.userSession?.notificationAlert = 0
            try await UserService.shared.clearNotificationAlert()
            
        } catch {
            print("error clearing notification alert")
        }
    }
}

struct PostRestaurantMapAnnotation: CoordinateIdentifiable, Identifiable, Hashable, Equatable {
    let id = UUID()
    var coordinate: CLLocationCoordinate2D
    var restaurant: Restaurant
}

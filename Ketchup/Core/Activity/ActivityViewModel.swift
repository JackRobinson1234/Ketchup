//
//  ActivityViewModel.swift
//  Foodi
//
//  Created by Jack Robinson on 5/2/24.
//

import Foundation
import SwiftUI
import PhotosUI
import FirebaseFirestore
import FirebaseAuth
import Firebase
@MainActor
class ActivityViewModel: ObservableObject {
    @Published var trendingActivity: [Activity] = []
        @Published var friendsActivity: [Activity] = []
        private var pageSize = 30
        @Published var letsKetchupOption: LetsKetchupOptions = .friends
        @Published var isFetching: Bool = false
        @Published var isLoadingMore: Bool = false
        @Published var outOfTrending: Bool = false
        @Published var outOfFriends: Bool = false
        private let loadThreshold = 5
        
        private var lastTrendingDocumentSnapshot: DocumentSnapshot? = nil
        private var lastFriendsDocumentSnapshot: DocumentSnapshot? = nil
        
        var user: User?
        private var service = ActivityService()
    
    
    // Sheet state properties
    @Published var collectionsViewModel =  CollectionsViewModel(user: AuthService.shared.userSession!)
    @Published var showWrittenPost: Bool = false
    @Published var showPost: Bool = false
    @Published var showCollection: Bool = false
    @Published var showUserProfile: Bool = false
    @Published var showRestaurant = false
    @Published var post: Post?
    @Published var writtenPost: Post?
    @Published var collection: Collection?
    @Published var selectedRestaurantId: String? = nil
    @Published var selectedUid: String? = nil

    
    
    func fetchMoreActivities(currentIndex: Int) async {
            switch letsKetchupOption {
            case .trending:
                await fetchMoreTrendingActivities(currentIndex: currentIndex)
            case .friends:
                await fetchMoreFriendsActivities(currentIndex: currentIndex)
            }
        }

        private func fetchMoreTrendingActivities(currentIndex: Int) async {
            await fetchMoreGenericActivities(
                currentIndex: currentIndex,
                activities: trendingActivity,
                outOfContent: outOfTrending,
                fetchFunction: fetchTrendingActivities
            )
        }

        private func fetchMoreFriendsActivities(currentIndex: Int) async {
            await fetchMoreGenericActivities(
                currentIndex: currentIndex,
                activities: friendsActivity,
                outOfContent: outOfFriends,
                fetchFunction: fetchFriendsActivities
            )
        }

        private func fetchMoreGenericActivities(
            currentIndex: Int,
            activities: [Activity],
            outOfContent: Bool,
            fetchFunction: () async throws -> Void
        ) async {
            guard !isFetching && !outOfContent && !isLoadingMore else { return }
            
            let distanceFromEnd = activities.count - currentIndex
            
            if distanceFromEnd <= loadThreshold {
                isLoadingMore = true
                do {
                    try await fetchFunction()
                } catch {
                    print("Error fetching more activities: \(error)")
                }
                isLoadingMore = false
            }
        }

        func fetchTrendingActivities() async throws {
            guard !isFetching, !outOfTrending else { return }
            isFetching = true
            defer { isFetching = false }
            
            let (activities, lastSnapshot) = try await service.fetchKetchupActivities(lastDocumentSnapshot: lastTrendingDocumentSnapshot, pageSize: pageSize)
            
            if activities.isEmpty {
                outOfTrending = true
            } else {
                self.trendingActivity.append(contentsOf: activities)
                lastTrendingDocumentSnapshot = lastSnapshot
            }
        }

        func fetchFriendsActivities() async throws {
            guard !isFetching, !outOfFriends else { return }
            isFetching = true
            defer { isFetching = false }
            
            let (activities, lastSnapshot) = try await service.fetchFollowingActivities(lastDocumentSnapshot: lastFriendsDocumentSnapshot, pageSize: pageSize)
            
            if activities.isEmpty {
                outOfFriends = true
            } else {
                self.friendsActivity.append(contentsOf: activities)
                lastFriendsDocumentSnapshot = lastSnapshot
            }
        }

        func fetchInitialActivities() async throws {
            guard !isFetching else { return }

            // Reset pagination state
            lastTrendingDocumentSnapshot = nil
            lastFriendsDocumentSnapshot = nil
            outOfTrending = false
            outOfFriends = false
            trendingActivity = []
            friendsActivity = []

            // Fetch the initial activities
            switch letsKetchupOption {
            case .trending:
                try await fetchTrendingActivities()
            case .friends:
                try await fetchFriendsActivities()
            }
        }
    }

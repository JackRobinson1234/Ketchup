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
    @Published var followingActivity: [Activity] = []
    private var pageSize = 30
    @Published var isFetching: Bool = false
    @Published var isLoadingMore: Bool = false
    @Published var hasMoreActivities: Bool = true
    private let loadThreshold = 5
    
    private var lastDocumentSnapshot: DocumentSnapshot? = nil
    
    var user: User?
    private var service = ActivityService()
    
    // Sheet state properties
    @Published var collectionsViewModel = CollectionsViewModel()
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
    
    func loadMore() {
        guard !isFetching, hasMoreActivities, !isLoadingMore else { return }
        
        isLoadingMore = true
        Task {
            do {
                try await fetchFollowingActivities()
            } catch {
                print("Error fetching more activities: \(error)")
            }
            isLoadingMore = false
        }
    }
    
    func fetchFollowingActivities() async throws {
        guard !isFetching else { return }
        isFetching = true
        defer { isFetching = false }
        
        let (activities, lastSnapshot) = try await service.fetchFollowingActivities(lastDocumentSnapshot: lastDocumentSnapshot, pageSize: pageSize)
        
        DispatchQueue.main.async {
            if activities.isEmpty {
                self.hasMoreActivities = false
            } else {
                self.followingActivity.append(contentsOf: activities)
                self.lastDocumentSnapshot = lastSnapshot
            }
        }
    }
    
    func fetchInitialActivities() async throws {
        guard !isFetching else { return }
        
        // Reset pagination state
        lastDocumentSnapshot = nil
        hasMoreActivities = true
        followingActivity = []
        
        // Fetch the initial activities
        try await fetchFollowingActivities()
    }
}

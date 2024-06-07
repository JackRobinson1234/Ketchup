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
    private var service = ActivityService()
    @Published var trendingActivity: [Activity] = []
    @Published var friendsActivity: [Activity] = []
    private var friendsCurrentPage = 1
    private var pageSize = 30

    @Published var letsKetchupOption: LetsKetchupOptions = .friends
    @State var outOfTrending = false
    @Published var isFetching: Bool = false
    private let fetchingThreshold: Int = -5
    private var lastFetched: Activity? = nil
    
    private var lastTrendingDocumentSnapshot: DocumentSnapshot? = nil
    var user: User?
    
    func fetchFriendsActivities() async throws {
            self.friendsActivity = try await service.fetchFollowingActivities()
        }

    
    
    func fetchMoreTrendingActivities(distanceFromEnd: Int) async throws{
        guard !isFetching, !outOfTrending else { return }
        let thresholdIndex = trendingActivity.index(trendingActivity.endIndex, offsetBy: fetchingThreshold)
        guard thresholdIndex >= trendingActivity.startIndex && thresholdIndex < trendingActivity.endIndex else {
                    print("Threshold index out of bounds")
                    return
                }
        if trendingActivity[thresholdIndex] != lastFetched, -distanceFromEnd == thresholdIndex {
            print("fetching new activities")
            lastFetched = trendingActivity[thresholdIndex]
            try await fetchTrendingActivities()
        } else if trendingActivity[thresholdIndex] == lastFetched, -distanceFromEnd == thresholdIndex{
            print("already fetched from this position")
        }
    }
    
    func fetchTrendingActivities() async throws {
        guard !isFetching, !outOfTrending else { return }
        isFetching = true
        defer { isFetching = false }
        
        let (activities, lastSnapshot) = try await service.fetchKetchupActivities(lastDocumentSnapshot: lastTrendingDocumentSnapshot, pageSize: pageSize)
        if activities.count < pageSize {
            outOfTrending = true
        }
        self.trendingActivity.append(contentsOf: activities)
        lastTrendingDocumentSnapshot = lastSnapshot
        lastFetched = trendingActivity.last
    }

        func fetchInitialTrendingActivities() async throws {
            guard !isFetching else { return }

            // Reset pagination state
            lastTrendingDocumentSnapshot = nil
            outOfTrending = false
            trendingActivity = []

            // Fetch the initial activities
            try await fetchTrendingActivities()
        }
    }

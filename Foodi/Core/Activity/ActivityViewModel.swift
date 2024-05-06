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
    @Published var letsKetchupOption: LetsKetchupOptions = .friends
    
    var user: User?
    func fetchFriendsActivities() async throws {
        self.friendsActivity = try await service.fetchFollowingActivities()
    }
    
    func fetchTrendingActivities() async throws {
        self.trendingActivity = try await service.fetchKetchupActivities()
    }
    
    func fetchActivitiesIfNeeded() async throws {
        if letsKetchupOption == .friends && friendsActivity.isEmpty {
            try await fetchFriendsActivities()
        } else if letsKetchupOption == .trending && trendingActivity.isEmpty {
            try await fetchTrendingActivities()
        }
    }
}

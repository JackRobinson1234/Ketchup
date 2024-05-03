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
    @Published var activityList: [Activity] = []
    @Published var ketchupActivityList: [Activity] = []
    private var service = ActivityService()
    private var userService = UserService()
    var user: User?
    func fetchActivities() async throws {
        self.activityList = try await service.fetchFollowingActivities()
    }
    
    func fetchKetchupActivities() async throws {
        self.ketchupActivityList = try await service.fetchKetchupActivities()
    }
    func fetchCurrentUser() async throws  {
        self.user = try await UserService().fetchCurrentUser()
    }
}

//
//  NotificationsViewModel.swift
//  Foodi
//
//  Created by Jack Robinson on 2/1/24.
//

import Foundation

@MainActor
class NotificationsViewModel: ObservableObject {
    @Published var notifications = [Notification]()
    @Published var isLoading = false
    @Published var showEmptyView = false
    
    private let service: NotificationService
    
    init(service: NotificationService) {
        self.service = service
        Task { await fetchNotifications() }
    }
    //MARK: fetchNotifications
    /// fetches notifications for the user
    func fetchNotifications() async {
        isLoading = true
        do {
            self.notifications = try await service.fetchNotifications()
            self.showEmptyView = notifications.isEmpty
            isLoading = false
        } catch {
            print("DEBUG: Failed to fetch notifications with error \(error.localizedDescription)")
            isLoading = false
        }
    }
    func follow(userId: String) async throws {
        try await UserService.shared.follow(uid: userId)
    }
    
    func unfollow(userId: String) async throws {
        try await UserService.shared.unfollow(uid: userId)
    }
    
    func checkIfUserIsFollowed(userId: String) async -> Bool {
        return await UserService.shared.checkIfUserIsFollowed(uid: userId)
    }
}

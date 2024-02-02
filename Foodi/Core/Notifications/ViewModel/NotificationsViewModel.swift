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
}

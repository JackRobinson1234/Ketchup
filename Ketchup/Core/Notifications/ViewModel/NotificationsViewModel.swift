//
//  NotificationsViewModel.swift
//  Foodi
//
//  Created by Jack Robinson on 2/1/24.
//

import Foundation
import FirebaseAuth

@MainActor
class NotificationsViewModel: ObservableObject {
    @Published var notifications = [Notification]()
    @Published var isLoading = false
    @Published var showEmptyView = false
    @Published var mostRecentlyUpdatedFollow: String? = nil
    
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
            ////print("DEBUG: Failed to fetch notifications with error \(error.localizedDescription)")
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
    func acceptCollectionInvite(notificationId: String, collectionId: String) async {
        do {
            // Accept the invite using CollectionService
            try await CollectionService.shared.acceptInvite(collectionId: collectionId)
            
            // Update the local notification status
            if let index = notifications.firstIndex(where: { $0.id == notificationId }) {
                notifications[index].inviteStatus = .accepted
            }
            
            // Update the notification in Firestore
            
            
            // Fetch the updated collection and add it to the user's collections
            
        } catch {
            ////print("DEBUG: Failed to accept collection invite with error \(error.localizedDescription)")
        }
    }
    
    func rejectCollectionInvite(notificationId: String, collectionId: String) async {
        do {
            // Reject the invite using CollectionService
            try await CollectionService.shared.rejectInvite(collectionId: collectionId)
            
            // Update the local notification status
            if let index = notifications.firstIndex(where: { $0.id == notificationId }) {
                notifications[index].inviteStatus = .rejected
            }
            
            // Update the notification in Firestore
            
        } catch {
            ////print("DEBUG: Failed to reject collection invite with error \(error.localizedDescription)")
        }
    }
    
    func updateNotificationStatus(notificationId: String, status: InviteStatus) async {
        if let index = notifications.firstIndex(where: { $0.id == notificationId }) {
            notifications[index].inviteStatus = status
        }
    }
    func checkCollectionStatus(collectionId: String) async -> InviteStatus {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            return .rejected // Or maybe a new status like .unknown
        }
        
        do {
            let collection = try await CollectionService.shared.fetchCollection(withId: collectionId)
            
            if collection.collaborators.contains(currentUserId) {
                return .accepted
            } else if collection.pendingInvitations.contains(currentUserId) {
                return .pending
            } else {
                return .rejected // Or maybe a new status like .notInvolved
            }
        } catch {
            ////print("DEBUG: Failed to fetch collection status with error \(error.localizedDescription)")
            return .rejected // Or maybe a new status like .unknown
        }
    }
}

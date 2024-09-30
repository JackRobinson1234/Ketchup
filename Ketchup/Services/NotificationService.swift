//
//  NotificationService.swift
//  Foodi
//
//  Created by Jack Robinson on 2/1/24.
//

import Foundation
import Firebase

class NotificationService {
    
    private var notifications = [Notification]()
    
    func fetchNotifications() async throws -> [Notification] {
        guard let uid = Auth.auth().currentUser?.uid else { return [] }
        
        self.notifications = try await FirestoreConstants.UserNotificationCollection(uid: uid)
            .order(by: "timestamp", descending: true)
            .getDocuments(as: Notification.self)
        
        await withThrowingTaskGroup(of: Void.self) { group in
            for notification in notifications {
                group.addTask { try await self.updateNotification(notification) }
            }
        }
        
        return notifications
    }
    

    private func updateNotification(_ notification: Notification) async throws {
        guard let indexOfNotification = notifications.firstIndex(where: { $0.id == notification.id }) else { return }
        
        async let notificationUser = try UserService.shared.fetchUser(withUid: notification.uid)
        self.notifications[indexOfNotification].user = try await notificationUser

        if notification.type == .follow {
            async let isFollowed = UserService.shared.checkIfUserIsFollowed(uid: notification.uid)
            self.notifications[indexOfNotification].user?.isFollowed = await isFollowed
        }
    }
}

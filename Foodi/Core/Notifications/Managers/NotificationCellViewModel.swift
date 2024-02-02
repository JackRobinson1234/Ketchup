//
//  NotificationCellViewModel.swift
//  Foodi
//
//  Created by Jack Robinson on 2/1/24.
//

import Foundation

@MainActor
class NotificationCellViewModel: ObservableObject {
    @Published var notification: Notification
    
    init(notification: Notification) {
        self.notification = notification
    }
    
    func follow() {
        Task {
            notification.user?.isFollowed = true
        }
    }
    
    func unfollow() {
        Task {
            notification.user?.isFollowed = false
        }
    }
}

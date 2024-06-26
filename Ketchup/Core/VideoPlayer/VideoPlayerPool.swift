//
//  VideoPlayerPool.swift
//  Ketchup
//
//  Created by Jack Robinson on 6/26/24.
//

import Foundation
import SwiftUI


class VideoPlayerCoordinatorPool {
    static let shared = VideoPlayerCoordinatorPool()
    private var coordinators: [VideoPlayerCoordinator] = []
    private let maxPoolSize: Int
    private let lock = NSLock()

    init(maxPoolSize: Int = 5) {  // Adjust pool size based on your app's needs
        self.maxPoolSize = maxPoolSize
    }

    func getCoordinator() -> VideoPlayerCoordinator {
        lock.lock()
        defer { lock.unlock() }

        if let coordinator = coordinators.first(where: { !$0.isInUse }) {
            coordinator.isInUse = true
            return coordinator
        } else {
            let newCoordinator = VideoPlayerCoordinator()
            newCoordinator.isInUse = true
            return newCoordinator
        }
    }

    func returnCoordinator(_ coordinator: VideoPlayerCoordinator) {
        lock.lock()
        defer { lock.unlock() }

        if coordinators.count < maxPoolSize {
            coordinator.resetPlayer()
            coordinator.isInUse = false
            coordinators.append(coordinator)
        } else {
            // Optionally handle the situation where the pool is full (e.g., release the coordinator)
        }
    }
}

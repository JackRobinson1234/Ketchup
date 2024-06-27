//
//  VideoPlayerPool.swift
//  Ketchup
//
//  Created by Jack Robinson on 6/26/24.
//

import Foundation
import SwiftUI


class VideoPlayerCoordinatorPool: ObservableObject {
    static let shared = VideoPlayerCoordinatorPool()
    @Published private var coordinators: [String: VideoPlayerCoordinator] = [:]
    private let maxPoolSize: Int
    private let lock = NSLock()

    private init(maxPoolSize: Int = 5) {
        self.maxPoolSize = maxPoolSize
    }

    func coordinator(for postId: String) -> VideoPlayerCoordinator {
        lock.lock()
        defer { lock.unlock() }

        if let coordinator = coordinators[postId] {
            return coordinator
        } else {
            let newCoordinator = VideoPlayerCoordinator()
            if coordinators.count >= maxPoolSize {
                removeOldestCoordinator()
            }
            coordinators[postId] = newCoordinator
            return newCoordinator
        }
    }

    func releaseCoordinator(for postId: String) {
        lock.lock()
        defer { lock.unlock() }

        if let coordinator = coordinators[postId] {
            coordinator.resetPlayer()
            coordinators.removeValue(forKey: postId)
        }
    }
    
    func resetPool() {
            lock.lock()
            defer { lock.unlock() }

            for (_, coordinator) in coordinators {
                coordinator.resetPlayer()
            }
            coordinators.removeAll()
        }
    
    private func removeOldestCoordinator() {
        if let oldestKey = coordinators.keys.first {
            if let oldestCoordinator = coordinators[oldestKey] {
                oldestCoordinator.resetPlayer()
                coordinators.removeValue(forKey: oldestKey)
            }
        }
    }
    
}

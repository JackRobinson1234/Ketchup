//
//  ActivityService.swift
//  Foodi
//
//  Created by Jack Robinson on 5/2/24.
//

import Foundation
import Foundation
import Firebase

class ActivityService {
    private let postService = PostService()
    
    func fetchFollowingActivities() async throws -> [Activity] {
        var allActivities = [Activity]()
        
        let users = try await UserService.shared.fetchFollowingUsers()
        var userIDs = users.map { $0.id } // Assuming User model has an `id` property
        
        while !userIDs.isEmpty {
            let batchSize = min(30, userIDs.count)
            let batchUserIDs = Array(userIDs.prefix(batchSize))
            userIDs.removeFirst(batchSize)
            
            let activities = try await fetchActivitiesForUsers(userIDs: batchUserIDs)
            allActivities.append(contentsOf: activities)
        }
        
        return allActivities
    }
    
    
    
    private func fetchActivitiesForUsers(userIDs: [String]) async throws -> [Activity] {
        var activities = [Activity]()
        // Query activities for the specified user ID, sorted by timestamp in descending order
        let query = FirestoreConstants.ActivityCollection
            .whereField("uid", in: userIDs)
            .order(by: "timestamp", descending: true)
        
        do {
            let querySnapshot = try await query.getDocuments()
            for document in querySnapshot.documents {
                // Parse and process each activity document
                if let activity = try? document.data(as: Activity.self) {
                    activities.append(activity)
                    print("Fetched activity: \(activity)")
                }
            }
            return activities
        } catch {
            throw error
        }
    }
    func fetchKetchupActivities() async throws -> [Activity] {
        let query = FirestoreConstants.ActivityCollection
            .document("yO2MWjMCZ1MsBsuVE9h8M5BTlpj2").collection("activities")
            .order(by: "timestamp", descending: true)
            .limit(to: 20)
        do {
            let activities = try await query.getDocuments(as: Activity.self)
            print(activities)
            return activities
        } catch {
            throw error
        }
    }
}



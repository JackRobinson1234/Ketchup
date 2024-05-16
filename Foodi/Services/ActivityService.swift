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
    private var fetchedUsers = false
    private var userIDs: [String] = []
    
    func fetchUserIDs() async throws {
            let users = try await UserService.shared.fetchFollowingUsers()
            userIDs = users.map { $0.id }
        }
    
    func fetchFollowingActivities(page: Int) async throws -> [Activity] {
        if !fetchedUsers{
            try await fetchUserIDs()
            fetchedUsers = true
        }
        guard !userIDs.isEmpty else {
            return []
        }
            let startIndex = page * 6
        guard startIndex < userIDs.count else { 
            return []
        }
            var activities = [Activity]()
            while userIDs.count > 0 {
                let endIndex = min(30, userIDs.count)
                let batchUserIDs = Array(userIDs[startIndex..<endIndex])

                let batchActivities = try await fetchActivitiesForUsers(userIds: batchUserIDs)
                activities.append(contentsOf: batchActivities)

                userIDs.removeFirst(batchUserIDs.count)
            }

            return activities
        }
    
    
    private func fetchActivitiesForUsers(userIds: [String]) async throws -> [Activity] {
        var activities = [Activity]()
        // Query activities for the specified user ID, sorted by timestamp in descending order
        let query = FirestoreConstants.ActivityCollection
        for uid in userIds{
            var userActivities = try await query.whereField("uid", isEqualTo: uid).order(by: "timestamp", descending: true).getDocuments(as: Activity.self)
            activities.append(contentsOf: userActivities)
        }
        return activities
    }
    
    
    func fetchKetchupActivities(lastDocumentSnapshot: DocumentSnapshot? = nil, pageSize: Int) async throws -> ([Activity], DocumentSnapshot?) {
            var query = FirestoreConstants.ActivityCollection
                .whereField("uid", isEqualTo: "yO2MWjMCZ1MsBsuVE9h8M5BTlpj2")
                .order(by: "timestamp", descending: true)
                .limit(to: pageSize)
            if let lastSnapshot = lastDocumentSnapshot {
                    query = query.start(afterDocument: lastSnapshot)
                }
            let snapshot = try await query.getDocuments()
           
           // Convert the documents to Activity objects
           let activities = try snapshot.documents.compactMap { try $0.data(as: Activity.self) }
           
           // Get the last document snapshot from this batch
           let lastDocument = snapshot.documents.last
           
           print("kechup activities fetched")
           
           return (activities, lastDocument)
        }
}



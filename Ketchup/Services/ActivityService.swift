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
    
    func fetchFollowingActivities(lastDocumentSnapshot: DocumentSnapshot? = nil, pageSize: Int) async throws -> ([Activity], DocumentSnapshot?) {
        if !fetchedUsers {
            try await fetchUserIDs()
            fetchedUsers = true
        }

        var query = FirestoreConstants.ActivityCollection
            .whereField("uid", in: Array(userIDs.prefix(30))) // Adjust the limit based on Firestore's constraints
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

        // Sort the activities by timestamp if needed

        return (activities, lastDocument)
    }
    
    
    private func fetchActivitiesForUsers(userIds: [String]) async throws -> [Activity] {
           var activities = [Activity]()
           // Query activities for the specified user ID, sorted by timestamp in descending order
           let query = FirestoreConstants.ActivityCollection
           for uid in userIds{
               let userActivities = try await query.whereField("uid", isEqualTo: uid).getDocuments(as: Activity.self)
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


extension Timestamp: Comparable {
    public static func < (lhs: Timestamp, rhs: Timestamp) -> Bool {
        return lhs.seconds < rhs.seconds || (lhs.seconds == rhs.seconds && lhs.nanoseconds < rhs.nanoseconds)
    }
}

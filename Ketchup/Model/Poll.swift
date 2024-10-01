//
//  Poll.swift
//  Ketchup
//
//  Created by Jack Robinson on 9/11/24.
//

import Foundation
struct Poll: Identifiable, Codable {
    var id: String
    let question: String
    var options: [PollOption]
    let createdAt: Date
    let scheduledDate: Date
    let expiresAt: Date // Now a stored property
    var totalVotes: Int
    var commentCount: Int
    var imageUrl: String?
    
    // Computed property to check if the poll is active
    var isActive: Bool {
        let now = Date()
        return now >= scheduledDate && now < expiresAt
    }
}
struct PollOption: Identifiable, Codable {
    let id: String
    let text: String
    var voteCount: Int
    var restaurant: PostRestaurant?
}
extension Poll {
    static func createNewPoll(question: String, options: [String], imageUrl: String? = nil, scheduledDate: Date) -> Poll {
        let now = Date()
        let expiresAt = Calendar.current.date(byAdding: .day, value: 1, to: scheduledDate)!
        
        return Poll(
            id: UUID().uuidString,
            question: question,
            options: options.map { PollOption(id: UUID().uuidString, text: $0, voteCount: 0) },
            createdAt: now,
            scheduledDate: scheduledDate,
            expiresAt: expiresAt,
            totalVotes: 0,
            commentCount: 0,
            imageUrl: imageUrl
        )
    }
}

struct PollVote: Identifiable, Codable {
    var id: String
    let pollId: String
    let user: PostUser
    var optionId: String
    let timestamp: Date
}
extension Poll: Commentable {
    var ownerUid: String? {
        return nil // Assuming polls don't have an owner UID
    }
    
    var commentsCollectionPath: String {
        return "polls/\(id)/comments"
    }
}
extension Poll: Equatable {
    static func == (lhs: Poll, rhs: Poll) -> Bool {
        return lhs.id == rhs.id
    }
}

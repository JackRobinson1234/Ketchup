//
//  Poll.swift
//  Ketchup
//
//  Created by Jack Robinson on 9/11/24.
//

import Foundation
struct Poll: Identifiable, Codable {
    var id: String?
    let question: String
    var options: [PollOption]
    let createdAt: Date
    let expiresAt: Date
    var totalVotes: Int
    var commentCount: Int
    var imageUrl: String?
    
}
struct PollOption: Identifiable, Codable {
    let id: String
    let text: String
    var voteCount: Int
    var restaurant: PostRestaurant?
}
extension Poll {
    static func createNewPoll(question: String, options: [String], imageUrl: String? = nil) -> Poll {
        let now = Date()
        return Poll(
            question: question,
            options: options.map { PollOption(id: UUID().uuidString, text: $0, voteCount: 0) },
            createdAt: now,
            expiresAt: Calendar.current.date(byAdding: .hour, value: 48, to: now)!,
            totalVotes: 0,
            commentCount: 0,
            imageUrl: imageUrl
        )
    }
    
    var isActive: Bool {
        Date() < expiresAt
    }
    
    mutating func vote(for optionId: String) {
        if let index = options.firstIndex(where: { $0.id == optionId }) {
            options[index].voteCount += 1
            totalVotes += 1
        }
    }
    
    mutating func addComment() {
        commentCount += 1
    }
}

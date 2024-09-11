//
//  PollViewModel.swift
//  Ketchup
//
//  Created by Jack Robinson on 9/11/24.
//

import Foundation
import FirebaseFirestoreInternal
@MainActor
class PollViewModel: ObservableObject {
    @Published var poll: Poll
    
    init(poll: Poll) {
        self.poll = poll
    }
    
    func voteForOption(_ optionId: String) async {
        guard poll.isActive else { return }
        
        // Update local state
        poll.vote(for: optionId)
        
        // Update in Firestore
        do {
            try await updatePollInFirestore()
        } catch {
            print("Error updating poll in Firestore: \(error.localizedDescription)")
            // You might want to revert the local state change here
        }
    }
    
    private func updatePollInFirestore() async throws {
        guard let pollId = poll.id else { return }
        
        let db = Firestore.firestore()
        let pollRef = db.collection("polls").document(pollId)
        
        try await pollRef.updateData([
            "options": poll.options.map { ["id": $0.id, "text": $0.text, "voteCount": $0.voteCount] },
            "totalVotes": poll.totalVotes
        ])
    }
    
    // Implement other methods as needed, such as fetching updated poll data, etc.
}

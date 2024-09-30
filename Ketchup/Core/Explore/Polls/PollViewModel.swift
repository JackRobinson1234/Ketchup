//
//  PollViewModel.swift
//  Ketchup
//
//  Created by Jack Robinson on 9/11/24.
//

import Foundation
import FirebaseFirestoreInternal
import FirebaseStorage
import Firebase
@MainActor
class PollViewModel: ObservableObject {
    @Published var polls: [Poll] = []
    @Published var hasUserVotedPolls: [String: (hasVoted: Bool, optionId: String?)] = [:]
    
    private var lastDocumentSnapshot: DocumentSnapshot?
    private var isFetching = false
        private let pageSize = 5
        private var hasMorePolls = true

    init() {
        // Fetch initial set of polls
        fetchPreviousPolls()
    }

    func fetchPreviousPolls() {
            guard !isFetching && hasMorePolls else { return }
            isFetching = true
            
            let db = Firestore.firestore()
            let pollsRef = db.collection("polls")
            
            // Get the start of today in PST
            var calendar = Calendar(identifier: .gregorian)
            calendar.timeZone = TimeZone(abbreviation: "PST")!
            let startOfToday = calendar.startOfDay(for: Date())

            var query: Query = pollsRef
                .whereField("scheduledDate", isLessThanOrEqualTo: startOfToday)
                .order(by: "scheduledDate", descending: true)
                .limit(to: pageSize)
            
            if let lastSnapshot = lastDocumentSnapshot {
                query = query.start(afterDocument: lastSnapshot)
            }

            query.getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching previous polls: \(error.localizedDescription)")
                    self.isFetching = false
                    return
                }

                guard let snapshot = snapshot, !snapshot.documents.isEmpty else {
                    self.hasMorePolls = false
                    self.isFetching = false
                    return
                }

                var fetchedPolls: [Poll] = []
                for document in snapshot.documents {
                    do {
                        var poll = try document.data(as: Poll.self)
                        poll.id = document.documentID
                        if !self.polls.contains(where: { $0.id == poll.id }) {
                            fetchedPolls.append(poll)
                        }
                    } catch {
                        print("Error decoding poll: \(error.localizedDescription)")
                    }
                }
                
                DispatchQueue.main.async {
                    self.polls.append(contentsOf: fetchedPolls)
                    self.lastDocumentSnapshot = snapshot.documents.last
                    self.isFetching = false
                    
                    // Check if user has voted for these polls
                    for poll in fetchedPolls {
                        self.checkIfUserHasVoted(for: poll)
                    }
                    
                    // Update hasMorePolls flag
                    self.hasMorePolls = !fetchedPolls.isEmpty
                }
            }
        }
    
    
    func checkIfUserHasVoted(for poll: Poll) {
        guard let userId = AuthService.shared.userSession?.id else {
            return
        }
        
        let db = Firestore.firestore()
        let votesRef = db.collection("polls").document(poll.id).collection("votes").document(userId)
        
        votesRef.getDocument { snapshot, error in
            if let error = error {
                print("Error checking vote: \(error.localizedDescription)")
                return
            }
            
            if let snapshot = snapshot, snapshot.exists {
                do {
                    let vote = try snapshot.data(as: PollVote.self)
                    DispatchQueue.main.async {
                        self.hasUserVotedPolls[poll.id] = (true, vote.optionId)
                    }
                } catch {
                    print("Error decoding user vote: \(error.localizedDescription)")
                }
            } else {
                DispatchQueue.main.async {
                    self.hasUserVotedPolls[poll.id] = (false, nil)
                }
            }
        }
    }
    
    func voteForOption(_ optionId: String, in poll: Poll) async {
        guard poll.isActive else { return }
        guard let user = AuthService.shared.userSession else { return }
        let userId = user.id

        let db = Firestore.firestore()
        let pollRef = db.collection("polls").document(poll.id)
        let votesRef = pollRef.collection("votes").document(userId)

        do {
            // Fetch the user's existing vote
            let snapshot = try await votesRef.getDocument()
            var previousOptionId: String? = nil

            if snapshot.exists {
                let existingVote = try snapshot.data(as: PollVote.self)
                previousOptionId = existingVote.optionId
            }

            // If the user is voting for the same option, do nothing
            if previousOptionId == optionId {
                return
            }

            // Create or update the PollVote object
            let pollVote = PollVote(
                id: user.id,
                user: PostUser(
                    id: user.id,
                    fullname: user.fullname,
                    profileImageUrl: user.profileImageUrl,
                    privateMode: user.privateMode,
                    username: user.username
                ),
                optionId: optionId,
                timestamp: Date()
            )

            // Start a batch to perform multiple writes atomically
            let batch = db.batch()

            // Update the user's vote in the votes subcollection
            try batch.setData(from: pollVote, forDocument: votesRef)

            // Update vote counts
            var updatedOptions = poll.options

            // Decrement vote count for the previous option if it exists
            if let prevOptionId = previousOptionId,
               let prevIndex = updatedOptions.firstIndex(where: { $0.id == prevOptionId }) {
                updatedOptions[prevIndex].voteCount -= 1
            }

            // Increment vote count for the new option
            if let newIndex = updatedOptions.firstIndex(where: { $0.id == optionId }) {
                updatedOptions[newIndex].voteCount += 1
            }

            // Update total votes only if it's a new vote
            var totalVotes = poll.totalVotes
            if previousOptionId == nil {
                totalVotes += 1
            }

            // Update the poll document
            let updatedData: [String: Any] = [
                "options": updatedOptions.map { option in
                    [
                        "id": option.id,
                        "text": option.text,
                        "voteCount": option.voteCount
                    ]
                },
                "totalVotes": totalVotes
            ]
            batch.updateData(updatedData, forDocument: pollRef)

            // Commit the batch
            try await batch.commit()

            // Update local state
            DispatchQueue.main.async {
                if let index = self.polls.firstIndex(where: { $0.id == poll.id }) {
                    self.polls[index].options = updatedOptions
                    self.polls[index].totalVotes = totalVotes
                }
                self.hasUserVotedPolls[poll.id] = (true, optionId)
            }

        } catch {
            print("Error updating poll in Firestore: \(error.localizedDescription)")
        }
    }
}

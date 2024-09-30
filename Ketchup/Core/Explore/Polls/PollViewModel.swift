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
class PollViewModel: ObservableObject, CommentableViewModel {
    @Published var poll: Poll?
    @Published var hasUserVoted = false
    @Published var userVotedOptionId: String?
    @Published var userVote: PollVote?
    @Published var selectedCommentId: String?

    init(poll: Poll? = nil) {
        if let poll = poll {
            self.poll = poll
            self.checkIfUserHasVoted()
        } else {
            fetchPollForToday()
        }
    }

    func fetchPollForToday() {
        let db = Firestore.firestore()
        let pollsRef = db.collection("polls")

        // Get the start and end of the current day in PST
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(abbreviation: "PST")!
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        pollsRef
            .whereField("scheduledDate", isGreaterThanOrEqualTo: startOfDay)
            .whereField("scheduledDate", isLessThan: endOfDay)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching poll: \(error.localizedDescription)")
                    return
                }

                if let document = snapshot?.documents.first {
                    do {
                        var poll = try document.data(as: Poll.self)
                        poll.id = document.documentID
                        DispatchQueue.main.async {
                            self.poll = poll
                            self.checkIfUserHasVoted()
                        }
                    } catch {
                        print("Error decoding poll: \(error.localizedDescription)")
                    }
                } else {
                    print("No poll scheduled for today")
                }
            }
    }

    func checkIfUserHasVoted() {
        guard let poll = poll else { return }
        guard let userId = AuthService.shared.userSession?.id else { return }

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
                        self.hasUserVoted = true
                        self.userVotedOptionId = vote.optionId
                        self.userVote = vote
                    }
                } catch {
                    print("Error decoding user vote: \(error.localizedDescription)")
                }
            }
        }
    }

    func voteForOption(_ optionId: String) async {
        guard let poll = poll, poll.isActive else { return }
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
                self.poll?.options = updatedOptions
                self.poll?.totalVotes = totalVotes
                self.hasUserVoted = true
                self.userVotedOptionId = optionId
                self.userVote = pollVote
            }

        } catch {
            print("Error updating poll in Firestore: \(error.localizedDescription)")
        }
    }
}

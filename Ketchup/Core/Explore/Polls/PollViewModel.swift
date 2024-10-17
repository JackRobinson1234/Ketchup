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
    @Published var friendVotes: [String: [String: [PostUser]]] = [:]
    private var lastDocumentSnapshot: DocumentSnapshot?
    private var isFetching = false
        private let pageSize = 5
        private var hasMorePolls = true

    

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
                    //print("Error fetching previous polls: \(error.localizedDescription)")
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
                        //print("Error decoding poll: \(error.localizedDescription)")
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
                //print("Error checking vote: \(error.localizedDescription)")
                return
            }
            
            if let snapshot = snapshot, snapshot.exists {
                do {
                    let vote = try snapshot.data(as: PollVote.self)
                    DispatchQueue.main.async {
                        self.hasUserVotedPolls[poll.id] = (true, vote.optionId)
                    }
                    self.fetchFriendsVotes(for: poll)
                } catch {
                    //print("Error decoding user vote: \(error.localizedDescription)")
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
                pollId: poll.id,
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
                Task{
                    
                    AuthService.shared.userSession?.pollStreak += 1
                    AuthService.shared.userSession?.lastVotedPoll = Date()
                    
                }
            }

            // Update the poll document
//            let updatedData: [String: Any] = [
//                "options": updatedOptions.map { option in
//                    [
//                        "id": option.id,
//                        "text": option.text,
//                        "voteCount": option.voteCount
//                    ]
//                }
//            ]
//            batch.updateData(updatedData, forDocument: pollRef)

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
            //print("Error updating poll in Firestore: \(error.localizedDescription)")
        }
    }
    func fetchPoll(withId pollId: String) async throws -> Poll? {
        let db = Firestore.firestore()
        let pollRef = db.collection("polls").document(pollId)
        let poll = try await pollRef.getDocument(as: Poll.self)
        
        // Update local polls array if needed
      
        return poll
    }
    func fetchFriendsVotes(for poll: Poll) {
        guard let currentUser = AuthService.shared.userSession else {
            //print("No user session found. Exiting fetchFriendsVotes.")
            return
        }
        
        let db = Firestore.firestore()
        let friendsVotesRef = db.collection("users").document(currentUser.id).collection("friend-votes")
        
        //print("Fetching friends' votes for poll with ID: \(poll.id)")
        
        // Fetch friends' votes for the specific poll
        friendsVotesRef
            .whereField("pollId", isEqualTo: poll.id)
            .getDocuments { snapshot, error in
                if let error = error {
                    //print("Error fetching friends' votes: \(error.localizedDescription)")
                    return
                }
                
                //print("Successfully fetched documents. Processing votes...")
                
                var votesByOption: [String: [PostUser]] = [:]
                
                if let documents = snapshot?.documents {
                    //print("Found \(documents.count) friend votes for poll.")
                    
                    for doc in documents {
                        //print("Processing document with ID: \(doc.documentID)")
                        
                        if let vote = try? doc.data(as: PollVote.self) {
                            //print("Parsed vote for option ID: \(vote.optionId) by user: \(vote.user.id)")
                            
                            // Append the friend to the corresponding option
                            if votesByOption[vote.optionId] != nil {
                                votesByOption[vote.optionId]?.append(vote.user)
                                //print("Added user to existing option: \(vote.optionId)")
                            } else {
                                votesByOption[vote.optionId] = [vote.user]
                                //print("Created new option entry for option ID: \(vote.optionId)")
                            }
                        } else {
                            //print("Error parsing document with ID: \(doc.documentID)")
                        }
                    }
                } else {
                    //print("No documents found for friends' votes.")
                }
                
                DispatchQueue.main.async {
                    //print("Updating friendVotes dictionary for poll ID: \(poll.id)")
                    self.friendVotes[poll.id] = votesByOption
                }
            }
    }
    func fetchPolls() {
            // Reset all polling-related state
            polls = []
            hasUserVotedPolls = [:]
            friendVotes = [:]
            lastDocumentSnapshot = nil
            isFetching = false
            hasMorePolls = true

            // Fetch initial set of polls
            fetchPreviousPolls()
        }
}

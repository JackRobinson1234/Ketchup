//
//  PollUploadViewModel.swift
//  Ketchup
//
//  Created by Jack Robinson on 9/28/24.
//

import SwiftUI
import FirebaseFirestoreInternal
import FirebaseStorage
class PollUploadViewModel: ObservableObject {
    @Published var question: String = ""
    @Published var options: [String] = ["", ""]
    @Published var selectedImage: UIImage?
    @Published var isUploading = false
    @Published var showAlert = false
    @Published var alertMessage = ""
    @Published var scheduledPolls: [Poll] = []
    @Published var selectedDate: Date? = Date()
    @Published var consecutiveScheduledPolls: Int = 0 // New property

    init() {
        fetchScheduledPolls()
    }
    
    func fetchScheduledPolls() {
        let db = Firestore.firestore()
        let pollsRef = db.collection("polls")
        let now = Date()
        let oneDayAgo = Calendar.current.date(byAdding: .day, value: -1, to: now)!

        pollsRef
            .whereField("scheduledDate", isGreaterThanOrEqualTo: oneDayAgo)
            .getDocuments { snapshot, error in
                if let error = error {
                    //print("Error fetching scheduled polls: \(error)")
                    return
                }

                if let documents = snapshot?.documents {
                    DispatchQueue.main.async {
                        self.scheduledPolls = documents.compactMap { doc in
                            try? doc.data(as: Poll.self)
                        }
                        self.calculateConsecutiveScheduledPolls()
                    }
                }
            }
    }

    func calculateConsecutiveScheduledPolls() {
        var count = 0
        var date = startOfDayPST(for: Date())
        while true {
            if scheduledPolls.contains(where: { startOfDayPST(for: $0.scheduledDate) == date }) {
                count += 1
                date = Calendar.current.date(byAdding: .day, value: 1, to: date)!
            } else {
                break
            }
        }
        self.consecutiveScheduledPolls = count
    }
    func deletePoll(_ poll: Poll) {
            // TODO: Implement authorization checks here (e.g., check if the current user is the creator)
            // Delete the poll from Firestore
           
            let db = Firestore.firestore()
        db.collection("polls").document(poll.id).delete { error in
                if let error = error {
                    //print("Error deleting poll: \(error.localizedDescription)")
                    DispatchQueue.main.async {
                        self.alertMessage = "Failed to delete poll: \(error.localizedDescription)"
                        self.showAlert = true
                    }
                } else {
                    DispatchQueue.main.async {
                        // Remove the poll from the local list
                        self.scheduledPolls.removeAll { $0.id == poll.id }
                        self.calculateConsecutiveScheduledPolls()
                        // Reset selectedDate if necessary
                        if let selectedDate = self.selectedDate,
                           self.startOfDayPST(for: selectedDate) == self.startOfDayPST(for: poll.scheduledDate) {
                            self.selectedDate = nil
                        }
                    }
                }
            }
        }

    func uploadPoll(dismiss: @escaping () -> Void) {
        // Input validation
        guard let selectedDate = selectedDate else {
            alertMessage = "Please select a date."
            showAlert = true
            return
        }
        
        let startOfSelectedDate = startOfDayPST(for: selectedDate)
        
        // Check if a poll is already scheduled for this date
        if scheduledPolls.contains(where: { startOfDayPST(for: $0.scheduledDate) == startOfSelectedDate }) {
            alertMessage = "A poll is already scheduled for this date. Please choose another date."
            showAlert = true
            return
        }
        
        // Input validation for question and options
        guard !question.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            alertMessage = "Please enter a question."
            showAlert = true
            return
        }
        let trimmedOptions = options.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
        guard trimmedOptions.count >= 2 else {
            alertMessage = "Please enter at least two options."
            showAlert = true
            return
        }
        
        isUploading = true
        
        // Upload process
        Task {
            do {
                var imageUrl: String?
                if let selectedImage = selectedImage {
                    imageUrl = try await uploadImage(selectedImage)
                }
                
                let pollOptions = trimmedOptions.map { optionText in
                    PollOption(id: UUID().uuidString, text: optionText, voteCount: 0)
                }
                
                let scheduledDateMidnightPST = getMidnightPST(of: selectedDate)
                let expiresAt = Calendar.current.date(byAdding: .day, value: 1, to: scheduledDateMidnightPST)!
                
                let poll = Poll(
                    id: UUID().uuidString,
                    question: question,
                    options: pollOptions,
                    createdAt: Date(),
                    scheduledDate: scheduledDateMidnightPST,
                    expiresAt: expiresAt,
                    totalVotes: 0,
                    commentCount: 0,
                    imageUrl: imageUrl
                )
                
                try await uploadPollToFirebase(poll)
                
                DispatchQueue.main.async {
                    self.isUploading = false
                    dismiss()
                }
            } catch {
                DispatchQueue.main.async {
                    self.isUploading = false
                    self.alertMessage = error.localizedDescription
                    self.showAlert = true
                }
            }
        }
    }
    
    // Helper methods
    func startOfDayPST(for date: Date) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(abbreviation: "PST")!
        return calendar.startOfDay(for: date)
    }
    
    func getMidnightPST(of date: Date) -> Date {
        return startOfDayPST(for: date)
    }


    // Image Upload Function
    func uploadImage(_ image: UIImage) async throws -> String {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw URLError(.badURL)
        }
        
        let filename = UUID().uuidString
        let storageRef = Storage.storage().reference().child("poll_images/\(filename).jpg")
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        return try await withCheckedThrowingContinuation { continuation in
            storageRef.putData(imageData, metadata: metadata) { metadata, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                storageRef.downloadURL { url, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                        return
                    }
                    
                    if let urlString = url?.absoluteString {
                        continuation.resume(returning: urlString)
                    } else {
                        continuation.resume(throwing: URLError(.badURL))
                    }
                }
            }
        }
    }
    
    // Poll Data Upload Function
    func uploadPollToFirebase(_ poll: Poll) async throws {
        let db = Firestore.firestore()
        var ref: DocumentReference? = nil
        
        var pollData = try Firestore.Encoder().encode(poll)
        
        ref = db.collection("polls").document()
        pollData["id"] = ref?.documentID // Set the document ID
        
        try await ref?.setData(pollData)
    }
}

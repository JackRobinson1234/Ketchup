//
//  SocialViewModel.swift
//  Ketchup
//
//  Created by Jack Robinson on 10/16/24.
//

import SwiftUI
import FirebaseAuth
import GeoFire
import Firebase
import Kingfisher
import FirebaseFirestoreInternal
import Foundation
import Contacts
@MainActor
class SocialPageViewModel: ObservableObject {
    @Published var topContacts: [Contact] = []
    @Published var isContactPermissionGranted: Bool = false
    private var lastContactDocumentSnapshot: DocumentSnapshot? = nil
    @Published var hasMoreContacts: Bool = true
    @Published var isLoadingMore: Bool = false
    let contactsPageSize = 5
    private let userService = UserService.shared

    func checkContactPermission() {
        let authorizationStatus = CNContactStore.authorizationStatus(for: .contacts)
        DispatchQueue.main.async {
            self.isContactPermissionGranted = authorizationStatus == .authorized
        }
    }

    func fetchTopContacts() async throws {
        guard isContactPermissionGranted else { return }
        guard let userId = Auth.auth().currentUser?.uid else { return }

        let db = Firestore.firestore()
        var query = db.collection("users").document(userId).collection("contacts")
            .whereField("hasExistingAccount", isEqualTo: true)
            .order(by: "userCount", descending: true)
            .limit(to: contactsPageSize)

        if let lastSnapshot = lastContactDocumentSnapshot {
            query = query.start(afterDocument: lastSnapshot)
        }

        let snapshot = try await query.getDocuments()

        var newContacts = snapshot.documents.compactMap { document -> Contact? in
            try? document.data(as: Contact.self)
        }

        // Fetch user details for each contact
        for i in 0..<newContacts.count {
            if let user = try await userService.fetchUser(withPhoneNumber: newContacts[i].phoneNumber) {
                newContacts[i].user = user
            }
        }

        DispatchQueue.main.async {
            self.topContacts.append(contentsOf: newContacts)
            self.lastContactDocumentSnapshot = snapshot.documents.last
            self.hasMoreContacts = !snapshot.documents.isEmpty
        }
    }

    func loadMoreContacts() {
        guard !isLoadingMore, hasMoreContacts else { return }

        isLoadingMore = true
        Task {
            do {
                try await fetchTopContacts()
            } catch {
                print("Error fetching more contacts: \(error)")
            }
            isLoadingMore = false
        }
    }

    func checkIfUserIsFollowed(contact: Contact) async throws -> Bool {
        guard let userId = contact.user?.id else { return false }

        // If we've already checked the follow status, return the stored value
        if let isFollowed = contact.isFollowed {
            return isFollowed
        }

        // If we haven't checked yet, fetch the status from the server
        let isFollowed = try await userService.checkIfUserIsFollowed(uid: userId)

        // Update the contact in the topContacts array
        if let index = topContacts.firstIndex(where: { $0.id == contact.id }) {
            DispatchQueue.main.async {
                self.topContacts[index].isFollowed = isFollowed
            }
        }

        return isFollowed
    }

    func updateContactFollowStatus(contact: Contact, isFollowed: Bool) {
        if let index = topContacts.firstIndex(where: { $0.id == contact.id }) {
            DispatchQueue.main.async {
                self.topContacts[index].isFollowed = isFollowed
            }
        }
    }

    func follow(userId: String) async throws {
        try await userService.follow(uid: userId)
        updateFollowStatus(for: userId, isFollowed: true)
    }

    func unfollow(userId: String) async throws {
        try await userService.unfollow(uid: userId)
        updateFollowStatus(for: userId, isFollowed: false)
    }

    private func updateFollowStatus(for userId: String, isFollowed: Bool) {
        if let index = topContacts.firstIndex(where: { $0.user?.id == userId }) {
            DispatchQueue.main.async {
                self.topContacts[index].isFollowed = isFollowed
            }
        }
    }
}

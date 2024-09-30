//
//  ActivityViewModel.swift
//  Foodi
//
//  Created by Jack Robinson on 5/2/24.
//

import Foundation
import SwiftUI
import PhotosUI
import FirebaseFirestore
import FirebaseAuth
import Firebase
import Contacts
@MainActor
class ActivityViewModel: ObservableObject {
    @Published var followingActivity: [Activity] = []
    private var pageSize = 30
    @Published var isFetching: Bool = false
    @Published var isLoadingMore: Bool = false
    @Published var hasMoreActivities: Bool = true
    private let loadThreshold = 5
    private var lastDocumentSnapshot: DocumentSnapshot? = nil
    var user: User?
    private var service = ActivityService()
    @Published var topContacts: [Contact] = []
    // Sheet state properties
    @Published var collectionsViewModel = CollectionsViewModel()
    @Published var showWrittenPost: Bool = false
    @Published var showPost: Bool = false
    @Published var showCollection: Bool = false
    @Published var showUserProfile: Bool = false
    @Published var showRestaurant = false
    @Published var post: Post?
    @Published var writtenPost: Post?
    @Published var collection: Collection?
    @Published var selectedRestaurantId: String? = nil
    @Published var selectedUid: String? = nil
    @Published var isContactPermissionGranted: Bool = false
    private var lastContactDocumentSnapshot: DocumentSnapshot? = nil
    @Published var hasMoreContacts: Bool = true
    @Published var currentPoll: Poll?
    
    
    private var contactsPageSize = 10
    
    let contactsViewModel = ContactsViewModel()
    private let userService = UserService.shared
    func checkContactPermission() {
        let authorizationStatus = CNContactStore.authorizationStatus(for: .contacts)
        DispatchQueue.main.async {
            self.isContactPermissionGranted = authorizationStatus == .authorized
        }
    }
    
    
    func loadMore() {
        guard !isFetching, hasMoreActivities, !isLoadingMore else { return }
        
        isLoadingMore = true
        Task {
            do {
                try await fetchFollowingActivities()
            } catch {
                //print("Error fetching more activities: \(error)")
            }
            isLoadingMore = false
        }
    }
    func loadMoreContacts() {
        guard !isFetching, hasMoreContacts, !isLoadingMore else { return }
        
        isLoadingMore = true
        Task {
            do {
                try await fetchTopContacts()
            } catch {
                //print("Error fetching more contacts: \(error)")
            }
            isLoadingMore = false
        }
    }
    func fetchFollowingActivities() async throws {
        guard !isFetching else { return }
        isFetching = true
        defer { isFetching = false }
        
        let (activities, lastSnapshot) = try await service.fetchFollowingActivities(lastDocumentSnapshot: lastDocumentSnapshot, pageSize: pageSize)
        
        DispatchQueue.main.async {
            if activities.isEmpty {
                self.hasMoreActivities = false
            } else {
                self.followingActivity.append(contentsOf: activities)
                self.lastDocumentSnapshot = lastSnapshot
            }
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
    
    func resetContactsPagination() {
        topContacts = []
        lastContactDocumentSnapshot = nil
        hasMoreContacts = true
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
    func fetchInitialActivities() async throws {
        guard !isFetching else { return }
        
        // Reset pagination state
        lastDocumentSnapshot = nil
        hasMoreActivities = true
        followingActivity = []
        
        // Fetch the initial activities
        try await fetchFollowingActivities()
    }
}

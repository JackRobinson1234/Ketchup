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

    @Published var mealRestaurants: [Restaurant] = []
    private var mealRestaurantsLastSnapshot: DocumentSnapshot?
    @Published var hasMoreMealRestaurants: Bool = true
    private let mealRestaurantsPageSize = 5
    private var currentMealTime: String?
    private var currentLocation: CLLocationCoordinate2D?
    private var contactsPageSize = 5
    @Published var cuisineRestaurants: [String: [Restaurant]] = [:]
    private var cuisineRestaurantsLastSnapshots: [String: DocumentSnapshot?] = [:]
    @Published var hasMoreCuisineRestaurants: [String: Bool] = [:]
    @Published var isFetchingCuisineRestaurants: [String: Bool] = [:]
    private var currentCuisineLocation: CLLocationCoordinate2D?
    let contactsViewModel = ContactsViewModel()
    private let userService = UserService.shared
    
    func checkContactPermission() {
        let authorizationStatus = CNContactStore.authorizationStatus(for: .contacts)
        DispatchQueue.main.async {
            self.isContactPermissionGranted = authorizationStatus == .authorized
        }
    }
    
        private var cuisineRestaurantsLastSnapshot: DocumentSnapshot?
    @Published var cuisinesFetched: Set<String> = []
    @Published var hasFetchedMealRestaurants = false
    @Published var isFetchingMealRestaurants = false
    
    @Published var topRestaurants: [Restaurant] = []
    private var topRestaurantsLastSnapshot: DocumentSnapshot?
    @Published var hasMoreTopRestaurants: Bool = true
    private var isFetchingTopRestaurants = false
    @Published var fetchedRestaurants: [Restaurant] = []
        private var restaurantsLastSnapshot: DocumentSnapshot?
        @Published var hasMoreRestaurants: Bool = true
        private var isFetchingRestaurants: Bool = false

    func fetchMealRestaurants(mealTime: String, location: CLLocationCoordinate2D?, pageSize: Int = 3) async throws {
        guard !isFetchingMealRestaurants else { return }
        guard let location = location else { return }
        isFetchingMealRestaurants = true
        self.currentMealTime = mealTime
        self.currentLocation = location

        // Check if we've already fetched the meal restaurants
        if hasFetchedMealRestaurants {
            isFetchingMealRestaurants = false
            return
        }

        let (restaurants, lastSnapshot) = try await RestaurantService.shared.fetchRestaurantsServingMeal(
            mealTime: mealTime,
            location: location,
            lastDocument: mealRestaurantsLastSnapshot,
            limit: pageSize
        )
        DispatchQueue.main.async {
            self.mealRestaurants.append(contentsOf: restaurants)
            self.mealRestaurantsLastSnapshot = lastSnapshot
            self.hasMoreMealRestaurants = lastSnapshot != nil
            self.hasFetchedMealRestaurants = true
        }
        isFetchingMealRestaurants = false
    }
    func fetchMoreMealRestaurants() async {
        guard let mealTime = currentMealTime, let location = currentLocation else { return }
        do {
            try await fetchMealRestaurants(mealTime: mealTime, location: location, pageSize: mealRestaurantsPageSize)
        } catch {
            print("Error fetching more meal restaurants: \(error)")
        }
    }
   

    func fetchMoreCuisineRestaurants(for cuisine: String, location: CLLocationCoordinate2D) async {
           do {
               try await fetchCuisineRestaurants(cuisine: cuisine, location: location, pageSize: 5)
           } catch {
               print("Error fetching more \(cuisine) restaurants: \(error)")
           }
       }
    func loadMoreContacts() {
        guard !isFetching, hasMoreContacts, !isLoadingMore else { return }
        
        isLoadingMore = true
        Task {
            do {
                try await fetchTopContacts()
            } catch {
                ////print("Error fetching more contacts: \(error)")
            }
            isLoadingMore = false
        }
    }
//    func fetchTopRestaurants(location: CLLocationCoordinate2D, limit: Int = 15) async throws {
//        guard !isFetchingTopRestaurants else { return }
//        isFetchingTopRestaurants = true
//
//        do {
//            let (restaurants, lastSnapshot) = try await RestaurantService.shared.fetchTopRestaurants(
//                location: location,
//                lastDocument: topRestaurantsLastSnapshot,
//                limit: limit
//            )
//            DispatchQueue.main.async {
//                self.topRestaurants.append(contentsOf: restaurants)
//                self.topRestaurantsLastSnapshot = lastSnapshot
//                self.hasMoreTopRestaurants = lastSnapshot != nil
//            }
//        } catch {
//            print("Error fetching top restaurants: \(error)")
//        }
//
//        isFetchingTopRestaurants = false
//    }
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
    func fetchCuisineRestaurants(cuisine: String, location: CLLocationCoordinate2D, pageSize: Int = 5) async throws {
        // Check if a fetch is already in progress for this cuisine
        if isFetchingCuisineRestaurants[cuisine] == true {
            return
        }
        isFetchingCuisineRestaurants[cuisine] = true
        defer {
            isFetchingCuisineRestaurants[cuisine] = false
        }

        // Fetch pageSize + 1 documents
        let limit = pageSize + 1
        let lastSnapshot = self.cuisineRestaurantsLastSnapshots[cuisine]
        do {
            let (restaurants, newLastSnapshot) = try await RestaurantService.shared.fetchRestaurantsForCuisine(
                cuisine: cuisine,
                location: location,
                lastDocument: lastSnapshot ?? nil,
                limit: limit
            )

            DispatchQueue.main.async {
                var fetchedRestaurants = restaurants
                var hasMore = false

                // Check if we fetched more than pageSize documents
                if fetchedRestaurants.count > pageSize {
                    hasMore = true
                    // Remove the extra document before appending to your list
                    fetchedRestaurants.removeLast()
                    self.cuisineRestaurantsLastSnapshots[cuisine] = newLastSnapshot
                } else {
                    // No more documents
                    hasMore = false
                }

                if self.cuisineRestaurants[cuisine] != nil {
                    self.cuisineRestaurants[cuisine]?.append(contentsOf: fetchedRestaurants)
                } else {
                    self.cuisineRestaurants[cuisine] = fetchedRestaurants
                }

                self.hasMoreCuisineRestaurants[cuisine] = hasMore
            }
        } catch {
            print("Error fetching cuisine restaurants for \(cuisine): \(error)")
        }
    }
    func fetchRestaurants(location: CLLocationCoordinate2D, limit: Int = 50) async throws {
           guard !isFetchingRestaurants else { return }
         
           isFetchingRestaurants = true

           do {
               let (restaurants, lastSnapshot) = try await RestaurantService.shared.fetchTopRestaurants(
                   location: location,
                   lastDocument: restaurantsLastSnapshot,
                   limit: limit
               )
               DispatchQueue.main.async {
                   self.fetchedRestaurants.append(contentsOf: restaurants)
                   self.restaurantsLastSnapshot = lastSnapshot
                   self.hasMoreRestaurants = lastSnapshot != nil
               }
               print(restaurants, fetchedRestaurants)
           } catch {
               print("Error fetching restaurants: \(error)")
           }

           isFetchingRestaurants = false
       }
}

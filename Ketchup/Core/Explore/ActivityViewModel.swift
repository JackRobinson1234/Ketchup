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
import GeoFire
import GeohashKit
@MainActor
class ActivityViewModel: ObservableObject {
    // MARK: - Published Properties (used in the UI)
    @Published var followingActivity: [Activity] = []
    @Published var topContacts: [Contact] = []
    @Published var mealRestaurants: [Restaurant] = []
    @Published var cuisineRestaurants: [String: [Restaurant]] = [:]
    @Published var trendingPosts: [Post] = []
    @Published var globalTrendingPosts: [Post] = []
    @Published var globalTrendingPostsFullList: [Post] = []
    @Published var friendPostsRestaurants: [Restaurant] = []
    @Published var fetchedRestaurants: [Restaurant] = []
    @Published var topRestaurants: [Restaurant] = []

    // UI State Properties
    @Published var isFetching: Bool = false
    @Published var isLoadingMore: Bool = false
    @Published var isContactPermissionGranted: Bool = false
    @Published var hasMoreContacts: Bool = true
    @Published var hasMoreMealRestaurants: Bool = true
    @Published var hasMoreRestaurants: Bool = true
    @Published var hasMoreFriendPosts: Bool = true
    @Published var hasMoreTrendingPosts: Bool = true
    @Published var hasMoreGlobalTrendingPosts: Bool = true

    @Published var isLoadingMoreTrendingPosts = false
    @Published var isLoadingGlobalTrendingPosts = false
    @Published var isLoadingMoreGlobalTrendingPosts = false
    @Published var showWrittenPost: Bool = false
    @Published var showPost: Bool = false
    @Published var showCollection: Bool = false
    @Published var showUserProfile: Bool = false
    @Published var showRestaurant = false

    // Selected Items
    @Published var post: Post?
    @Published var writtenPost: Post?
    @Published var collection: Collection?
    @Published var selectedRestaurantId: String? = nil
    @Published var selectedUid: String? = nil

    // Private Properties
    private let pageSize = 30
    private let loadThreshold = 5
    private var lastDocumentSnapshot: DocumentSnapshot? = nil
    private var lastContactDocumentSnapshot: DocumentSnapshot? = nil
    private var mealRestaurantsLastSnapshot: DocumentSnapshot?
    private var cuisineRestaurantsLastSnapshots: [String: DocumentSnapshot?] = [:]
    private var restaurantsLastSnapshot: DocumentSnapshot?
    private var lastFriendPostDocument: DocumentSnapshot?
    private var lastTrendingPostDocument: DocumentSnapshot?
    private var lastGlobalTrendingPostDocument: DocumentSnapshot?
    private var topRestaurantsLastSnapshot: DocumentSnapshot?

    private var currentMealTime: String?
    private var currentLocation: CLLocationCoordinate2D?
    private var currentCuisineLocation: CLLocationCoordinate2D?

    private var currentPoll: Poll?
    private var user: User?
    private let mealRestaurantsPageSize = 5
    private let contactsPageSize = 5
    private let friendPostsPageSize: Int = 10

    // Service Instances
    private let service = ActivityService()
    private let userService = UserService.shared

    // Fetching States
    private var isFetchingMealRestaurants = false
    private var isFetchingCuisineRestaurants: [String: Bool] = [:]
    private var isFetchingFriendPosts: Bool = false
    private var isFetchingRestaurants: Bool = false
    private var isFetchingTopRestaurants = false
    @Published var recentFriendPost: Post?
        @Published var recentGlobalPost: Post?
        @Published var hasUnseenFriendPosts: Bool = false
    // MARK: - Methods

    func checkContactPermission() {
        let authorizationStatus = CNContactStore.authorizationStatus(for: .contacts)
        self.isContactPermissionGranted = authorizationStatus == .authorized
    }

    func fetchMealRestaurants(mealTime: String, location: CLLocationCoordinate2D?, pageSize: Int = 5) async throws {
        print("Fetching meal restaurants")

        guard !isFetchingMealRestaurants else { return }
        guard let location = location else { return }
        isFetchingMealRestaurants = true
        defer { isFetchingMealRestaurants = false }

        self.currentMealTime = mealTime
        self.currentLocation = location

        let (restaurants, lastSnapshot) = try await RestaurantService.shared.fetchRestaurantsServingMeal(
            mealTime: mealTime,
            location: location,
            lastDocument: mealRestaurantsLastSnapshot,
            limit: pageSize
        )

        self.mealRestaurants.append(contentsOf: restaurants)
        self.mealRestaurantsLastSnapshot = lastSnapshot
        self.hasMoreMealRestaurants = lastSnapshot != nil
    }

    func fetchMoreMealRestaurants() async {
        guard let mealTime = currentMealTime, let location = currentLocation else { return }
        do {
            try await fetchMealRestaurants(mealTime: mealTime, location: location, pageSize: mealRestaurantsPageSize)
        } catch {
            print("Error fetching more meal restaurants: \(error)")
        }
    }

    func fetchFriendPostsNearby(location: CLLocationCoordinate2D) async {
        print("Fetching friend posts")

        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        guard !isFetchingFriendPosts else { return }
        isFetchingFriendPosts = true
        defer { isFetchingFriendPosts = false }

        let geohash = GFUtils.geoHash(forLocation: location)
        let truncatedGeohash5 = String(geohash.prefix(5))
        let geohashNeighborsList = geohashNeighborsOfNeighbors(geohash: truncatedGeohash5)

        let db = Firestore.firestore()
        let postsRef = db.collection("followingposts").document(currentUserId).collection("posts")

        var query: Query = postsRef
            .whereField("restaurant.truncatedGeohash5", in: geohashNeighborsList)
            .order(by: "timestamp", descending: true)
            .limit(to: friendPostsPageSize)

        if let lastDocument = lastFriendPostDocument {
            query = query.start(afterDocument: lastDocument)
        }

        do {
            let snapshot = try await query.getDocuments()
            let posts = snapshot.documents.compactMap { try? $0.data(as: SimplifiedPost.self) }

            if let lastSnapshot = snapshot.documents.last {
                self.lastFriendPostDocument = lastSnapshot
            } else {
                self.hasMoreFriendPosts = false
            }

            let groupedPosts = Dictionary(grouping: posts) { $0.restaurant.id }

            var newRestaurants: [Restaurant] = []
            for (_, posts) in groupedPosts {
                if let firstPost = posts.first {
                    let restaurant = Restaurant(
                        id: firstPost.restaurant.id,
                        categoryName: firstPost.restaurant.cuisine,
                        price: firstPost.restaurant.price,
                        name: firstPost.restaurant.name,
                        geoPoint: firstPost.restaurant.geoPoint,
                        profileImageUrl: firstPost.restaurant.profileImageUrl,
                        stats: RestaurantStats(postCount: 0, collectionCount: 0)
                    )
                    newRestaurants.append(restaurant)
                }
            }

            self.friendPostsRestaurants.append(contentsOf: newRestaurants)

        } catch {
            print("Error fetching friend posts: \(error)")
            self.hasMoreFriendPosts = false
        }
    }

    private func geohashNeighborsOfNeighbors(geohash: String) -> [String] {
        var resultSet: Set<String> = [geohash]
        if let geoHash = Geohash(geohash: geohash),
           let immediateNeighbors = geoHash.neighbors?.all.map({ $0.geohash }) {
            resultSet.formUnion(immediateNeighbors)
            for neighborGeohash in immediateNeighbors {
                if let neighborGeoHash = Geohash(geohash: neighborGeohash),
                   let neighborNeighbors = neighborGeoHash.neighbors?.all.map({ $0.geohash }) {
                    resultSet.formUnion(neighborNeighbors)
                }
            }
        }
        return Array(resultSet)
    }

    func loadMoreContacts() {
        guard !isFetching, hasMoreContacts, !isLoadingMore else { return }

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

    func fetchTopContacts() async throws {
        print("Fetching contacts")

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

        for i in 0..<newContacts.count {
            if let user = try await userService.fetchUser(withPhoneNumber: newContacts[i].phoneNumber) {
                newContacts[i].user = user
            }
        }

        self.topContacts.append(contentsOf: newContacts)
        self.lastContactDocumentSnapshot = snapshot.documents.last
        self.hasMoreContacts = !snapshot.documents.isEmpty
    }

    func resetData() {
        mealRestaurantsLastSnapshot = nil
        hasMoreMealRestaurants = true
        mealRestaurants = []

        restaurantsLastSnapshot = nil
        hasMoreRestaurants = true
        fetchedRestaurants = []

        lastTrendingPostDocument = nil
        hasMoreTrendingPosts = true
        trendingPosts = []

        lastGlobalTrendingPostDocument = nil
        hasMoreGlobalTrendingPosts = true
        globalTrendingPosts = []
        globalTrendingPostsFullList = []

        lastFriendPostDocument = nil
        hasMoreFriendPosts = true
        friendPostsRestaurants = []
    }

    func resetContactsPagination() {
        topContacts = []
        lastContactDocumentSnapshot = nil
        hasMoreContacts = true
    }

    func checkIfUserIsFollowed(contact: Contact) async throws -> Bool {
        guard let userId = contact.user?.id else { return false }

        if let isFollowed = contact.isFollowed {
            return isFollowed
        }

        let isFollowed = try await userService.checkIfUserIsFollowed(uid: userId)

        if let index = topContacts.firstIndex(where: { $0.id == contact.id }) {
            self.topContacts[index].isFollowed = isFollowed
        }

        return isFollowed
    }

    func updateContactFollowStatus(contact: Contact, isFollowed: Bool) {
        if let index = topContacts.firstIndex(where: { $0.id == contact.id }) {
            self.topContacts[index].isFollowed = isFollowed
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
            self.topContacts[index].isFollowed = isFollowed 
        }
    }

    func fetchRestaurants(location: CLLocationCoordinate2D, limit: Int = 50) async throws {
        print("Fetching restaurants")
        guard !isFetchingRestaurants else { return }
        isFetchingRestaurants = true
        defer { isFetchingRestaurants = false }

        do {
            let (restaurants, lastSnapshot) = try await RestaurantService.shared.fetchTopRestaurants(
                location: location,
                lastDocument: restaurantsLastSnapshot,
                limit: limit
            )
            self.fetchedRestaurants.append(contentsOf: restaurants)
            self.restaurantsLastSnapshot = lastSnapshot
            self.hasMoreRestaurants = lastSnapshot != nil
        } catch {
            print("Error fetching restaurants: \(error)")
        }
    }

    func fetchTrendingPosts(location: CLLocationCoordinate2D) async throws {
        let geohash = GFUtils.geoHash(forLocation: location)
        let (posts, lastDocument) = try await PostService.shared.fetchTopPosts(geohash: geohash, lastDocument: nil, limit: 5)
        self.trendingPosts = posts
        self.lastTrendingPostDocument = lastDocument
        self.hasMoreTrendingPosts = lastDocument != nil
        self.currentLocation = location
    }

    func fetchMoreTrendingPosts() async {
        guard !isLoadingMoreTrendingPosts, hasMoreTrendingPosts else { return }
        isLoadingMoreTrendingPosts = true
        defer { isLoadingMoreTrendingPosts = false }

        do {
            if let location = currentLocation {
                let geohash = GFUtils.geoHash(forLocation: location)
                let (posts, lastDocument) = try await PostService.shared.fetchTopPosts(geohash: geohash, lastDocument: lastTrendingPostDocument, limit: 10)
                self.trendingPosts.append(contentsOf: posts)
                self.lastTrendingPostDocument = lastDocument
                self.hasMoreTrendingPosts = lastDocument != nil
            }
        } catch {
            print("Error fetching more trending posts: \(error)")
        }
    }

    // MARK: - Global Trending Posts
    func fetchTopGlobalTrendingPosts() async {
        guard !isLoadingGlobalTrendingPosts else { return }
        isLoadingGlobalTrendingPosts = true
        defer { isLoadingGlobalTrendingPosts = false }

        do {
            let (posts, _) = try await PostService.shared.fetchGlobalTopPosts(
                lastDocument: nil,
                limit: 5
            )
            self.globalTrendingPosts = posts
        } catch {
            print("Error fetching global trending posts: \(error)")
        }
    }

    func fetchGlobalTrendingPostsForFullList() async {
        guard !isLoadingMoreGlobalTrendingPosts, hasMoreGlobalTrendingPosts else { return }
        isLoadingMoreGlobalTrendingPosts = true
        defer { isLoadingMoreGlobalTrendingPosts = false }

        do {
            let (posts, lastDocument) = try await PostService.shared.fetchGlobalTopPosts(
                lastDocument: lastGlobalTrendingPostDocument,
                limit: 10
            )
            self.globalTrendingPostsFullList.append(contentsOf: posts)
            self.lastGlobalTrendingPostDocument = lastDocument
            self.hasMoreGlobalTrendingPosts = lastDocument != nil
        } catch {
            print("Error fetching more global trending posts: \(error)")
        }
    }

    func resetGlobalTrendingPostsPagination() {
        globalTrendingPostsFullList = []
        lastGlobalTrendingPostDocument = nil
        hasMoreGlobalTrendingPosts = true
    }
    func fetchRecentPosts(unseenCount: Int) async {
            do {
                // Check if the user has unseen friend posts
                if unseenCount > 0 {
                    hasUnseenFriendPosts = true
                    // Fetch the most recent friend post
                    recentFriendPost = try await fetchMostRecentFriendPost()
                } else {
                    hasUnseenFriendPosts = false
                    // Fetch the most recent global post
                    recentGlobalPost = try await fetchMostRecentGlobalPost()
                }
            } catch {
                print("Error fetching recent posts: \(error)")
            }
        }

        private func fetchMostRecentFriendPost() async throws -> Post? {
            // Fetch the most recent post from friends
            guard let currentUserId = Auth.auth().currentUser?.uid else { return nil }
            let db = Firestore.firestore()
            let followingRef = db.collection("followingposts").document(currentUserId).collection("posts")
            let query = followingRef
                .order(by: "timestamp", descending: true)
                .limit(to: 1)

            let snapshot = try await query.getDocuments()
            if let document = snapshot.documents.first {
                let simplifiedPost = try document.data(as: SimplifiedPost.self)
                return simplifiedPost.toPost()
                // Fetch full post details
            }
            return nil
        }

        private func fetchMostRecentGlobalPost() async throws -> Post? {
            // Fetch the most recent post from the app
            let db = Firestore.firestore()
            let query = db.collection("posts")
                .order(by: "timestamp", descending: true)
                .limit(to: 1)

            let snapshot = try await query.getDocuments()
            return snapshot.documents.first.flatMap { try? $0.data(as: Post.self) }
        }
    
}

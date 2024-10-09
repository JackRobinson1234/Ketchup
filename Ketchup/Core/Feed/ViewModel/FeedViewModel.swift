//
//  FeedViewModel.swift
//  foodi
//
//  Created by Jack Robinson on 1/6/24.
//

import SwiftUI
import Kingfisher
import FirebaseFirestoreInternal
import AVFoundation
import CachingPlayerItem
import FirebaseAuth
import CoreLocation
import GeoFire
import GeohashKit
import Firebase
enum FeedType: String, CaseIterable {
    case discover = "Discover"
    case following = "Following"
}

enum FeedTab {
    case discover
    case following
}
enum FeedLocationSetting: String, CaseIterable, Identifiable {
    var id: String { self.rawValue }

    //case exactCity = "Exact City"
    case twoMiles = "1 mile"
    case fiveMiles = "3 miles"
    case tenMiles = "5 miles"
    case twentyMiles = "10 miles"
    case anywhere = "Any"
}
protocol CommentableViewModel: ObservableObject {
    var selectedCommentId: String? { get }// Include any other common properties or methods
}
@MainActor
class FeedViewModel: ObservableObject, CommentableViewModel  {
    
    @Published var posts = [Post]()
    @Published var showEmptyView = false
    @Published var currentlyPlayingPostID: String?
    @Published var initialPrimaryScrollPosition: String?
    var isContainedInTabBar = true
    @Published var isLoading = false
    private var lastDocument: DocumentSnapshot?
    private var isFetching = false
    private let pageSize = 15
    private let fetchingThreshold = -5
    @Published var filters: [String: [Any]]? = [:]
    private var lastFetched: Int = 0
    @Published var duration: Double = 0.0
    @Published var currentTime: Double = 0.0
    @Published var isDragging = false
    @Published var startingPostId: String
    @Published var hasMorePosts: Bool = true
    @Published var showPostAlert: Bool = false
    @Published var showRepostAlert: Bool = false
    @Published var startingImageIndex = 0
    @Published var isMuted: Bool = false
    private var prefetching = false
    let videoCoordinator = VideoPlayerCoordinator()
    var preloadedPlayerItems = NSCache<NSString, AVQueuePlayer>()
    private let synchronizationQueue = DispatchQueue(label: "com.yourapp.prefetchingQueue")
    private var followingUsers: [String] = []
    @Published var isLoadingMoreContent = false
    private var fetchTask: Task<Void, Error>?
    @Published var isShowingProfileSheet: Bool = false
    @Published var selectedTab: FeedTab = .discover {
        didSet {
            Task {
                if selectedTab == .following {
                    currentLocationFilter = .anywhere
                }
                isInitialLoading = true
                await handleTabChange()
                isInitialLoading = false
                resetNewPostsCount()
                
            }
        }
    }
    @Published var showBookmarks = true
    @Published var selectedCommentId: String?
    @Published var isInitialLoading: Bool = false
    @Published var initialOffset: CGFloat?
    @Published var friendsOverallRating: Double?
    @Published var friendsFoodRating: Double?
    @Published var friendsValueRating: Double?
    @Published var friendsAtmosphereRating: Double?
    @Published var friendsServiceRating: Double?
    @Published var city: String?
    @Published var state: String?
    @Published var surroundingGeohash: String?
    @Published var surroundingCounty: String = "Nearby"
    
    @Published var currentLocationFilter: FeedLocationSetting = .anywhere
    @Published var simplifiedPosts: [SimplifiedPost] = []
    private var lastSimplifiedPostTimestamp: Timestamp?
    private let simplifiedPostPageSize = 15
    private let locationManager = LocationManager.shared
    
    init(posts: [Post] = [], startingPostId: String = "", earlyPosts: [Post] = [], showBookmarks: Bool = true, selectedCommentId: String? = nil) {
        self.posts = posts
        self.isContainedInTabBar = posts.isEmpty
        self.startingPostId = startingPostId
        self.showBookmarks = showBookmarks
    }
    func setupLocation() {
        
        isInitialLoading = true
        locationManager.requestLocation { success in
            
            if success {
                Task{
                    self.updateLocationInfo()
                    try await self.fetchInitialPosts()
                    self.isInitialLoading = false
                }
            } else {
                Task{
                    //print("Failed to get user location")
                    self.loadLocationFromUserSession()
                    try await self.fetchInitialPosts()
                    self.isInitialLoading = false
                    
                }
            }
            
        }
    }
    
    private func updateLocationInfo() {
        guard let location = locationManager.userLocation else { return }
        updateLocation(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
    }
    
    private func loadLocationFromUserSession() {
        if let userSession = AuthService.shared.userSession,
           let userLocation = userSession.location,
           let geoPoint = userLocation.geoPoint {
            updateLocation(latitude: geoPoint.latitude, longitude: geoPoint.longitude)
        }
    }
    
    func updateLocation(latitude: Double, longitude: Double) {
        surroundingGeohash = GFUtils.geoHash(forLocation: CLLocationCoordinate2D(latitude: latitude, longitude: longitude))
        //print(surroundingGeohash, "2")
        reverseGeocodeLocation(latitude: latitude, longitude: longitude)
        //        Task{
        //            try await fetchInitialPosts()
        //        }
    }
    
    private func reverseGeocodeLocation(latitude: Double, longitude: Double) {
        let location = CLLocation(latitude: latitude, longitude: longitude)
        let geocoder = CLGeocoder()
        
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
            guard let self = self else { return }
            
            if let error = error {
                //print("Reverse geocoding error: \(error.localizedDescription)")
                return
            }
            
            if let placemark = placemarks?.first {
                self.city = placemark.locality
                self.state = placemark.administrativeArea
                self.surroundingCounty = placemark.subAdministrativeArea ?? "Nearby"
            }
        }
    }
    
    func applyLocationFilter() {
        filters?.removeValue(forKey: "restaurant.truncatedGeohash6")
        filters?.removeValue(forKey: "restaurant.truncatedGeohash5")
        filters?.removeValue(forKey: "restaurant.truncatedGeohash")
        filters?.removeValue(forKey: "restaurant.city")
        switch currentLocationFilter {
//        case .exactCity:
//            if let city = self.city {
//                filters?["restaurant.city"] = [city]
//            } else {
//                filters?.removeValue(forKey: "restaurant.city")
//            }
//            filters?.removeValue(forKey: "restaurant.truncatedGeohash")
        case .twoMiles:
            if let geohash = surroundingGeohash {
                let geohashPrefix = String(geohash.prefix(6))
                filters?["restaurant.truncatedGeohash6"] = geohashNeighbors(geohash: geohashPrefix)
            } else {
                filters?.removeValue(forKey: "restaurant.truncatedGeohash6")
            }
        case .fiveMiles:
            if let geohash = surroundingGeohash {
                let geohashPrefix = String(geohash.prefix(6))
                filters?["restaurant.truncatedGeohash6"] = geohashNeighborsOfNeighbors(geohash: geohashPrefix)
            } else {
                filters?.removeValue(forKey: "restaurant.truncatedGeohash6")
            }
        case .tenMiles:
            if let geohash = surroundingGeohash {
                let geohashPrefix = String(geohash.prefix(5))
                filters?["restaurant.truncatedGeohash5"] = geohashNeighbors(geohash: geohashPrefix)
            } else {
                filters?.removeValue(forKey: "restaurant.truncatedGeohash5")
            }
        case .twentyMiles:
            if let geohash = surroundingGeohash {
                let geohashPrefix = String(geohash.prefix(4))
                filters?["restaurant.truncatedGeohash"] = geohashNeighbors(geohash: geohashPrefix)
            } else {
                filters?.removeValue(forKey: "restaurant.truncatedGeohash")
            }
        case .anywhere:
            filters?.removeValue(forKey: "restaurant.truncatedGeohash6")
            filters?.removeValue(forKey: "restaurant.truncatedGeohash5")
            filters?.removeValue(forKey: "restaurant.truncatedGeohash")
            filters?.removeValue(forKey: "restaurant.city")
        }
    }
    private func geohashNeighborsOfNeighbors(geohash: String) -> [String] {
        var resultSet: Set<String> = [geohash]  // Start with the original geohash
        
        // Get immediate neighbors of the original geohash
        if let geoHash = Geohash(geohash: geohash) {
            if let immediateNeighbors = geoHash.neighbors?.all.map({ $0.geohash }) {
                resultSet.formUnion(immediateNeighbors)  // Add immediate neighbors to the set
                
                // For each immediate neighbor, get its immediate neighbors (neighbors of neighbors)
                for neighborGeohash in immediateNeighbors {
                    if let neighborGeoHash = Geohash(geohash: neighborGeohash) {
                        if let neighborNeighbors = neighborGeoHash.neighbors?.all.map({ $0.geohash }) {
                            resultSet.formUnion(neighborNeighbors)  // Add neighbors of neighbors to the set
                        }
                    }
                }
            }
        }
        
        return Array(resultSet)
    }
    private func geohashNeighbors(geohash: String) -> [String] {
        if let geoHash = Geohash(geohash: geohash) {
            if let neighbors = geoHash.neighbors {
                let neighborGeohashes = neighbors.all.map { $0.geohash }
                return [geohash] + neighborGeohashes
            }
        }
        return [geohash]
    }
    private func handleTabChange() async {
        
        resetFeedState()
        do {
            if selectedTab == .following {
                await fetchFollowingUsers()
            }
            var newPosts = try await fetchPostsPage(withFilters: self.filters, isInitialLoad: true)
            await checkPostInteractions(for: &newPosts)
            handleFetchedPosts(newPosts, isInitialLoad: true)
        } catch {
            ////print("Error handling tab change: \(error)")
        }
    }
    @MainActor
    func fetchInitialPosts(withFilters filters: [String: [Any]]? = nil) async {
        
        resetFeedState(filters: filters)
        do {
            var newPosts = try await fetchPostsPage(withFilters: self.filters, isInitialLoad: true)
            await checkPostInteractions(for: &newPosts)
            handleFetchedPosts(newPosts, isInitialLoad: true)
        } catch {
            ////print("Error fetching initial posts: \(error)")
        }
    }
    
    private func resetFeedState(filters: [String: [Any]]? = nil) {
        lastSimplifiedPostTimestamp = nil
        isLoading = true
        lastDocument = nil
        hasMorePosts = true
        //self.filters = filters
        lastFetched = 0
    }
    
    func fetchMorePosts() async {
        guard shouldFetchMorePosts(currentPost: posts.last?.id) else { return }
        
        isFetching = true
        do {
            var newPosts = try await fetchPostsPage(withFilters: self.filters)
            await checkPostInteractions(for: &newPosts)
            handleFetchedPosts(newPosts, isInitialLoad: false)
        } catch {
            //print("DEBUG: Error fetching more posts: \(error)")
        }
        isFetching = false
    }
    
    private func shouldFetchMorePosts(currentPost: String?) -> Bool {
        guard let currentPost = currentPost, !posts.isEmpty else { return false }
        guard !isFetching, hasMorePosts else { return false }
        
        if let currentIndex = posts.firstIndex(where: { $0.id == currentPost }) {
            let thresholdIndex = max(0, posts.count - abs(fetchingThreshold))
            return currentIndex >= thresholdIndex && currentIndex > lastFetched
        }
        return false
    }
    private func fetchPostsPage(withFilters filters: [String: [Any]]? = nil, isInitialLoad: Bool = false) async throws -> [Post] {
        if selectedTab == .following {
            return try await fetchFollowingPostsPage()
        } else {
            return try await fetchRegularPostsPage(withFilters: filters, isInitialLoad: isInitialLoad)
        }
    }
    
    private func fetchFollowingPostsPage() async throws -> [Post] {
        guard let currentUserId = Auth.auth().currentUser?.uid else { throw NSError(domain: "FeedViewModel", code: 1, userInfo: [NSLocalizedDescriptionKey: "No current user"]) }
        
        let newSimplifiedPosts = try await fetchSimplifiedFollowingPosts(userId: currentUserId, withFilters: filters)
        let newPosts = try await fetchFullPostDetails(for: newSimplifiedPosts)
        
        await MainActor.run {
            self.simplifiedPosts.append(contentsOf: newSimplifiedPosts)
            self.lastSimplifiedPostTimestamp = newSimplifiedPosts.last?.timestamp
        }
        
        return newPosts
    }
    
    private func fetchRegularPostsPage(withFilters filters: [String: [Any]]? = nil, isInitialLoad: Bool = false) async throws -> [Post] {
        applyLocationFilter()
        //print("FETCHING WITH FILTERS", filters)
        var updatedFilters = filters ?? [:]
        updatedFilters["user.privateMode"] = [false]
        
        let db = Firestore.firestore()
        var query: Query = db.collection("posts")
        
        for (key, value) in updatedFilters {
            query = query.whereField(key, in: value)
        }
        
        if selectedTab != .following {
            query = query.whereField("user.id", isNotEqualTo: "6nLYduH5e0RtMvjhediR7GkaI003")
        }
       
        query = query.order(by: "timestamp", descending: true)
            .limit(to: pageSize)
        
        if let lastDocument = lastDocument {
            query = query.start(afterDocument: lastDocument)
        }
        
        let snapshot = try await query.getDocuments()
        self.lastDocument = snapshot.documents.last
        return snapshot.documents.compactMap { try? $0.data(as: Post.self) }
    }
    
    private func fetchSimplifiedFollowingPosts(userId: String, withFilters filters: [String: [Any]]? = nil) async throws -> [SimplifiedPost] {
        applyLocationFilter()
        guard let currentUserID = Auth.auth().currentUser?.uid else { return [] }
        
        var query: Query = Firestore.firestore().collection("followingposts").document(currentUserID).collection("posts")
        if let filters, !filters.isEmpty {
            for (key, value) in filters {
                query = query.whereField(key, in: value)
            }
        }
        query = query
            .order(by: "timestamp", descending: true)
            .limit(to: simplifiedPostPageSize)
        
        
        if let lastTimestamp = lastSimplifiedPostTimestamp {
            query = query.start(after: [lastTimestamp])
        }
        
        let snapshot = try await query.getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: SimplifiedPost.self) }
    }
    
    private func fetchFullPostDetails(for simplifiedPosts: [SimplifiedPost]) async throws -> [Post] {
        let db = Firestore.firestore()
        let postIds = simplifiedPosts.map { $0.id }
        
        let chunks = postIds.chunked(into: 30) // Firestore allows up to 10 items in a whereField(in:) query
        var allPosts: [Post] = []
        
        for chunk in chunks {
            let query = db.collection("posts").whereField("id", in: chunk).order(by: "timestamp", descending: true)
            let snapshot = try await query.getDocuments()
            let posts = snapshot.documents.compactMap { try? $0.data(as: Post.self) }
            allPosts.append(contentsOf: posts)
        }
        
        return allPosts
    }
    
    
    
    private func handleFetchedPosts(_ newPosts: [Post], isInitialLoad: Bool) {
        if isInitialLoad {
            posts = newPosts
        } else {
            posts.append(contentsOf: newPosts)
        }
        hasMorePosts = newPosts.count >= pageSize
        showEmptyView = posts.isEmpty
        isInitialLoading = false
    }
    private func fetchFollowingUsers() async {
        do {
            let userIds = try await UserService.shared.fetchFollowingUserIds()
            self.followingUsers = userIds
        } catch {
            ////print("Error fetching following users: \(error)")
            self.followingUsers = []
        }
    }
    func fetchUserPosts(user: User) async throws {
        do {
            if user.username != "ketchup_media"{
                
                self.posts = try await PostService.shared.fetchUserPosts(user: user)
            }
        } catch {
            ////print("DEBUG: Failed to fetch posts with error: \(error.localizedDescription)")
        }
    }
    func fetchUserLikedPosts(user: User) async throws {
        do {
            self.posts = try await PostService.shared.fetchUserLikedPosts(user: user)
            
        } catch {
            ////print("DEBUG: Failed to fetch posts with error: \(error.localizedDescription)")
        }
        
    }
    func fetchPosts(withFilters filters: [String: [Any]]? = nil, isInitialLoad: Bool = false) async {
        if Task.isCancelled { return }
        if isInitialLoad{
            isInitialLoading = true
        }
        await MainActor.run {
            if !hasMorePosts {
                ////print("Doesn't have any more posts")
                return
            }
            
            if isInitialLoad {
                lastDocument = nil
            }
            
            self.isLoading = true // Set loading to true
        }
        
        do {
            var updatedFilters = filters ?? [:]
            updatedFilters["user.privateMode"] = [false]
            
            let db = Firestore.firestore()
            var query: Query = db.collection("posts")
            
            for (key, value) in updatedFilters {
                query = query.whereField(key, in: value)
            }
            if selectedTab != .following{
                query = query.whereField("user.id", isNotEqualTo: "6nLYduH5e0RtMvjhediR7GkaI003")
            }
            if selectedTab == .following {
                let followingBatch = Array(followingUsers.prefix(30))
                if followingBatch.isEmpty {
                    await MainActor.run {
                        self.posts = []
                        self.showEmptyView = true
                        self.hasMorePosts = false
                        self.isLoading = false // Set loading to false
                    }
                    return
                }
                query = query.whereField("user.id", in: followingBatch)
            }
            
            query = query.order(by: "timestamp", descending: true)
                .limit(to: pageSize)
            
            if let lastDocument = lastDocument {
                query = query.start(afterDocument: lastDocument)
            }
            
            let snapshot = try await query.getDocuments()
            if Task.isCancelled { return }
            var newPosts = snapshot.documents.compactMap { try? $0.data(as: Post.self) }
            if newPosts.isEmpty {
                await MainActor.run {
                    self.hasMorePosts = false
                    if isInitialLoad {
                        self.posts = []
                    }
                    self.showEmptyView = self.posts.isEmpty
                    self.isInitialLoading = false // Set loading to false
                }
                return
            }
            
            // Check if user liked and bookmarked the new posts
            for i in 0..<newPosts.count {
                do {
                    newPosts[i].didLike = try await PostService.shared.checkIfUserLikedPost(newPosts[i])
                    newPosts[i].didBookmark = try await PostService.shared.checkIfUserBookmarkedRestaurant(restaurantId: newPosts[i].restaurant.id)
                } catch {
                    ////print("DEBUG: Failed to check if user liked or bookmarked post")
                }
            }
            
            await MainActor.run {
                if newPosts.isEmpty {
                    self.hasMorePosts = false
                } else {
                    if isInitialLoad {
                        self.posts = newPosts
                    } else {
                        self.posts.append(contentsOf: newPosts)
                    }
                    self.lastDocument = snapshot.documents.last
                    self.hasMorePosts = newPosts.count >= self.pageSize
                }
                self.showEmptyView = self.posts.isEmpty
                self.isInitialLoading = false // Set loading to false
            }
        } catch {
            ////print("DEBUG: Failed to fetch posts \(error.localizedDescription)")
            await MainActor.run {
                self.isInitialLoading = false // Set loading to false in case of error
            }
        }
    }
    
    func fetchRestaurantPosts(restaurant: Restaurant, friendIds: [String]) async throws {
        do {
            // Ensure the current user is authenticated
            guard let currentUserId = Auth.auth().currentUser?.uid else {
                throw NSError(domain: "FeedViewModel", code: 1, userInfo: [NSLocalizedDescriptionKey: "No current user"])
            }
            
            // Fetch posts from friends
            let (friendsPosts, overallAverageRating, averageFoodRating, averageServiceRating, averageAtmosphereRating, averageValueRating) = try await PostService.shared.fetchFriendsPosts(for: restaurant, friendIds: friendIds)
            
            // Fetch remaining posts excluding friends' posts
            let remainingPosts = try await PostService.shared.fetchRemainingRestaurantPosts(for: restaurant, excluding: friendIds)
            
            // Combine and update the posts
            DispatchQueue.main.async {
                self.posts = friendsPosts + remainingPosts
                self.friendsOverallRating = overallAverageRating
                self.friendsFoodRating = averageFoodRating
                self.friendsServiceRating = averageServiceRating
                self.friendsAtmosphereRating = averageAtmosphereRating
                self.friendsValueRating = averageValueRating
            }
            
        } catch {
            ////print("DEBUG: Failed to fetch posts with error: \(error.localizedDescription)")
        }
    }
    func updateCache(scrollPosition: String?) {
        guard !posts.isEmpty, let scrollPosition = scrollPosition else {
            ////print("Posts array is empty or scroll position is nil")
            return
        }
        
        guard let currentIndex = posts.firstIndex(where: { $0.id == scrollPosition }) else {
            ////print("Current index not found in posts array")
            return
        }
        
        ////print("Updating cache. Current index: \(currentIndex), Posts count: \(posts.count)")
        
        let startIndex = min(currentIndex + 1, posts.count - 1)
        let endIndex = min(currentIndex + 6, posts.count)
        
        guard startIndex < endIndex else {
            ////print("Invalid range: startIndex \(startIndex) is not less than endIndex \(endIndex)")
            return
        }
        
        let postsToPreload = Array(posts[startIndex..<endIndex])
        
        ////print("Preloading \(postsToPreload.count) posts")
        
        DispatchQueue.global().async {
            for post in postsToPreload {
                Task {
                    if post.mediaType == .video {
                        if let videoURL = post.mediaUrls.first, let url = URL(string: videoURL) {
                            ////print("Running prefetch for video")
                            VideoPrefetcher.shared.prefetchPosts([post])
                        }
                    } else if post.mediaType == .photo {
                        let prefetcher = ImagePrefetcher(urls: post.mediaUrls.compactMap { URL(string: $0) })
                        prefetcher.start()
                    }
                    
                    if let profileImageUrl = post.user.profileImageUrl, let userProfileImageURL = URL(string: profileImageUrl) {
                        let prefetcher = ImagePrefetcher(urls: [userProfileImageURL])
                        prefetcher.start()
                    }
                    
                    if let profileImageURL = post.restaurant.profileImageUrl, let restaurantProfileImageURL = URL(string: profileImageURL) {
                        let prefetcher = ImagePrefetcher(urls: [restaurantProfileImageURL])
                        prefetcher.start()
                    }
                }
            }
        }
    }
}

extension FeedViewModel {
    func like(_ post: Post) async {
        guard let index = posts.firstIndex(where: { $0.id == post.id }) else { return }
        posts[index].didLike = true
        posts[index].likes += 1
        
        do {
            try await PostService.shared.likePost(post)
        } catch {
            ////print("DEBUG: Failed to like post with error \(error.localizedDescription)")
            posts[index].didLike = false
            posts[index].likes -= 1
        }
    }
    
    func unlike(_ post: Post) async {
        guard let index = posts.firstIndex(where: { $0.id == post.id }) else { return }
        posts[index].didLike = false
        posts[index].likes -= 1
        
        do {
            try await PostService.shared.unlikePost(post)
        } catch {
            ////print("DEBUG: Failed to unlike post with error \(error.localizedDescription)")
            posts[index].didLike = true
            posts[index].likes += 1
        }
    }
    
    func checkIfUserLikedPosts() async {
        guard !posts.isEmpty else { return }
        var copy = posts
        for i in 0..<copy.count {
            do {
                let post = copy[i]
                let didLike = try await PostService.shared.checkIfUserLikedPost(post)
                
                if didLike {
                    copy[i].didLike = didLike
                }
            } catch {
                ////print("DEBUG: Failed to check if user liked post")
            }
        }
        
        posts = copy
    }
    
    func loadMoreContentIfNeeded(currentPost: String?) async {
        guard let currentPost = currentPost, !posts.isEmpty else {
            ////print("No current post or posts array is empty")
            return
        }
        
        guard !isFetching && hasMorePosts else {
            ////print("Already fetching or no more posts to fetch")
            return
        }
        
        guard let currentIndex = posts.firstIndex(where: { $0.id == currentPost }) else {
            ////print("Error: Current post not found in the posts array")
            return
        }
        
        let thresholdIndex = max(0, posts.count - abs(fetchingThreshold))
        
        if currentIndex >= thresholdIndex && currentIndex > lastFetched {
            ////print("Fetching more posts. Current index: \(currentIndex), Last fetched: \(lastFetched)")
            lastFetched = currentIndex
            
            Task {
                isLoadingMoreContent = true
                await fetchMorePosts()
                isLoadingMoreContent = false
            }
        } else {
            ////print("Not yet reached the threshold for fetching more posts. Current index: \(currentIndex), Threshold: \(thresholdIndex), Last fetched: \(lastFetched)")
        }
    }
    
    func isLastItem(_ post: Post) -> Bool {
        guard let lastPost = posts.last else {
            return false
        }
        return post.id == lastPost.id
    }
}

extension FeedViewModel {
    func updateCurrentlyPlayingPostID(_ postID: String?) {
        self.currentlyPlayingPostID = postID
    }
}

extension FeedViewModel {
    func deletePost(post: Post) async {
        do {
            try await PostService.shared.deletePost(post)
            if let index = posts.firstIndex(where: { $0.id == post.id }) {
                posts.remove(at: index)
            }
            AuthService.shared.userSession?.stats.posts -= 1

        } catch {
            ////print("DEBUG: Failed to delete post with error \(error.localizedDescription)")
        }
    }
    
    func repost(_ post: Post) async {
        guard let index = posts.firstIndex(where: { $0.id == post.id }) else { return }
        posts[index].didRepost = true
        posts[index].repostCount += 1
        
        AuthService.shared.userSession?.stats.posts += 1
        do {
            try await PostService.shared.repostPost(post)
        } catch {
            ////print("DEBUG: Failed to like post with error \(error.localizedDescription)")
            posts[index].didRepost = false
            posts[index].repostCount -= 1
            AuthService.shared.userSession?.stats.posts -= 1
        }
    }
    
    func removeRepost(_ post: Post) async {
        guard let index = posts.firstIndex(where: { $0.id == post.id }) else { return }
        posts[index].didRepost = false
        posts[index].repostCount -= 1
        AuthService.shared.userSession?.stats.posts -= 1
        do {
            try await PostService.shared.removeRepost(post)
        } catch {
            ////print("DEBUG: Failed to removeRepost with error \(error.localizedDescription)")
            posts[index].didRepost = true
            posts[index].repostCount += 1
            AuthService.shared.userSession?.stats.posts += 1
        }
    }
    private func checkPostInteractions(for posts: inout [Post]) async {
        for i in 0..<posts.count {
            do {
                posts[i].didLike = try await PostService.shared.checkIfUserLikedPost(posts[i])
                posts[i].didBookmark = try await PostService.shared.checkIfUserBookmarkedRestaurant(restaurantId: posts[i].restaurant.id)
            } catch {
                ////print("DEBUG: Failed to check if user liked or bookmarked post \(posts[i].id)")
            }
        }
    }
}
extension FeedViewModel {
    func updatePost(_ updatedPost: Post) {
        if let index = posts.firstIndex(where: { $0.id == updatedPost.id }) {
            ////print("FOUND INDEX")
            ////print("updatedPost", updatedPost.caption)
            posts[index] = updatedPost
        } else {
            
        }
    }
}
extension FeedViewModel {
    func bookmark(_ post: Post) async {
        do {
            try await PostService.shared.bookmarkRestaurant(from: post)
            
            // Update all posts with the same restaurant.id
            updateBookmarkStatus(for: post.restaurant.id, isBookmarked: true)
        } catch {
            ////print("DEBUG: Failed to bookmark restaurant with error \(error.localizedDescription)")
        }
    }
    
    func unbookmark(_ post: Post) async {
        do {
            try await PostService.shared.unbookmarkFromPost(post)
            
            // Update all posts with the same restaurant.id
            updateBookmarkStatus(for: post.restaurant.id, isBookmarked: false)
        } catch {
            ////print("DEBUG: Failed to unbookmark restaurant with error \(error.localizedDescription)")
        }
    }
    
    private func updateBookmarkStatus(for restaurantId: String, isBookmarked: Bool) {
        for index in posts.indices {
            if posts[index].restaurant.id == restaurantId {
                posts[index].didBookmark = isBookmarked
            }
        }
    }
    func checkIfUserBookmarkedPost(_ post: Post) async -> Bool {
        guard let uid = Auth.auth().currentUser?.uid else { return false }
        
        do {
            let bookmarkRef = FirestoreConstants.PostsCollection
                .document(post.id)
                .collection("post-bookmarks")
                .document(uid)
            
            let snapshot = try await bookmarkRef.getDocument()
            return snapshot.exists
        } catch {
            ////print("DEBUG: Failed to check if user bookmarked post with error \(error.localizedDescription)")
            return false
        }
    }
    func resetNewPostsCount() {
        
        let authService = AuthService.shared
        
        guard let userId = authService.userSession?.id,
              let currentCount = authService.userSession?.followingPosts,
              currentCount > 0 else { return }
        
        
        // Reset count in Firebase
        
        let userRef = Firestore.firestore().collection("users").document(userId)
        userRef.updateData(["followingPosts": 0]) { error in
            if let error = error {
                //print("Error resetting followingPosts in Firebase: \(error.localizedDescription)")
            } else {
                //print("Successfully reset followingPosts in Firebase")
            }
        }
        
        // Reset count in local auth user session
        authService.userSession?.followingPosts = 0
        
        // Reset local state
    }
}
extension FeedViewModel {
    var activeCuisineAndPriceFiltersCount: Int {
        var count = 0
        if let filters = filters {
            if let cuisines = filters["restaurant.cuisine"] {
                count += cuisines.count
            }
            if let prices = filters["restaurant.price"] {
                count += prices.count
            }
        }
        return count
    }
}

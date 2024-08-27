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
enum FeedType: String, CaseIterable {
    case discover = "Discover"
    case following = "Following"
}

enum FeedTab {
    case discover
    case following
}

@MainActor
class FeedViewModel: ObservableObject {
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
                isInitialLoading = true
                await handleTabChange()
                isInitialLoading = false
            }
        }
    }
    @Published var showBookmarks = true
    @Published var selectedCommentId: String?
    @Published var isInitialLoading: Bool = false
    @Published var initialOffset: CGFloat?


    
    init(posts: [Post] = [], startingPostId: String = "", earlyPosts: [Post] = [], showBookmarks: Bool = true, selectedCommentId: String? = nil) {
        self.posts = posts
        self.isContainedInTabBar = posts.isEmpty
        self.startingPostId = startingPostId
        self.showBookmarks = showBookmarks
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
                print("Error handling tab change: \(error)")
            }
        }
    @MainActor
    func fetchInitialPosts(withFilters filters: [String: [Any]]? = nil) async {
            resetFeedState(filters: filters)
            
            do {
                var newPosts = try await fetchPostsPage(withFilters: filters, isInitialLoad: true)
                await checkPostInteractions(for: &newPosts)
                handleFetchedPosts(newPosts, isInitialLoad: true)
            } catch {
                print("Error fetching initial posts: \(error)")
            }
        }
    
    private func resetFeedState(filters: [String: [Any]]? = nil) {
            isLoading = true
            lastDocument = nil
            hasMorePosts = true
            self.filters = filters
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
                print("Error fetching more posts: \(error)")
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

           if selectedTab == .following {
               let followingBatch = Array(followingUsers.prefix(30))
               if followingBatch.isEmpty { return [] }
               query = query.whereField("user.id", in: followingBatch)
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
                print("Error fetching following users: \(error)")
                self.followingUsers = []
            }
        }
    func fetchUserPosts(user: User) async throws {
        do {
            if user.username != "ketchup_media"{
                
                self.posts = try await PostService.shared.fetchUserPosts(user: user)
            }
        } catch {
            print("DEBUG: Failed to fetch posts with error: \(error.localizedDescription)")
        }
    }
    func fetchUserLikedPosts(user: User) async throws {
        do {
            self.posts = try await PostService.shared.fetchUserLikedPosts(user: user)
           
        } catch {
            print("DEBUG: Failed to fetch posts with error: \(error.localizedDescription)")
        }
        
    }
    func fetchPosts(withFilters filters: [String: [Any]]? = nil, isInitialLoad: Bool = false) async {
        if Task.isCancelled { return }
        if isInitialLoad{
            isInitialLoading = true
        }
        await MainActor.run {
            if !hasMorePosts {
                print("Doesn't have any more posts")
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
                    print("DEBUG: Failed to check if user liked or bookmarked post")
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
            print("DEBUG: Failed to fetch posts \(error.localizedDescription)")
            await MainActor.run {
                self.isInitialLoading = false // Set loading to false in case of error
            }
        }
    }
    func fetchRestaurantPosts(restaurant: Restaurant) async throws{
        do {
            self.posts = try await PostService.shared.fetchRestaurantPosts(restaurant: restaurant)
        } catch {
            print("DEBUG: Failed to fetch posts with error: \(error.localizedDescription)")
            
        }
    }
    func updateCache(scrollPosition: String?) {
           guard !posts.isEmpty, let scrollPosition = scrollPosition,
                 let currentIndex = posts.firstIndex(where: { $0.id == scrollPosition }) else {
               return
           }

           ContentPrefetcher.shared.prefetchContent(for: posts, currentIndex: currentIndex)
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
            print("DEBUG: Failed to like post with error \(error.localizedDescription)")
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
            print("DEBUG: Failed to unlike post with error \(error.localizedDescription)")
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
                print("DEBUG: Failed to check if user liked post")
            }
        }
        
        posts = copy
    }
    
    func loadMoreContentIfNeeded(currentPost: String?) async {
        guard let currentPost = currentPost, !posts.isEmpty else {
            print("No current post or posts array is empty")
            return
        }
        
        guard !isFetching && hasMorePosts else {
            print("Already fetching or no more posts to fetch")
            return
        }
        
        guard let currentIndex = posts.firstIndex(where: { $0.id == currentPost }) else {
            print("Error: Current post not found in the posts array")
            return
        }
        
        let thresholdIndex = max(0, posts.count - abs(fetchingThreshold))
        
        if currentIndex >= thresholdIndex && currentIndex > lastFetched {
            print("Fetching more posts. Current index: \(currentIndex), Last fetched: \(lastFetched)")
            lastFetched = currentIndex
            
            Task {
                isLoadingMoreContent = true
                await fetchMorePosts()
                isLoadingMoreContent = false
            }
        } else {
            print("Not yet reached the threshold for fetching more posts. Current index: \(currentIndex), Threshold: \(thresholdIndex), Last fetched: \(lastFetched)")
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
        } catch {
            print("DEBUG: Failed to delete post with error \(error.localizedDescription)")
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
            print("DEBUG: Failed to like post with error \(error.localizedDescription)")
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
            print("DEBUG: Failed to removeRepost with error \(error.localizedDescription)")
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
                    print("DEBUG: Failed to check if user liked or bookmarked post \(posts[i].id)")
                }
            }
        }
}
extension FeedViewModel {
    func updatePost(_ updatedPost: Post) {
        if let index = posts.firstIndex(where: { $0.id == updatedPost.id }) {
            print("FOUND INDEX")
            print("updatedPost", updatedPost.caption)
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
            print("DEBUG: Failed to bookmark restaurant with error \(error.localizedDescription)")
        }
    }
    
    func unbookmark(_ post: Post) async {
        do {
            try await PostService.shared.unbookmarkFromPost(post)
            
            // Update all posts with the same restaurant.id
            updateBookmarkStatus(for: post.restaurant.id, isBookmarked: false)
        } catch {
            print("DEBUG: Failed to unbookmark restaurant with error \(error.localizedDescription)")
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
              print("DEBUG: Failed to check if user bookmarked post with error \(error.localizedDescription)")
              return false
          }
      }
}
class ContentPrefetcher {
    static let shared = ContentPrefetcher()
    private let prefetchQueue = OperationQueue()
    private var currentPrefetchOperations: [String: Operation] = [:]

    private init() {
        prefetchQueue.maxConcurrentOperationCount = 3
    }

    func prefetchContent(for posts: [Post], currentIndex: Int) {
        // Cancel any existing operations
        cancelAllPrefetchOperations()

        // Ensure currentIndex is within bounds
        guard currentIndex >= 0 && currentIndex < posts.count else {
            print("Error: Current index out of bounds")
            return
        }

        // Determine the range of posts to prefetch
        let startIndex = currentIndex + 1
        let endIndex = min(startIndex + 5, posts.count - 1)

        // Ensure startIndex is less than or equal to endIndex
        guard startIndex <= endIndex else {
            print("No more posts to prefetch")
            return
        }

        for i in startIndex...endIndex {
            guard i < posts.count else {
                print("Warning: Attempted to access post beyond array bounds")
                break
            }

            let post = posts[i]
            let operation = BlockOperation { [weak self] in
                self?.prefetchPost(post)
            }
            currentPrefetchOperations[post.id] = operation
            prefetchQueue.addOperation(operation)
        }
    }

    private func prefetchPost(_ post: Post) {
        switch post.mediaType {
        case .video:
            VideoPrefetcher.shared.prefetchPosts([post])
        case .photo, .mixed:
            prefetchImages(for: post)
        case .written:
            // No media to prefetch for written posts
            break
        }

        prefetchProfileImages(for: post)
    }

    private func prefetchImages(for post: Post) {
        let urls = post.mixedMediaUrls?.compactMap { URL(string: $0.url) } ??
                   post.mediaUrls.compactMap { URL(string: $0) }
        
        if urls.isEmpty {
            print("Warning: No valid image URLs found for post \(post.id)")
            return
        }

        let prefetcher = ImagePrefetcher(urls: urls)
        prefetcher.start()
    }

    private func prefetchProfileImages(for post: Post) {
        if let userProfileImageURL = URL(string: post.user.profileImageUrl ?? "") {
            let prefetcher = ImagePrefetcher(urls: [userProfileImageURL])
            prefetcher.start()
        }

        if let restaurantProfileImageURL = URL(string: post.restaurant.profileImageUrl ?? "") {
            let prefetcher = ImagePrefetcher(urls: [restaurantProfileImageURL])
            prefetcher.start()
        }
    }

    func cancelAllPrefetchOperations() {
        prefetchQueue.cancelAllOperations()
        currentPrefetchOperations.removeAll()
    }

    func cancelPrefetchOperation(for postId: String) {
        if let operation = currentPrefetchOperations[postId] {
            operation.cancel()
            currentPrefetchOperations.removeValue(forKey: postId)
        }
    }
}

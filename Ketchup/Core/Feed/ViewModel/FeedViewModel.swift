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
    @Published var earlyPosts: [Post]
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
    @Published var selectedTab: FeedTab = .following {
        didSet {
            cancelExistingFetchAndStartNew()
        }
    }

    init(posts: [Post] = [], startingPostId: String = "", earlyPosts: [Post] = []) {
        self.posts = posts
        self.isContainedInTabBar = posts.isEmpty
        self.startingPostId = startingPostId
        self.earlyPosts = earlyPosts
    }

    func fetchInitialPosts(withFilters filters: [String: [Any]]? = nil) async throws {
        await MainActor.run {
            self.posts.removeAll()
            self.hasMorePosts = true
            self.filters = filters
        }
        
        if selectedTab == .following {
            await fetchFollowingUsers()
        }
        
        await fetchPosts(withFilters: filters, isInitialLoad: true)
    }

    private func cancelExistingFetchAndStartNew() {
        fetchTask?.cancel()
        fetchTask = Task {
            do {
                self.isLoading = true
                self.posts.removeAll()
                self.lastDocument = nil
                try await fetchInitialPosts(withFilters: self.filters)
            } catch {
                print("Error fetching posts: \(error)")
            }
            self.isLoading = false
        }
    }

    func fetchMorePosts() async {
        guard !isFetching else { return }
        isFetching = true
        await fetchPosts(withFilters: self.filters, isInitialLoad: false)
        isFetching = false
    }

    private func fetchFollowingUsers() async {
        do {
            let userIds = try await UserService.shared.fetchFollowingUserIds()
            
            // Ensure we're on the main thread when updating published properties
            await MainActor.run {
                self.followingUsers = userIds
                print("Following users count: \(self.followingUsers.count)")
            }
        } catch {
            print("Error fetching following users: \(error)")
            
            // Ensure we're on the main thread when updating published properties
            await MainActor.run {
                self.followingUsers = []
            }
        }
    }

    func fetchPosts(withFilters filters: [String: [Any]]? = nil, isInitialLoad: Bool = false) async {
        if Task.isCancelled { return }
        if !hasMorePosts {
            print("Doesn't have any more posts")
            return
        }

        do {
            var updatedFilters = filters ?? [:]
            updatedFilters["user.privateMode"] = [false]

            if isInitialLoad {
                lastDocument = nil
            }

            if selectedTab == .following && followingUsers.isEmpty {
                self.posts = []
                self.showEmptyView = true
                self.hasMorePosts = false
                return
            }

            let db = Firestore.firestore()
            var query: Query = db.collection("posts")

            for (key, value) in updatedFilters {
                query = query.whereField(key, in: value)
            }

            if selectedTab == .following {
                if followingUsers.isEmpty {
                    print("No following users, showing empty state")
                    await MainActor.run {
                        self.posts = []
                        self.showEmptyView = true
                        self.hasMorePosts = false
                    }
                    return
                }
                
                // Use a safe subset of following users
                let followingBatch = Array(followingUsers.prefix(30))
                print("Using \(followingBatch.count) following users for query")
                query = query.whereField("user.id", in: followingBatch)
            }

            query = query.order(by: "timestamp", descending: true)
                .limit(to: pageSize)

            if let lastDocument = lastDocument {
                query = query.start(afterDocument: lastDocument)
            }

            let snapshot = try await query.getDocuments()
            if Task.isCancelled { return }
            let newPosts = snapshot.documents.compactMap { try? $0.data(as: Post.self) }

            print("Fetched \(newPosts.count) new posts")

            if newPosts.isEmpty {
                self.hasMorePosts = false
            } else {
                // Use a temporary array to avoid direct mutation of published property
                var updatedPosts = self.posts
                updatedPosts.append(contentsOf: newPosts)
                self.posts = updatedPosts
                self.lastDocument = snapshot.documents.last
                self.hasMorePosts = newPosts.count >= self.pageSize
            }
            self.showEmptyView = self.posts.isEmpty
            await checkIfUserLikedPosts()
        } catch {
            print("DEBUG: Failed to fetch posts \(error.localizedDescription)")
        }
    }

    func updateCache(scrollPosition: String?) {
        guard !posts.isEmpty, let scrollPosition = scrollPosition else {
                print("Posts array is empty or scroll position is nil")
                return
            }

            guard let currentIndex = posts.firstIndex(where: { $0.id == scrollPosition }) else {
                print("Current index not found in posts array")
                return
            }

            print("Updating cache. Current index: \(currentIndex), Posts count: \(posts.count)")

            let startIndex = min(currentIndex + 1, posts.count - 1)
            let endIndex = min(currentIndex + 6, posts.count)

            guard startIndex < endIndex else {
                print("Invalid range: startIndex \(startIndex) is not less than endIndex \(endIndex)")
                return
            }

            let postsToPreload = Array(posts[startIndex..<endIndex])
            
            print("Preloading \(postsToPreload.count) posts")
        
        DispatchQueue.global().async {
            for post in postsToPreload {
                Task {
                    if post.mediaType == .video {
                        if let videoURL = post.mediaUrls.first, let url = URL(string: videoURL) {
                            print("Running prefetch for video")
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
        guard let currentPost = currentPost else {
            print("Error: No current post provided")
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

        print("Current index: \(currentIndex), Posts count: \(posts.count)")

        let thresholdIndex = max(0, posts.count - abs(fetchingThreshold))

        if currentIndex >= thresholdIndex && currentIndex > lastFetched {
            print("Fetching more posts")
            lastFetched = currentIndex

            Task {
                isLoadingMoreContent = true
                await fetchMorePosts()
                isLoadingMoreContent = false
            }
        } else {
            print("Not yet reached the threshold for fetching more posts")
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
}

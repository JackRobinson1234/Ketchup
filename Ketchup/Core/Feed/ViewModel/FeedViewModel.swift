//
//  FeedViewModel.swift
//  foodi
//
//  Created by Jack Robinson on 1/6/24.
//

import SwiftUI
import Kingfisher
import FirebaseFirestoreInternal
enum FeedType: String, CaseIterable {
    case discover = "Discover"
    case following = "Following"
}

@MainActor
class FeedViewModel: ObservableObject {
    @Published var feedViewOption: FeedViewOption = .grid
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
    private var filters: [String: [Any]]? = [:]
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
    let videoCoordinator = VideoPlayerCoordinator()
    
    
    
    init(posts: [Post] = [], startingPostId: String = "", earlyPosts: [Post] = []) {
        self.posts = posts
        self.isContainedInTabBar = posts.isEmpty
        self.startingPostId = startingPostId
        self.earlyPosts = earlyPosts
    }
    
    func fetchInitialPosts(withFilters filters: [String: [Any]]? = nil) async {
        hasMorePosts = true
        self.filters = filters
        isLoading = true
        await fetchPosts(withFilters: filters, isInitialLoad: true)
        isLoading = false
    }
    
    func combineEarlyPosts() {
        posts.insert(contentsOf: earlyPosts, at: 0)
        earlyPosts = []
    }
    func fetchMorePosts() async {
        guard !isFetching else { return }
        isFetching = true
        await fetchPosts(withFilters: self.filters, isInitialLoad: false)
        isFetching = false
    }
    
    /// fetches all posts from firebase and preloads the next 3 posts in the cache
    func fetchPosts(withFilters filters: [String: [Any]]? = nil, isInitialLoad: Bool = false) async {
        if !hasMorePosts{
            print("Doesn't have any more posts")
            return
        }
        do {
            var updatedFilters = filters ?? [:]
            updatedFilters["user.privateMode"] = [false]
            
            if isInitialLoad {
                posts.removeAll()
                lastDocument = nil
            }
            
            let (newPosts, lastDoc) = try await PostService.shared.fetchPosts(lastDocument: lastDocument, pageSize: pageSize, withFilters: updatedFilters)
            print("postsfetched")
            if newPosts.isEmpty || newPosts.count < self.pageSize {
                print("no more posts after this fetch")
                self.posts.append(contentsOf: newPosts)
                self.lastDocument = lastDoc
                self.hasMorePosts = false // No more posts are available.
            } else {
                self.posts.append(contentsOf: newPosts)
                self.lastDocument = lastDoc
            }
            self.showEmptyView = self.posts.isEmpty
            await checkIfUserLikedPosts()
        } catch {
            print("DEBUG: Failed to fetch posts \(error.localizedDescription)")
        }
    }
    
    // Add other methods as needed...
    
    /// updates the cache with the next 3 post videos saved
    func updateCache(scrollPosition: String?) {
        guard !posts.isEmpty else {
            print("Posts array is empty")
            return
        }
        
        guard let scrollPosition = scrollPosition else {
            print("Scroll position is nil")
            return
        }
        
        guard let currentIndex = posts.firstIndex(where: { $0.id == scrollPosition }) else {
            print("Current index not found in posts array")
            print("scroll position = \(scrollPosition)")
            return
        }
        
        // Ensure the range is valid
        let startIndex = currentIndex + 2
        let endIndex = min(currentIndex + 6, posts.count)
        
        guard startIndex < endIndex else {
            print("Invalid range: startIndex \(startIndex) is not less than endIndex \(endIndex)")
            return
        }
        
        let posts = self.posts
        DispatchQueue.global().async { [weak self] in
            guard let self = self else { return }
            let nextIndexes = Array(startIndex ..< endIndex)
            for index in nextIndexes {
                if index >= posts.count {
                    break
                }
                let post = posts[index]
                Task {
                    if post.mediaType == .video {
                        if let videoURL = post.mediaUrls.first, let url = URL(string: videoURL) {
                            if index == currentIndex + 1 {
                                // await self.videoCoordinator.configurePlayer(url: url, postId: post.id)
                            }
                            print("running prefetch")
                            self.videoCoordinator.prefetch(url: url, postId: post.id)
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

// MARK: - Likes

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
        for i in 0 ..< copy.count {
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
    
    
    /// Fetches more content when the scroll positon reaches the threshold posoton
    /// - Parameter currentPost: Current scroll position postID
    func loadMoreContentIfNeeded(currentPost: String?) async {
        guard let currentPost = currentPost, !isFetching else {
            print("error with currentPost")
            print("Either no current post, currently fetching, or no more posts to fetch.")
                    return }
        
        let thresholdIndex = posts.index(posts.endIndex, offsetBy: fetchingThreshold)
        let postPosition = posts.firstIndex(where: { $0.id == currentPost })
        
        
        if let postPosition, postPosition >= thresholdIndex && lastFetched <= postPosition {
            print("Fetching more posts")
            self.lastFetched = postPosition
            await fetchMorePosts()
            
            
        } else if let postPosition, lastFetched > postPosition {
            print("posts already been fetched from this index")
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
    // MARK: - Delete Post
    /// Deletes a post using PostService and removes it from the posts array
    /// - Parameter post: The post object to be deleted
    func deletePost(post: Post) async {
        do {
            // Delete the post using PostService
            try await PostService.shared.deletePost(post)
            
            // Remove the post from the posts array
            
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
            AuthService.shared.userSession?.stats.posts += 1
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

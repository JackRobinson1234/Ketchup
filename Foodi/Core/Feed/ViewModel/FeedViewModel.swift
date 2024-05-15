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
    @Published var posts = [Post]()
    @Published var showEmptyView = false
    @Published var currentlyPlayingPostID: String?
    @Binding var scrollPosition: String?
    var videoCoordinator = VideoPlayerCoordinator()
    private var currentFeedType: FeedType = .discover // default
    var isContainedInTabBar = true
    
    
    @Published var isLoading = false
    private var lastDocument: DocumentSnapshot?
    private var isFetching = false
    private let pageSize = 6
    private let fetchingThreshold = -3
    
    
    init( scrollPosition: Binding<String?> = .constant(""), posts: [Post] = []) {
        self.posts = posts
        self.isContainedInTabBar = posts.isEmpty
        videoCoordinator = VideoPlayerCoordinator()
        self._scrollPosition = scrollPosition
        
    }
    
    func fetchInitialPosts(withFilters filters: [String: [Any]]? = nil) async {
        isLoading = true
        await fetchPosts(withFilters: filters, isInitialLoad: true)
        isLoading = false
    }
    
    func fetchMorePosts(withFilters filters: [String: [Any]]? = nil) async {
        guard !isFetching else { return }
        isFetching = true
        await fetchPosts(withFilters: filters, isInitialLoad: false)
        isFetching = false
    }
    
    /// fetches all posts from firebase and preloads the next 3 posts in the cache
    func fetchPosts(withFilters filters: [String: [Any]]? = nil, isInitialLoad: Bool = false) async {
        do {

            var updatedFilters = filters ?? [:]
            updatedFilters["user.privateMode"] = [false]
            
            if isInitialLoad {
                posts.removeAll()
                lastDocument = nil
            }
            
            let (newPosts, lastDoc) = try await PostService.shared.fetchPosts(lastDocument: lastDocument, pageSize: pageSize, withFilters: updatedFilters)
            self.lastDocument = lastDoc
            self.posts.append(contentsOf: newPosts)
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
        // Starts at 2 posts ahead the current scroll position and prefetches the next 5 videos. Configures the next video in line for smoother scrolling.
        let posts = self.posts
        DispatchQueue.global().async { [weak self] in
            guard let self = self else {return}
            let nextIndexes = Array(currentIndex + 2 ..< min(currentIndex + 8, posts.count + 2))
            for index in nextIndexes {
                if index >= posts.count {
                    break
                }
                let post = posts[index]
                Task{
                    if post.mediaType == "video"{
                        if let videoURL = post.mediaUrls.first {
                            if index == currentIndex + 1 {
                                //await self.videoCoordinator.configurePlayer(url: URL(string: videoURL), postId: post.id)
                            }
                            print("running prefetch")
                            await self.videoCoordinator.prefetch(url: URL(string: videoURL), postId: post.id)
                        }
                        
                        ///Prefetches all photos
                    } else if post.mediaType == "photo" {
                        let prefetcher = ImagePrefetcher(urls: post.mediaUrls.compactMap { URL(string: $0) })
                        prefetcher.start()
                    }
                    
                    if let profileImageUrl = post.user.profileImageUrl,
                       let userProfileImageURL = URL(string: profileImageUrl) {
                        let prefetcher = ImagePrefetcher(urls: [userProfileImageURL])
                        prefetcher.start()
                    }
                    
                    if let profileImageURL = post.restaurant?.profileImageUrl,
                       let restaurantProfileImageURL = URL(string: profileImageURL) {
                        let prefetcher = ImagePrefetcher(urls: [restaurantProfileImageURL])
                        prefetcher.start()
                    }
                }
                
            }
        }
    }
    
    func setFeedType(_ feedType: FeedType) {
        currentFeedType = feedType
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
    func loadMoreContentIfNeeded(currentPost: String?) {
            guard let currentPost = currentPost, let lastFetchedDocumentID = lastFetchedDocumentID else { return }

            let thresholdIndex = posts.index(posts.endIndex, offsetBy: fetchingThreshold)
//            if posts.firstIndex(where: { $0.id == currentPost }) == thresholdIndex {
                
                    Task {
                        print("Fetching more posts")
                        await fetchMorePosts()
                    }
//                } else {
//                    print("Already fetched this batch")
//                }
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
}

//
//  FeedViewModel.swift
//  foodi
//
//  Created by Jack Robinson on 1/6/24.
//

import SwiftUI

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
    @Published var user = User(id: "", username: "", fullname: "", privateMode: true)
    
    var videoCoordinator = VideoPlayerCoordinator()
    
    private var currentFeedType: FeedType = .discover // default
    
    var isContainedInTabBar = true

    init( scrollPosition: Binding<String?> = .constant(""), posts: [Post] = []) {
        self.posts = posts
        self.isContainedInTabBar = posts.isEmpty
        videoCoordinator = VideoPlayerCoordinator()
        self._scrollPosition = scrollPosition


    }
    
    /// fetches all posts from firebase and preloads the next 3 posts in the cache
    func fetchPosts(withFilters filters: [String: [Any]]? = nil) async {
        do {
            var updatedFilters = filters ?? [:] // Create a mutable copy or use an empty dictionary if filters is nil
            // Append [user.privateMode: false] to the filters dictionary
            updatedFilters["user.privateMode"] = [false]

            posts.removeAll()
            switch currentFeedType {
            case .discover:
                posts = try await PostService.shared.fetchPosts(withFilters: updatedFilters)
            case .following:
                posts = try await PostService.shared.fetchFollowingPosts(withFilters: updatedFilters)
            }
            showEmptyView = posts.isEmpty
            await checkIfUserLikedPosts()
            updateCache(scrollPosition: posts.first?.id)
        } catch {
            print("DEBUG: Failed to fetch posts \(error.localizedDescription)")
        }
    }
    
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
        
        let posts = self.posts
        DispatchQueue.global().async { [weak self] in
            guard let self = self else {return}
            let nextIndexes = Array(currentIndex + 2 ..< min(currentIndex + 6, posts.count + 2))
            for index in nextIndexes {
                if index >= posts.count {
                    break
                }
                let post = posts[index]
                Task{
                    if post.mediaType == "video"{
                        if let videoURL = post.mediaUrls.first {
                            print("running prefetch")
                            await self.videoCoordinator.prefetch(url: URL(string: videoURL), postId: post.id)
                        }
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
}

extension FeedViewModel {
    func updateCurrentlyPlayingPostID(_ postID: String?) {
        self.currentlyPlayingPostID = postID
        }
}

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
    @Published var isLoading = false
    @Published var showEmptyView = false
    @Published var currentlyPlayingPostID: String?
    
    private var currentFeedType: FeedType = .discover // default
    
    private let postService: PostService
    var isContainedInTabBar = true

    init(postService: PostService, posts: [Post] = []) {
        self.postService = postService
        self.posts = posts
        self.isContainedInTabBar = posts.isEmpty
    }
    
    
    func fetchPosts() async {
        print("DEBUG: Fetching posts from feedviewmodel")
        isLoading = true
        
        do {
            posts.removeAll()
            switch currentFeedType {
            case .discover:
                print("DEBUG: went in fetch discover")
                posts = try await postService.fetchPosts()
            case .following:
                print("DEBUG: went in fetch following")
                posts = try await postService.fetchFollowingPosts()
            }
            posts.sort(by: { $0.timestamp.dateValue() > $1.timestamp.dateValue() })
    
            isLoading = false
            showEmptyView = posts.isEmpty
            await checkIfUserLikedPosts()
        } catch {
            isLoading = false
            print("DEBUG: Failed to fetch posts \(error.localizedDescription)")
        }
    }
    
    func refreshFeed() async {
        posts.removeAll()
        isLoading = true
        
        do {
            posts = try await postService.fetchPosts()
            posts.shuffle()
            isLoading = false
        } catch {
            isLoading = false
            print("DEBUG: Failed to refresh posts with error: \(error.localizedDescription)")
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
            try await postService.likePost(post)
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
            try await postService.unlikePost(post)
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
                let didLike = try await self.postService.checkIfUserLikedPost(post)
                
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

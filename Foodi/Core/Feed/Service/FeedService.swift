//
//  FeedService.swift
//  Foodi
//
//  Created by Jack Robinson on 2/1/24.
//

import Foundation

class FeedService {
    private var posts = [Post]()
    private let userService = UserService()
    
    func fetchPosts() async throws -> [Post] {
        self.posts = try await FirestoreConstants
            .PostsCollection
            .order(by: "timestamp", descending: true)
            .getDocuments(as: Post.self)
        
        await withThrowingTaskGroup(of: Void.self) { group in
            for post in posts {
                group.addTask { try await self.fetchPostUserData(post) }
            }
        }
        
        return posts
    }
    
    private func fetchPostUserData(_ post: Post) async throws {
        guard let index = posts.firstIndex(where: { $0.id == post.id }) else { return }
        
        let user = try await userService.fetchUser(withUid: post.ownerUid)
        posts[index].user = user
    }
}

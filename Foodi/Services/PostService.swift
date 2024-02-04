//
//  PostService.swift
//  Foodi
//
//  Created by Jack Robinson on 2/1/24.
//

import Foundation
import Firebase

class PostService {
    private var posts = [Post]()
    private let userService = UserService()
    
    
    func fetchPost(postId: String) async throws -> Post {
        return try await FirestoreConstants
            .PostsCollection
            .document(postId)
            .getDocument(as: Post.self)
    }
    
    func fetchUserPosts(user: User) async throws -> [Post] {
        var posts = try await FirestoreConstants
            .PostsCollection
            .whereField("ownerUid", isEqualTo: user.id)
            .getDocuments(as: Post.self)
        
        for i in 0 ..< posts.count {
            posts[i].user = user
        }
        return posts
    }
    
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

    

// MARK: - Likes

extension PostService {
    func likePost(_ post: Post) async throws {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        async let _ = try FirestoreConstants.PostsCollection.document(post.id).collection("post-likes").document(uid).setData([:])
        async let _ = try FirestoreConstants.PostsCollection.document(post.id).updateData(["likes": post.likes + 1])
        async let _ = try FirestoreConstants.UserCollection.document(uid).collection("user-likes").document(post.id).setData([:])
        
        NotificationManager.shared.uploadLikeNotification(toUid: post.ownerUid, post: post)
    }
    
    func unlikePost(_ post: Post) async throws {
        guard post.likes > 0 else { return }
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        async let _ = try FirestoreConstants.PostsCollection.document(post.id).collection("post-likes").document(uid).delete()
        async let _ = try FirestoreConstants.UserCollection.document(uid).collection("user-likes").document(post.id).delete()
        async let _ = try FirestoreConstants.PostsCollection.document(post.id).updateData(["likes": post.likes - 1])
        
        async let _ = NotificationManager.shared.deleteNotification(toUid: post.ownerUid, type: .like)
    }
    
    func checkIfUserLikedPost(_ post: Post) async throws -> Bool {
        guard let uid = Auth.auth().currentUser?.uid else { return false }
                
        let snapshot = try await FirestoreConstants.UserCollection.document(uid).collection("user-likes").document(post.id).getDocument()
        return snapshot.exists
    }
}

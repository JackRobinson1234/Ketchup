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
    private let restaurantService = RestaurantService()
    
    
    func fetchPost(postId: String) async throws -> Post {
        print("DEBUG: Ran fetchPost")
        let post = try await FirestoreConstants
                .PostsCollection
                .document(postId)
                .getDocument(as: Post.self)
        self.posts.append(post)
        return post
    }
    
    func fetchUserPosts(user: User) async throws -> [Post] {
        print("DEBUG: Ran fetchUserPost")
        self.posts = try await FirestoreConstants
            .PostsCollection
            .whereField("user.id", isEqualTo: user.id)
            .getDocuments(as: Post.self)
        /*
        await withThrowingTaskGroup(of: Void.self) { group in
            for post in posts {
                group.addTask { try await self.fetchPostUserData(post) }
                
            }
        }
        */
        return posts
    }
    
    func fetchRestaurantPosts(restaurant: Restaurant) async throws -> [Post] {
        print("DEBUG: Ran fetchRestaurantPosts")
        self.posts = try await FirestoreConstants
            .PostsCollection
            .whereField("restaurant.id", isEqualTo: restaurant.id)
            .getDocuments(as: Post.self)
        
        /*await withThrowingTaskGroup(of: Void.self) { group in
            for post in posts {
                group.addTask { try await self.fetchPostUserData(post) }
            }
        } */
        return posts
    }
    
    func fetchPosts() async throws -> [Post] {
        print("DEBUG: Ran fetchPosts()")
        self.posts = try await FirestoreConstants
            .PostsCollection
            .order(by: "timestamp", descending: true)
            .getDocuments(as: Post.self)
        
        /*await withThrowingTaskGroup(of: Void.self) { group in
            for post in posts {
                group.addTask { try await self.fetchPostUserData(post) }
                //group.addTask { try await self.fetchPostRestaurantData(post)}
            }
        }*/
        return posts
    }

    /*private func fetchPostUserData(_ post: Post) async throws {
        guard let index = posts.firstIndex(where: { $0.id == post.id }) else { return }
        
        let user = try await userService.fetchUser(withUid: post.ownerUid)
        posts[index].user = user
    }*/
}

    

// MARK: - Likes

extension PostService {
    func likePost(_ post: Post) async throws {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        async let _ = try FirestoreConstants.PostsCollection.document(post.id).collection("post-likes").document(uid).setData([:])
        async let _ = try FirestoreConstants.PostsCollection.document(post.id).updateData(["likes": FieldValue.increment(Int64(1))])
        async let _ = try FirestoreConstants.UserCollection.document(uid).collection("user-likes").document(post.id).setData([:])
        async let _ = try FirestoreConstants.UserCollection.document(uid).updateData(["stats.likes": FieldValue.increment(Int64(1))])
        
        NotificationManager.shared.uploadLikeNotification(toUid: post.user.id, post: post)
    }
    
    func unlikePost(_ post: Post) async throws {
        guard post.likes > 0 else { return }
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        async let _ = try FirestoreConstants.PostsCollection.document(post.id).collection("post-likes").document(uid).delete()
        async let _ = try FirestoreConstants.UserCollection.document(uid).collection("user-likes").document(post.id).delete()
        async let _ = try FirestoreConstants.PostsCollection.document(post.id).updateData(["likes": FieldValue.increment(Int64(-1))])
        async let _ = try FirestoreConstants.UserCollection.document(uid).updateData(["stats.likes": FieldValue.increment(Int64(-1))])
        
        async let _ = NotificationManager.shared.deleteNotification(toUid: post.user.id, type: .like)
    }
    
    func checkIfUserLikedPost(_ post: Post) async throws -> Bool {
        guard let uid = Auth.auth().currentUser?.uid else { return false }
                
        let snapshot = try await FirestoreConstants.UserCollection.document(uid).collection("user-likes").document(post.id).getDocument()
        return snapshot.exists
    }
    
    func fetchUserLikedPosts(user: User) async throws -> [Post] {        
        print("DEBUG: Ran fetchUserLikedPost")
        // Gets a snapshot of liked postIds
        let querySnapshot = try await FirestoreConstants
            .UserCollection
            .document(user.id)
            .collection("user-likes")
            .getDocuments()
        let postIds = querySnapshot.documents.map { $0.documentID }
        
        // fetches the posts fromt the PostIds
        await withThrowingTaskGroup(of: Void.self) { group in
            for postId in postIds {
                group.addTask { try await self.fetchLikedPostData(postId: postId, userId: user.id)}
            }
        }
       
        return posts
        }
    
    func fetchLikedPostData(postId: String, userId: String) async throws {
        print("DEBUG: Ran fetchLikedPostData")
        // fetches the posts given a postID
        let post = try await FirestoreConstants
                .PostsCollection
                .document(postId)
                .getDocument(as: Post.self)
        
        // doesnt show posts that arent the users
        if post.user.id != userId {
            self.posts.append(post)
        }
    }
        
}



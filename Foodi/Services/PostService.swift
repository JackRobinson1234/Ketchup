//
//  PostService.swift
//  Foodi
//
//  Created by Jack Robinson on 2/1/24.
//

import Foundation
import Firebase
import MapKit
import GeoFire

class PostService {
    private var posts = [Post]()
    private let userService = UserService()
    private let restaurantService = RestaurantService()
    
    
    func fetchPost(postId: String) async throws -> Post {
        //print("DEBUG: Ran fetchPost")
        let post = try await FirestoreConstants
                .PostsCollection
                .document(postId)
                .getDocument(as: Post.self)
        self.posts.append(post)
        return post
    }
    
    func fetchUserPosts(user: User) async throws -> [Post] {
        //print("DEBUG: Ran fetchUserPost")
        self.posts = try await FirestoreConstants
            .PostsCollection
            .whereField("user.id", isEqualTo: user.id)
            .getDocuments(as: Post.self)
        return posts
    }
    
    func fetchRestaurantPosts(restaurant: Restaurant) async throws -> [Post] {
        //print("DEBUG: Ran fetchRestaurantPosts")
        self.posts = try await FirestoreConstants
            .PostsCollection
            .whereField("restaurant.id", isEqualTo: restaurant.id)
            .getDocuments(as: Post.self)
        return posts
    }
    /// fetches all posts from firebase
    func fetchPosts(withFilters filters: [String: [Any]]? = nil) async throws -> [Post] {
        var query = FirestoreConstants.PostsCollection.order(by: "timestamp", descending: true)
        if let filters = filters, !filters.isEmpty {
            query = applyFilters(toQuery: query, filters: filters)
            }
            self.posts = try await query.getDocuments(as: Post.self)
        //print("DEBUG: posts fetched", posts.count)
            return posts
    }
    /// fetches all posts from user that the user is following
    ///
    ///
    /// TODO DEBUG THIS
    func fetchFollowingPosts(withFilters filters: [String: [Any]]? = nil) async throws -> [Post] {
        //print("DEBUG: Fetching Following Post")
        guard let currentUser = Auth.auth().currentUser else {
           throw NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
       }
       
       // Fetch the list of users that the current user is following
       let followingUsers = try await userService.fetchFollowingUsers()
        if followingUsers.isEmpty {return []}
       let followingUserIDs = followingUsers.map { $0.id }
       
       // Fetch posts from followingUsers using 'in' operator
        var query = FirestoreConstants.PostsCollection.order(by: "timestamp", descending: true).whereField("user.id", in: followingUserIDs)
        if let filters = filters, !filters.isEmpty {
            query = applyFilters(toQuery: query, filters: filters)
            }
           
       
        self.posts = try await query.getDocuments(as: Post.self)
        return posts
       }
    
    func applyFilters(toQuery query: Query, filters: [String: [Any]]) -> Query {
        var updatedQuery = query
        
        for (field, value) in filters {
            switch field {
            case "recipe.dietary":
                updatedQuery = updatedQuery.whereField(field, arrayContainsAny: value)
            case "recipe.cookingTime":
                if let cookingTime = value.first as? Int {
                    updatedQuery = updatedQuery.whereField(field, isLessThan: cookingTime)
                }
            case "location":
                let geoFire = GeoFireManager.shared.geoFire
                if let coordinates = value.first as? CLLocation {
                    let circleQuery = geoFire.query(at: coordinates, withRadius: 5.0)
                    var nearbyPostIDs: [String] = []
                    circleQuery.observe(.keyEntered, with: { (key, location) in
                        print("Key: \(key), Location: \(location.coordinate.latitude), \(location.coordinate.longitude)")
                        nearbyPostIDs.append(key)
                    })
                    if !nearbyPostIDs.isEmpty{
                        updatedQuery = updatedQuery.whereField("id", in: [nearbyPostIDs])
                    } else {
                        print("problem with fetching posts")
                    }
                }
            default:
                updatedQuery = updatedQuery.whereField(field, in: value)
            }
        }
        
        return updatedQuery
    }
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



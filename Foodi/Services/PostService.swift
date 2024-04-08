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
import FirebaseFirestoreInternal

class PostService {
    private var posts = [Post]()
    private let userService = UserService()
    private let restaurantService = RestaurantService()
    
    //MARK: fetchPost
    /// Fetches a singular post
    /// - Parameter postId: string id of the post that is to be fetched
    /// - Returns: post
    func fetchPost(postId: String) async throws -> Post {
        //print("DEBUG: Ran fetchPost")
        let post = try await FirestoreConstants
            .PostsCollection
            .document(postId)
            .getDocument(as: Post.self)
        self.posts.append(post)
        return post
    }
    
    
    //MARK: fetchUserPosts
    /// fetches all the posts for a user
    /// - Parameter user: user object that you want matching posts for
    /// - Returns: array of post objects
    func fetchUserPosts(user: User) async throws -> [Post] {
        //print("DEBUG: Ran fetchUserPost")
        self.posts = try await FirestoreConstants
            .PostsCollection
            .whereField("user.id", isEqualTo: user.id)
            .getDocuments(as: Post.self)
        return posts
    }
    
    
    //MARK: fetchRestaurantPosts
    /// fetches posts for a selected retaurant
    /// - Parameter restaurant: restaurant object that you want posts for
    /// - Returns: array of post objects
    func fetchRestaurantPosts(restaurant: Restaurant) async throws -> [Post] {
        //print("DEBUG: Ran fetchRestaurantPosts")
        self.posts = try await FirestoreConstants
            .PostsCollection
            .whereField("restaurant.id", isEqualTo: restaurant.id)
            .getDocuments(as: Post.self)
        return posts
    }
    
    //MARK: fetchPosts
    /// Fetches posts all posts from firebase, if filters are passed in it will only return posts that match those filters
    /// - Parameter filters: dictionary of filters with the field and an array of matching conditions ex. ["cuisine" : ["japanese", chinese], "price": ["$"]
    /// - Returns: array of posts (that match filters)
    func fetchPosts(withFilters filters: [String: [Any]]? = nil) async throws -> [Post] {
        var query = FirestoreConstants.PostsCollection.order(by: "timestamp", descending: true)
        if let filters = filters, !filters.isEmpty {
            query = await applyFilters(toQuery: query, filters: filters)
        }
        self.posts = try await query.getDocuments(as: Post.self)
        //print("DEBUG: posts fetched", posts.count)
        return posts
    }
    
    
    //MARK: fetchfollowingPosts
    /// Fetches posts of users that the user is following
    /// - Parameter filters: dictionary of f filters with the field and an array of matching conditions ex. ["cuisine" : ["japanese", chinese], "price": ["$"]
    /// - Returns: array of posts (that match filters)
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
            query = await applyFilters(toQuery: query, filters: filters)
        }
        self.posts = try await query.getDocuments(as: Post.self)
        return posts
    }
    
    
    //MARK: applyFilters
    /// Applies .whereFields to an existing query that are associated with the filters
    /// - Parameters:
    ///   - query: the existing query that needs to have filters applied to it
    ///   - filters: an map of filter categories and a corresponding array of values ex: ["cuisine": ["Chinese","Japanese"]
    /// - Returns: the original query with .whereFields attached to it
    func applyFilters(toQuery query: Query, filters: [String: [Any]]) async -> Query {
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
                if let coordinates = value.first as? CLLocation {
                    let modifiedQuery = await locationQuery(toQuery: updatedQuery, coordinates: coordinates)
                    updatedQuery = modifiedQuery
                    print("modified query", modifiedQuery)
                }
            default:
                updatedQuery = updatedQuery.whereField(field, in: value)
            }
        }
        print("final query", updatedQuery)
        return updatedQuery
    }
    
    
    
    //MARK: locationQuery
    /// Uses GeoFire to fetch locations. If no locations are found, will give a query that will not return any posts
    /// - Parameters:
    ///   - query: existing query to have another .whereField appended to it
    ///   - coordinates: coordinates of the center of the radius
    /// - Returns: an updated query that finds postIds based on returned postIds from GeoFire
    
    func locationQuery(toQuery query: Query, coordinates: CLLocation, radius: Double? = 10.0) async -> Query {
        let radius: Double = 10.0
        let geoFire = GeoFireManager.shared.geoFire
        let circleQuery = geoFire.query(at: coordinates, withRadius: radius)
        var nearbyPostIDs: [String] = []
        // Perform the asynchronous GeoFire query
        let circleQueryResult = await withCheckedContinuation { continuation in
            circleQuery.observe(.keyEntered, with: { (key, location) in
                print("Key: \(key), Location: \(location.coordinate.latitude), \(location.coordinate.longitude)")
                nearbyPostIDs.append(key)
            })
            circleQuery.observeReady {
                if !nearbyPostIDs.isEmpty {
                    let updatedQuery = query.whereField("restaurant.id", in: nearbyPostIDs)
                    continuation.resume(returning: updatedQuery)
                } else {
                    /// Sets the query to an object where no posts will be found
                    let updatedQuery = query.whereField("restaurant.id", in: ["No Post Found"])
                    continuation.resume(returning: updatedQuery)
                }
            }
        }
        // Return the modified query asynchronously
        return circleQueryResult
    }
}




extension PostService {
    // MARK: - likePost
    /// Likes a post from the current user
    /// - Parameter post: post object to be liked
    func likePost(_ post: Post) async throws {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        async let _ = try FirestoreConstants.PostsCollection.document(post.id).collection("post-likes").document(uid).setData([:])
        async let _ = try FirestoreConstants.PostsCollection.document(post.id).updateData(["likes": FieldValue.increment(Int64(1))])
        async let _ = try FirestoreConstants.UserCollection.document(uid).collection("user-likes").document(post.id).setData([:])
        async let _ = try FirestoreConstants.UserCollection.document(uid).updateData(["stats.likes": FieldValue.increment(Int64(1))])
        NotificationManager.shared.uploadLikeNotification(toUid: post.user.id, post: post)
    }
    
    
    // MARK: - unlikePost
    /// Unlikes a post from the current user
    /// - Parameter post: post object to be unliked
    func unlikePost(_ post: Post) async throws {
        guard post.likes > 0 else { return }
        guard let uid = Auth.auth().currentUser?.uid else { return }
        async let _ = try FirestoreConstants.PostsCollection.document(post.id).collection("post-likes").document(uid).delete()
        async let _ = try FirestoreConstants.UserCollection.document(uid).collection("user-likes").document(post.id).delete()
        async let _ = try FirestoreConstants.PostsCollection.document(post.id).updateData(["likes": FieldValue.increment(Int64(-1))])
        async let _ = try FirestoreConstants.UserCollection.document(uid).updateData(["stats.likes": FieldValue.increment(Int64(-1))])
        async let _ = NotificationManager.shared.deleteNotification(toUid: post.user.id, type: .like)
    }
    
    
    // MARK: - checkIfUserLikedPost
    /// Checks to see if the current user liked a post
    /// - Parameter post: post that is being checked
    /// - Returns: Boolean if the user liked the post
    func checkIfUserLikedPost(_ post: Post) async throws -> Bool {
        guard let uid = Auth.auth().currentUser?.uid else { return false }
        let snapshot = try await FirestoreConstants.UserCollection.document(uid).collection("user-likes").document(post.id).getDocument()
        return snapshot.exists
    }
    
    
    // MARK: - fetchUserLikedPosts
    /// Fetches all the posts that the user has liked
    /// - Parameter user: user to be checked
    /// - Returns: array of post objects that the user has liked
    func fetchUserLikedPosts(user: User) async throws -> [Post] {
        print("DEBUG: Ran fetchUserLikedPost")
        // Gets a snapshot of liked postIds
        let querySnapshot = try await FirestoreConstants
            .UserCollection
            .document(user.id)
            .collection("user-likes")
            .getDocuments()
        let postIds = querySnapshot.documents.map { $0.documentID }
        /// Fetches the posts from the PostIds
        posts = try await self.fetchPosts(withFilters: ["id": postIds])
        return posts
    }
}



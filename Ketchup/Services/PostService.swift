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
    static let shared = PostService() // Singleton instance
    private init() {}
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
        return post
    }
    
    
    //MARK: fetchUserPosts
    /// fetches all the posts for a user (ALSO Fetches REPOSTS)
    /// - Parameter user: user object that you want matching posts for
    /// - Returns: array of post objects
    func fetchUserPosts(user: User) async throws -> [Post] {
        let posts = try await FirestoreConstants
            .PostsCollection
            .whereField("user.id", isEqualTo: user.id)
            .getDocuments(as: Post.self)
        let repostQuerySnapshot = try await FirestoreConstants
            .UserCollection
            .document(user.id)
            .collection("user-reposts")
            .getDocuments()
        let repostPostIds = repostQuerySnapshot.documents.map { $0.documentID }
        var reposts: [Post] = []
        for postId in repostPostIds {
            do {
                var post = try await fetchPost(postId: postId)
                post.repost = true
                reposts.append(post)
            } catch {
                print("Error fetching repost with id \(postId): \(error.localizedDescription)")
            }
        }
        // Combine posts and reposts
        var combinedPosts = posts + reposts
        // Sort by timestamp
        combinedPosts.sort {
            if let timestamp1 = $0.timestamp, let timestamp2 = $1.timestamp {
                return timestamp1 > timestamp2
            } else {
                return $0.timestamp != nil
            }
        }
        
        return combinedPosts
    }
    
    
    //MARK: fetchRestaurantPosts
    /// fetches posts for a selected retaurant
    /// - Parameter restaurant: restaurant object that you want posts for
    /// - Returns: array of post objects
    func fetchRestaurantPosts(restaurant: Restaurant) async throws -> [Post] {
        //print("DEBUG: Ran fetchRestaurantPosts")
        let posts = try await FirestoreConstants
            .PostsCollection
            .whereField("restaurant.id", isEqualTo: restaurant.id)
            .whereField("user.privateMode", isEqualTo: false)
            .order(by: "timestamp", descending: true)
            .getDocuments(as: Post.self)
        return posts
    }
    
    
    
    func fetchPosts(lastDocument: DocumentSnapshot?, pageSize: Int, withFilters filters: [String: [Any]]? = nil) async throws -> ([Post], DocumentSnapshot?) {
        var query = FirestoreConstants.PostsCollection.order(by: "timestamp", descending: true).limit(to: pageSize)
        
        if let lastDocument = lastDocument {
            query = query.start(afterDocument: lastDocument)
        }
        
        if let filters = filters, !filters.isEmpty {
            if let locationFilters = filters["location"], let coordinates = locationFilters.first as? CLLocationCoordinate2D {
                let filteredPosts = try await fetchPostsWithLocation(filters: filters, center: coordinates, lastDocument: lastDocument)
                return filteredPosts
            }
            
            query = applyFilters(toQuery: query, filters: filters)
        }
        
        do {
            let snapshot = try await query.getDocuments()
            let posts = try snapshot.documents.compactMap { document in
                try? document.data(as: Post.self)
            }
            let lastDocumentSnapshot = snapshot.documents.last
            return (posts, lastDocumentSnapshot)
        } catch {
            // Handle or rethrow the error appropriately
            throw error
        }
    }
    
    //MARK: applyFilters
    /// Applies .whereFields to an existing query that are associated with the filters
    /// - Parameters:
    ///   - query: the existing query that needs to have filters applied to it
    ///   - filters: an map of filter categories and a corresponding array of values ex: ["cuisine": ["Chinese","Japanese"]
    /// - Returns: the original query with .whereFields attached to it
    ///
    ///
    /// Built a hacky solution where for cooking time posts, it fetches the matching postId, but for cooking it fetches the matching recipe Ids. Will probably want to look into a sql database for recipe storage.
    func applyFilters(toQuery query: Query, filters: [String: [Any]]) -> Query {
        print("applying filters", filters)
        var updatedQuery = query
        for (field, value) in filters {
            switch field {
            case "location":
                continue
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
    
    func fetchPostsWithLocation(filters: [String: [Any]], center: CLLocationCoordinate2D, radiusInM: Double = 1000, lastDocument: DocumentSnapshot? = nil, pageSize: Int = 10) async throws -> ([Post], DocumentSnapshot?) {
        let queryBounds = GFUtils.queryBounds(forLocation: center, withRadius: radiusInM)
        
        let queries = try await withThrowingTaskGroup(of: Query.self) { group -> [Query] in
            var queryList: [Query] = []
            
            for bound in queryBounds {
                group.addTask {
                    var query = self.applyFilters(toQuery: FirestoreConstants.PostsCollection
                        .order(by: "restaurant.geoHash")
                        .start(at: [bound.startValue])
                        .end(at: [bound.endValue]), filters: filters)
                        .limit(to: 75)
                    
                    if let lastDocument = lastDocument {
                        query = query.start(afterDocument: lastDocument)
                    }
                    return query.limit(to: pageSize)
                }
            }
            
            for try await query in group {
                queryList.append(query)
            }
            
            return queryList
        }
        
        // After all queries have been created and filtered, execute them
        do {
            let matchingDocs = try await withThrowingTaskGroup(of: [QueryDocumentSnapshot].self) { group -> [QueryDocumentSnapshot] in
                for query in queries {
                    group.addTask {
                        let snapshot = try await query.getDocuments()
                        return snapshot.documents
                    }
                }
                var matchingDocs = [QueryDocumentSnapshot]()
                for try await documents in group {
                    matchingDocs.append(contentsOf: documents)
                }
                return matchingDocs
            }
            
            let posts = matchingDocs.compactMap { document in
                try? document.data(as: Post.self)
            }
            
            let lastDocumentSnapshot = matchingDocs.last
            return (posts, lastDocumentSnapshot)
        } catch {
            throw error
        }
    }
}


extension PostService {
    // MARK: - likePost
    /// Likes a post from the current user
    /// - Parameter post: post object to be liked
    func likePost(_ post: Post) async throws {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        async let _ = try FirestoreConstants.PostsCollection.document(post.id).collection("post-likes").document(uid).setData([:])
        async let _ = try FirestoreConstants.UserCollection.document(uid).collection("user-likes").document(post.id).setData([:])
    }
    
    
    // MARK: - unlikePost
    /// Unlikes a post from the current user
    /// - Parameter post: post object to be unliked
    func unlikePost(_ post: Post) async throws {
        guard post.likes > 0 else { return }
        guard let uid = Auth.auth().currentUser?.uid else { return }
        async let _ = try FirestoreConstants.PostsCollection.document(post.id).collection("post-likes").document(uid).delete()
        async let _ = try FirestoreConstants.UserCollection.document(uid).collection("user-likes").document(post.id).delete()
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
        // Gets a snapshot of liked postIds
        let querySnapshot = try await FirestoreConstants
            .UserCollection
            .document(user.id)
            .collection("user-likes")
            .getDocuments()
        let postIds = querySnapshot.documents.map { $0.documentID }
        var likedPosts: [Post] = []
        /// Fetches the posts from the PostIds
        for postId in postIds {
            do {
                let post = try await self.fetchPost(postId: postId)
                likedPosts.append(post)
            } catch {
                print("Error fetching post with id \(postId): \(error.localizedDescription)")
            }
        }
        return likedPosts
    }
    
    //MARK: deletePost
    func deletePost(_ post: Post) async throws  {
        do {
            try await FirestoreConstants.PostsCollection.document(post.id).delete()
            print("Post deleted successfully")
           
        } catch {
            print("Error deleting post: \(error.localizedDescription)")
            
        }
    }
}

extension PostService {
    // MARK: - repostPost
    /// Reposts a post for the current user
    /// - Parameter post: post object to be reposted
    func repostPost(_ post: Post) async throws {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        // Add user ID to the post's reposts subcollection
        
        try await FirestoreConstants.PostsCollection
            .document(post.id)
            .collection("post-reposts")
            .document(uid)
            .setData(["timestamp": Timestamp(date: Date())])
        
        // Optionally, add the post ID to the user's reposts subcollection
        try await FirestoreConstants.UserCollection
            .document(uid)
            .collection("user-reposts")
            .document(post.id)
            .setData(["timestamp": Timestamp(date: Date())])
    }
    func removeRepost(_ post: Post) async throws {
           guard let uid = Auth.auth().currentUser?.uid else { return }
           
           // Remove user ID from the post's reposts subcollection
           try await FirestoreConstants.PostsCollection
               .document(post.id)
               .collection("post-reposts")
               .document(uid)
               .delete()
           
           // Optionally, remove the post ID from the user's reposts subcollection
           try await FirestoreConstants.UserCollection
               .document(uid)
               .collection("user-reposts")
               .document(post.id)
               .delete()
       }
    func checkIfUserReposted(_ post: Post) async throws -> Bool {
        guard let uid = Auth.auth().currentUser?.uid else { return false }
        let snapshot = try await FirestoreConstants.UserCollection.document(uid).collection("user-reposts").document(post.id).getDocument()
        return snapshot.exists
    }
}

extension PostService {
    // MARK: - bookmarkRestaurant
    /// Bookmarks a restaurant for the current user
    /// - Parameter post: post object containing the restaurant to be bookmarked
    func bookmarkRestaurant(from post: Post) async throws {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        let db = Firestore.firestore()
        let batch = db.batch()
        
        // Create a bookmark document in the restaurant's post-bookmarks collection
        let restaurantBookmarkRef = FirestoreConstants.RestaurantCollection
            .document(post.restaurant.id)
            .collection("user-bookmarks")
            .document(uid)
        
        let bookmark = [
            "userId": uid,
            "timestamp": Timestamp()
        ] as [String : Any]
        
        batch.setData(bookmark, forDocument: restaurantBookmarkRef)
        
        // Create a bookmark document in the post's post-bookmarks collection
        let postBookmarkRef = FirestoreConstants.PostsCollection
            .document(post.id)
            .collection("post-bookmarks")
            .document(uid)
        
        batch.setData(bookmark, forDocument: postBookmarkRef)
       
        // Add the bookmark to the user's bookmarks collection
        let userBookmarkRef = FirestoreConstants.UserCollection
            .document(uid)
            .collection("user-bookmarks")
            .document(post.restaurant.id)
        
        let userBookmark = Bookmark(
            id: post.restaurant.id,
            restaurantName: post.restaurant.name,
            restaurantCity: post.restaurant.city,
            restaurantState: post.restaurant.state,
            geoPoint: post.restaurant.geoPoint,
            timestamp: Timestamp(date: Date()),
            image: post.restaurant.profileImageUrl
        )
        
        try batch.setData(from: userBookmark, forDocument: userBookmarkRef)
        
        // Commit the batch
        try await batch.commit()
    }

    func unbookmarkFromPost(_ post: Post) async throws {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        let db = Firestore.firestore()
        let batch = db.batch()
        
        // Remove the bookmark document from the restaurant's post-bookmarks collection
        let restaurantBookmarkRef = FirestoreConstants.RestaurantCollection
            .document(post.restaurant.id)
            .collection("user-bookmarks")
            .document(uid)
        
        batch.deleteDocument(restaurantBookmarkRef)
        
        // Remove the bookmark document from the post's post-bookmarks collection
        let postBookmarkRef = FirestoreConstants.PostsCollection
            .document(post.id)
            .collection("post-bookmarks")
            .document(uid)
        
        batch.deleteDocument(postBookmarkRef)
        
        
        // Remove the bookmark from the user's bookmarks collection
        let userBookmarkRef = FirestoreConstants.UserCollection
            .document(uid)
            .collection("user-bookmarks")
            .document(post.restaurant.id)
        
        batch.deleteDocument(userBookmarkRef)
        
        // Commit the batch
        try await batch.commit()
    }
    func fetchFriendsPosts(for restaurant: Restaurant, friendIds: [String]) async throws -> (
        posts: [Post],
        overallAverageRating: Double?,
        averageFoodRating: Double?,
        averageServiceRating: Double?,
        averageAtmosphereRating: Double?,
        averageValueRating: Double?
    ) {
        guard !friendIds.isEmpty else {
            print("Error: friendIds array is empty.")
            return ([], nil, nil, nil, nil, nil) // Return empty array and nil ratings
        }

        let batchSize = 30
        var allPosts: [Post] = []
        var totalOverallRating: Double = 0.0
        var totalFoodRating: Double = 0.0
        var totalServiceRating: Double = 0.0
        var totalAtmosphereRating: Double = 0.0
        var totalValueRating: Double = 0.0
        
        var totalPostsWithRatings: Int = 0
        var totalPostsWithFoodRating: Int = 0
        var totalPostsWithServiceRating: Int = 0
        var totalPostsWithAtmosphereRating: Int = 0
        var totalPostsWithValueRating: Int = 0

        for i in stride(from: 0, to: friendIds.count, by: batchSize) {
            let end = min(i + batchSize, friendIds.count)
            let batch = Array(friendIds[i..<end])

            let posts = try await FirestoreConstants.PostsCollection
                .whereField("restaurant.id", isEqualTo: restaurant.id)
                .whereField("user.id", in: batch)
                .order(by: "timestamp", descending: true)
                .getDocuments(as: Post.self)

            for post in posts {
                if let overallRating = calculateOverallRating(for: post), overallRating > 0.0 {
                    totalOverallRating += overallRating
                    totalPostsWithRatings += 1
                }
                if let foodRating = post.foodRating, foodRating > 0.0 {
                    totalFoodRating += foodRating
                    totalPostsWithFoodRating += 1
                }
                if let serviceRating = post.serviceRating, serviceRating > 0.0 {
                    totalServiceRating += serviceRating
                    totalPostsWithServiceRating += 1
                }
                if let atmosphereRating = post.atmosphereRating, atmosphereRating > 0.0 {
                    totalAtmosphereRating += atmosphereRating
                    totalPostsWithAtmosphereRating += 1
                }
                if let valueRating = post.valueRating, valueRating > 0.0 {
                    totalValueRating += valueRating
                    totalPostsWithValueRating += 1
                }
            }

            allPosts.append(contentsOf: posts)
        }

        // Sort all posts by timestamp descending
        allPosts.sort { $0.timestamp ?? Timestamp() > $1.timestamp ?? Timestamp() }

        // Calculate the overall average rating across all posts
        let overallAverageRating: Double? = totalPostsWithRatings > 0 ? totalOverallRating / Double(totalPostsWithRatings) : nil
        let averageFoodRating: Double? = totalPostsWithFoodRating > 0 ? totalFoodRating / Double(totalPostsWithFoodRating) : nil
        let averageServiceRating: Double? = totalPostsWithServiceRating > 0 ? totalServiceRating / Double(totalPostsWithServiceRating) : nil
        let averageAtmosphereRating: Double? = totalPostsWithAtmosphereRating > 0 ? totalAtmosphereRating / Double(totalPostsWithAtmosphereRating) : nil
        let averageValueRating: Double? = totalPostsWithValueRating > 0 ? totalValueRating / Double(totalPostsWithValueRating) : nil

        return (allPosts, overallAverageRating, averageFoodRating, averageServiceRating, averageAtmosphereRating, averageValueRating)
    }
    private func calculateOverallRating(for post: Post) -> Double? {
        var ratings: [Double] = []
        if let foodRating = post.foodRating, foodRating > 0 { ratings.append(foodRating) }
        if let atmosphereRating = post.atmosphereRating, atmosphereRating > 0 { ratings.append(atmosphereRating) }
        if let valueRating = post.valueRating, valueRating > 0 { ratings.append(valueRating) }
        if let serviceRating = post.serviceRating, serviceRating > 0 { ratings.append(serviceRating) }

        guard !ratings.isEmpty else {
            return nil
        }

        let average = ratings.reduce(0, +) / Double(ratings.count)
        return average
    }
    func fetchRemainingRestaurantPosts(for restaurant: Restaurant, excluding friendIds: [String]) async throws -> [Post] {
        // Fetch all posts related to the restaurant
        var posts: [Post] = try await FirestoreConstants.PostsCollection
            .whereField("restaurant.id", isEqualTo: restaurant.id)
            .whereField("user.privateMode", isEqualTo: false)
            .order(by: "timestamp", descending: true)
            .getDocuments(as: Post.self)
        
        // Filter out posts from users in the friendIds list
        if !friendIds.isEmpty {
            posts = posts.filter { !friendIds.contains($0.user.id) }
        }
        
        return posts
    }
    
    // MARK: - unbookmarkRestaurant
    /// Removes a restaurant from the user's bookmarks
    /// - Parameter restaurantId: ID of the restaurant to be unbookmarked
//    func unbookmarkRestaurant(restaurantId: String) async throws {
//        guard let uid = Auth.auth().currentUser?.uid else { return }
//        
//        do {
//            try await FirestoreConstants.UserCollection
//                .document(uid)
//                .collection("user-bookmarks")
//                .document(restaurantId)
//                .delete()
//        } catch {
//            print("Error unbookmarking restaurant: \(error.localizedDescription)")
//            throw error
//        }
//    }
    
    // MARK: - checkIfUserBookmarkedRestaurant
    /// Checks if the current user has bookmarked a specific restaurant
    /// - Parameter restaurantId: ID of the restaurant to check for bookmark
    /// - Returns: Boolean indicating if the restaurant is bookmarked
    func checkIfUserBookmarkedRestaurant(restaurantId: String) async throws -> Bool {
        guard let uid = Auth.auth().currentUser?.uid else { return false }
        
        do {
            let snapshot = try await FirestoreConstants.UserCollection
                .document(uid)
                .collection("user-bookmarks")
                .document(restaurantId)
                .getDocument()
            
            return snapshot.exists
        } catch {
            print("Error checking bookmark status: \(error.localizedDescription)")
            throw error
        }
    }
}

//
//  RestaurantService.swift
//  Foodi
//
//  Created by Jack Robinson on 2/1/24.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore
import MapKit
import GeoFire
import GeohashKit

class RestaurantService {
    static let shared = RestaurantService() // Singleton instance
    private init() {}
    
    //MARK: fetchRestaurant
    /// Fetches a single restaurant given an ID
    /// - Parameter id: String of an ID for a restaurant
    /// - Returns: RestaurantObject
    func fetchRestaurant(withId id: String) async throws -> Restaurant {
        ////print("DEBUG: Fetching restaurant with ID: \(id)")
        do {
            let documentSnapshot = try await FirestoreConstants.RestaurantCollection.document(id).getDocument()
            ////print("DEBUG: Successfully fetched document")
            // Print raw data
            if let data = documentSnapshot.data() {
                ////print("DEBUG: Raw document data:")
                ////print(data)
            } else {
                ////print("DEBUG: Document data is nil")
            }
            
            // Attempt to decode
            do {
                let restaurant = try documentSnapshot.data(as: Restaurant.self)
                ////print("DEBUG: Successfully decoded Restaurant")
                ////print("DEBUG: Restaurant name: \(restaurant.name)")
                ////print("DEBUG: Restaurant additionalInfo: \(String(describing: restaurant.additionalInfo))")
                return restaurant
            } catch {
                ////print("DEBUG: Failed to decode Restaurant")
                ////print("DEBUG: Decoding error: \(error)")
                
                // If it's a DecodingError, print more details
                //                if let decodingError = error as? DecodingError {
                //                    switch decodingError {
                //                    case .keyNotFound(let key, let context):
                //                        ////print("DEBUG: Key '\(key)' not found: \(context.debugDescription)")
                //                    case .valueNotFound(let type, let context):
                //                        ////print("DEBUG: Value of type '\(type)' not found: \(context.debugDescription)")
                //                    case .typeMismatch(let type, let context):
                //                        ////print("DEBUG: Type mismatch for type '\(type)': \(context.debugDescription)")
                //                    case .dataCorrupted(let context):
                //                        ////print("DEBUG: Data corrupted: \(context.debugDescription)")
                //                    @unknown default:
                //                        ////print("DEBUG: Unknown decoding error")
                //                    }
                //                }
                
                throw error
            }
        } catch {
            ////print("DEBUG: Failed to fetch document")
            ////print("DEBUG: Fetch error: \(error)")
            throw error
        }
    }
    //MARK: fetchRestaurants
    /// Fetches an array of restaurants that match the provided filters
    /// - Parameter filters: dictionary of filters with the field and an array of matching conditions ex. ["cuisine" : ["japanese", chinese], "price": ["$"]
    /// - Returns: array of restaurants
    func fetchRestaurants(withFilters filters: [String: [Any]]? = nil, limit: Int = 1000) async throws -> [Restaurant] {
        var query = FirestoreConstants.RestaurantCollection.order(by: "id", descending: true)
        ////print("DEBUG: Initial query created with descending order by id")
        
        // Fetch a sample of restaurants to see if any exist in the collection
        let sampleSnapshot = try await query.limit(to: 1).getDocuments()
        let sampleRestaurants = sampleSnapshot.documents.compactMap { document -> Restaurant? in
            do {
                return try document.data(as: Restaurant.self)
            } catch {
                ////print("DEBUG: Error decoding sample restaurant document:", document.documentID, error)
                return nil
            }
        }
        ////print("DEBUG: Sample restaurants fetched to check existence:", sampleRestaurants.count)
        
        if let filters = filters, !filters.isEmpty {
            ////print("DEBUG: Filters are provided:", filters)
            
            if let locationFilters = filters["location"],
               let coordinates = locationFilters.first as? CLLocationCoordinate2D,
               let radiusInM = locationFilters[1] as? Double {
                ////print("DEBUG: Location filters found - Coordinates:", coordinates, "Radius (m):", radiusInM)
                let restaurants = try await fetchRestaurantsWithLocation(filters: filters, center: coordinates, radiusInM: radiusInM, limit: limit)
                ////print("DEBUG: Restaurants fetched with location filters:", restaurants.count)
                if restaurants.isEmpty {
                    ////print("DEBUG: No restaurants found within the location filters")
                } else {
                    ////print("DEBUG: Restaurants within location filters:")
                }
                return restaurants
            } else {
                ////print("DEBUG: No valid location filters found in filters")
            }
            
            query = applyFilters(toQuery: query, filters: filters)
            ////print("DEBUG: Query after applying filters:", query)
        } else {
            ////print("DEBUG: No filters provided or filters are empty")
        }
        
        var allRestaurants: [Restaurant] = []
        var lastDocument: DocumentSnapshot?
        
        repeat {
            var paginatedQuery = query
            if let lastDocument = lastDocument {
                paginatedQuery = paginatedQuery.start(afterDocument: lastDocument)
            }
            paginatedQuery = paginatedQuery.limit(to: limit)
            let snapshot = try await paginatedQuery.getDocuments()
            let restaurants = snapshot.documents.compactMap { document -> Restaurant? in
                do {
                    return try document.data(as: Restaurant.self)
                } catch {
                    ////print("DEBUG: Error decoding restaurant document:", document.documentID, error)
                    return nil
                }
            }
            allRestaurants.append(contentsOf: restaurants)
            lastDocument = snapshot.documents.last
            ////print("DEBUG: Fetched \(restaurants.count) restaurants, total so far: \(allRestaurants.count)")
        } while lastDocument != nil
        
        ////print("DEBUG: Total restaurants fetched:", allRestaurants.count)
        if allRestaurants.isEmpty {
            ////print("DEBUG: No restaurants found in the collection")
        } else {
            ////print("DEBUG: Fetched restaurants:")
        }
        return allRestaurants
    }
    
    
    //MARK: applyFilters
    /// Applies .whereFields to an existing query that are associated with the filters
    /// - Parameters:
    ///   - query: the existing query that needs to have filters applied to it
    ///   - filters: an map of filter categories and a corresponding array of values ex: ["cuisine": ["Chinese","Japanese"]
    /// - Returns: the original query with .whereFields attached to it
    func applyFilters(toQuery query: Query, filters: [String: [Any]], limit: Int = 0) -> Query {
        var updatedQuery = query
        for (field, value) in filters {
            switch field {
            case "location":
                continue
            default:
                updatedQuery = updatedQuery.whereField(field, in: value)
            }
        }
        if limit > 0 {
            updatedQuery = updatedQuery.limit(to: limit)
        }
        return updatedQuery
    }
    
    
    /// Fetches restaurants that fall within the "radiusInM" range and applies any additional filters selected to that query
    /// - Parameters:
    ///   - filters: an map of filter categories and a corresponding array of values ex: ["cuisine": ["Chinese","Japanese"]
    ///   - center: CLLocationCoordinate2D that represents the center point of the query
    /// - Returns: Array of restaurants that match all of the filters
    func fetchRestaurantsWithLocation(filters: [String: [Any]], center: CLLocationCoordinate2D, radiusInM: Double = 500, limit: Int = 0) async throws -> [Restaurant] {
        let queryBounds = GFUtils.queryBounds(forLocation: center,
                                              withRadius: radiusInM)
        let queries = queryBounds.map { bound -> Query in
            return applyFilters(toQuery: FirestoreConstants.RestaurantCollection
                .order(by: "geoHash")
                .start(at: [bound.startValue])
                .end(at: [bound.endValue]), filters: filters, limit: limit)
        }
        // After all callbacks have executed, matchingDocs contains the result. Note that this code executes all queries serially, which may not be optimal for performance.
        do {
            let matchingDocs = try await withThrowingTaskGroup(of: [Restaurant].self) { group -> [Restaurant] in
                for query in queries {
                    group.addTask {
                        let snapshot = try await query.getDocuments()
                        return snapshot.documents.compactMap { document in
                            try? document.data(as: Restaurant.self)
                        }
                    }
                }
                var matchingDocs = [Restaurant]()
                for try await documents in group {
                    matchingDocs.append(contentsOf: documents)
                }
                return matchingDocs
            }
            return matchingDocs
        } catch {
            throw error
        }
    }
    
    func requestRestaurant(requestRestaurant: RestaurantRequest) async throws {
        let ref = FirestoreConstants.RequestRestaurantCollection.document(requestRestaurant.id)
        guard let requestData = try? Firestore.Encoder().encode(requestRestaurant) else {
            ////print("not encoding request right")
            return
        }
        do {
            try await ref.setData(requestData)
        } catch {
            ////print("uploading a request failed")
        }
    }
    func createBookmark(for restaurant: Restaurant) async throws {
        guard let uid = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "RestaurantService", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        let db = Firestore.firestore()
        let batch = db.batch()
        
        let bookmark = Bookmark(
            id: restaurant.id,
            restaurantName: restaurant.name,
            restaurantCity: restaurant.city,
            restaurantState: restaurant.state,
            geoPoint: restaurant.geoPoint,
            timestamp: Timestamp(),
            image: restaurant.profileImageUrl
        )
        
        // User's bookmark
        let userBookmarkRef = FirestoreConstants.UserCollection
            .document(uid)
            .collection("user-bookmarks")
            .document(restaurant.id)
        
        try batch.setData(from: bookmark, forDocument: userBookmarkRef)
        
        // Restaurant's bookmark
        let restaurantBookmarkRef = FirestoreConstants.RestaurantCollection
            .document(restaurant.id)
            .collection("user-bookmarks")
            .document(uid)
        
        let restaurantBookmarkData = [
            "userId": uid,
            "timestamp": Timestamp()
        ] as [String : Any]
        
        batch.setData(restaurantBookmarkData, forDocument: restaurantBookmarkRef)
        
        do {
            try await batch.commit()
            ////print("Bookmark created successfully for restaurant: \(restaurant.name)")
        } catch {
            ////print("Error creating bookmark: \(error.localizedDescription)")
            throw error
        }
    }
    
    // MARK: - removeBookmark
    /// Removes a bookmark for a restaurant
    /// - Parameter restaurantId: The ID of the restaurant to unbookmark
    /// - Throws: An error if the bookmark removal fails
    func removeBookmark(for restaurantId: String) async throws {
        guard let uid = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "RestaurantService", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        let db = Firestore.firestore()
        let batch = db.batch()
        
        // Remove from user's bookmarks
        let userBookmarkRef = FirestoreConstants.UserCollection
            .document(uid)
            .collection("user-bookmarks")
            .document(restaurantId)
        
        batch.deleteDocument(userBookmarkRef)
        
        // Remove from restaurant's bookmarks
        let restaurantBookmarkRef = FirestoreConstants.RestaurantCollection
            .document(restaurantId)
            .collection("restaurant-bookmarks")
            .document(uid)
        
        batch.deleteDocument(restaurantBookmarkRef)
        
        do {
            try await batch.commit()
            ////print("Bookmark removed successfully for restaurant ID: \(restaurantId)")
        } catch {
            ////print("Error removing bookmark: \(error.localizedDescription)")
            throw error
        }
    }
    
    // MARK: - isBookmarked
    /// Checks if a restaurant is bookmarked by the current user
    /// - Parameter restaurantId: The ID of the restaurant to check
    /// - Returns: A boolean indicating whether the restaurant is bookmarked
    /// - Throws: An error if the check fails
    func isBookmarked(_ restaurantId: String) async throws -> Bool {
        guard let uid = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "RestaurantService", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        let bookmarkRef = FirestoreConstants.UserCollection
            .document(uid)
            .collection("user-bookmarks")
            .document(restaurantId)
        
        let snapshot = try await bookmarkRef.getDocument()
        return snapshot.exists
    }
    func fetchRestaurant(byName name: String, nearGeoHash: String) async throws -> Restaurant? {
        
        let geohashPrefix = String(nearGeoHash.prefix(4)) // Using first 5 characters of the geohash
        let geohashNeighbors = geohashNeighborsOfNeighbors(geohash: geohashPrefix)
        let query = FirestoreConstants.RestaurantCollection
            .whereField("name", isEqualTo: name)
            .whereField("truncatedGeohash", in: geohashNeighbors)
            .limit(to: 1)
        let snapshot = try await query.getDocuments()
        return try? snapshot.documents.first?.data(as: Restaurant.self)
    }
    private func geohashNeighbors(geohash: String) -> [String] {
        if let geoHash = Geohash(geohash: geohash) {
            let neighbors = geoHash.neighbors
            if let neighbors {
                let neighborGeohashes = neighbors.all.map { $0.geohash }
                //print([geohash] + neighborGeohashes)
                return [geohash] + neighborGeohashes
            }
        }
        return [geohash]
    }
    private func geohashNeighborsOfNeighbors(geohash: String) -> [String] {
        var resultSet: Set<String> = [geohash]  // Start with the original geohash
        
        // Get immediate neighbors of the original geohash
        if let geoHash = Geohash(geohash: geohash) {
            if let immediateNeighbors = geoHash.neighbors?.all.map({ $0.geohash }) {
                resultSet.formUnion(immediateNeighbors)  // Add immediate neighbors to the set
                
                // For each immediate neighbor, get its immediate neighbors (neighbors of neighbors)
                for neighborGeohash in immediateNeighbors {
                    if let neighborGeoHash = Geohash(geohash: neighborGeohash) {
                        if let neighborNeighbors = neighborGeoHash.neighbors?.all.map({ $0.geohash }) {
                            resultSet.formUnion(neighborNeighbors)  // Add neighbors of neighbors to the set
                        }
                    }
                }
            }
        }
        
        return Array(resultSet)
    }
    func fetchRestaurantsServingMeal(mealTime: String, location: CLLocationCoordinate2D, lastDocument: DocumentSnapshot? = nil, limit: Int = 5) async throws -> ([Restaurant], DocumentSnapshot?) {
        let db = Firestore.firestore()
        let geohash = GFUtils.geoHash(forLocation: location)
        let truncatedGeohash5 = String(geohash.prefix(5))
        let geohashNeighbors = geohashNeighbors(geohash: truncatedGeohash5)
        
        var query = db.collection("restaurants")
            .whereField("truncatedGeohash5", in: geohashNeighbors)
            .whereField("servesMeals", arrayContains: mealTime.capitalized)
            .order(by: "stats.postCount", descending: true)
            .limit(to: limit)
        
        if let lastDocument = lastDocument {
            query = query.start(afterDocument: lastDocument)
        }
        
        let snapshot = try await query.getDocuments()
        let restaurants = snapshot.documents.compactMap { document -> Restaurant? in
            try? document.data(as: Restaurant.self)
        }
        let newLastDocument = snapshot.documents.last
        return (restaurants, newLastDocument)
    }
    func fetchRestaurantsForCuisine(
        cuisine: String,
        location: CLLocationCoordinate2D,
        lastDocument: DocumentSnapshot? = nil,
        limit: Int = 5
    ) async throws -> ([Restaurant], DocumentSnapshot?) {
        
        let db = Firestore.firestore()
        let geohash = GFUtils.geoHash(forLocation: location)
        let truncatedGeohash5 = String(geohash.prefix(5))
        let geohashNeighbors = geohashNeighborsOfNeighbors(geohash: truncatedGeohash5)
        print(cuisine, "cuisine")
        var query = db.collection("restaurants")
            .whereField("truncatedGeohash5", in: geohashNeighbors)
            .whereField("macrocategory", isEqualTo: cuisine)
            .order(by: "stats.postCount", descending: true)
            .limit(to: limit)
        
        if let lastDocument = lastDocument {
            query = query.start(afterDocument: lastDocument)
        }
        
        let snapshot = try await query.getDocuments()
        let restaurants = snapshot.documents.compactMap { document -> Restaurant? in
            try? document.data(as: Restaurant.self)
        }
        print(restaurants, "restaurants")
        let newLastDocument = snapshot.documents.last
        return (restaurants, newLastDocument)
    }
    func fetchTopRestaurants(
        location: CLLocationCoordinate2D,
        lastDocument: DocumentSnapshot? = nil,
        limit: Int = 30
    ) async throws -> ([Restaurant], DocumentSnapshot?) {
        let db = Firestore.firestore()
        let geohash = GFUtils.geoHash(forLocation: location)
        let truncatedGeohash5 = String(geohash.prefix(5))
        let geohashNeighbors = geohashNeighborsOfNeighbors(geohash: truncatedGeohash5)

        var query = db.collection("mapClusters")
            .whereField("truncatedGeoHash", in: geohashNeighbors)

        if let lastDocument = lastDocument {
            query = query.start(afterDocument: lastDocument)
        }

        let snapshot = try await query.getDocuments()
        var allRestaurants: [Restaurant] = []

        for document in snapshot.documents {
            if let clusterData = try? document.data(as: Cluster.self) {
                let clusterRestaurants = clusterData.restaurants.sorted { $0.postCount ?? 0 > $1.postCount ?? 0 }
                let convertedRestaurants = clusterRestaurants.compactMap { convertToRestaurant($0) }
                allRestaurants.append(contentsOf: convertedRestaurants)
            }
        }

        // Sort all restaurants by post count and take the top 'limit' restaurants
        let topRestaurants = Array(allRestaurants.sorted { $0.stats?.postCount ?? 0 > $1.stats?.postCount ?? 0 })

        let newLastDocument = snapshot.documents.last
        return (topRestaurants, newLastDocument)
    }

    func convertToRestaurant(_ clusterRestaurant: ClusterRestaurant) -> Restaurant? {
        
        
        let stats = RestaurantStats(postCount: clusterRestaurant.postCount ?? 0, collectionCount: 0)
        let overallRating = OverallRating(average: clusterRestaurant.overallRating, totalCount: nil)

        return Restaurant(
            id: clusterRestaurant.id,
            categoryName: clusterRestaurant.cuisine,
            price: clusterRestaurant.price,
            name: clusterRestaurant.name,
            geoPoint: clusterRestaurant.geoPoint,
            geoHash: clusterRestaurant.fullGeoHash,
            profileImageUrl: clusterRestaurant.profileImageUrl,
            stats: stats,
            overallRating: overallRating,
            macrocategory: clusterRestaurant.macrocategory
        )
    }
}

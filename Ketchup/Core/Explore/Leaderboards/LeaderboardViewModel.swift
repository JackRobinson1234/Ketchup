//
//  LeaderboardViewModel.swift
//  Ketchup
//
//  Created by Jack Robinson on 9/7/24.
//

import Foundation
import FirebaseCore
import FirebaseFirestoreInternal
import GeoFire
import GeohashKit

@MainActor
class LeaderboardViewModel: ObservableObject {
    @Published var timePeriod: TimePeriod = .month
    @Published var isLoading = false
    @Published var hasMorePosts = true
    @Published var hasMoreRestaurants = true
    @Published var posts: [Post] = []
    @Published var restaurants: [Restaurant] = []
    
    private var lastPostDocument: QueryDocumentSnapshot?
    private var lastRestaurantDocument: QueryDocumentSnapshot?
    private let pageSize = 10
    enum RatingCategory: String {
        case overall, food, atmosphere, value, service
    }
    
    
    enum LocationFilter {
        case anywhere
        case state(String)
        case city(String)
        case geohash(String)
    }

    private func applyLocationFilter(_ query: Query, filter: LocationFilter) -> Query {
        switch filter {
        case .anywhere:
            return query
        case .state(let state):
            return query.whereField("state", isEqualTo: state)
        case .city(let city):
            return query.whereField("city", isEqualTo: city)
        case .geohash(let geohash):
            let geohashPrefix = String(geohash.prefix(4))
            let geohashNeighbors = geohashNeighbors(geohash: geohashPrefix)
            return query.whereField("truncatedGeohash", in: geohashNeighbors)
        }
    }

    func fetchTopRestaurants(count: Int = 10, locationFilter: LocationFilter) async throws -> [Restaurant] {
        do {
            var query = FirestoreConstants.RestaurantCollection
                .order(by: "stats.postCount", descending: true)
            
            query = applyLocationFilter(query, filter: locationFilter)
            
            let restaurants = try await query
                .limit(to: count)
                .getDocuments(as: Restaurant.self)
            
            //print("Successfully fetched \(restaurants.count) top restaurants")
            return restaurants
        } catch {
            //print("Error fetching top restaurants: \(error.localizedDescription)")
            throw error
        }
    }

    func fetchMoreRestaurants(locationFilter: LocationFilter) async throws {
        guard !isLoading && hasMoreRestaurants else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            var query = FirestoreConstants.RestaurantCollection
                .order(by: "stats.postCount", descending: true)
            
            query = applyLocationFilter(query, filter: locationFilter)
            
            if let lastRestaurantDocument = lastRestaurantDocument {
                query = query.start(afterDocument: lastRestaurantDocument)
            }
            
            let snapshot = try await query.limit(to: pageSize).getDocuments()
            
            let newRestaurants = try snapshot.documents.compactMap { try $0.data(as: Restaurant.self) }
            
            restaurants.append(contentsOf: newRestaurants)
            lastRestaurantDocument = snapshot.documents.last
            hasMoreRestaurants = newRestaurants.count == pageSize
        } catch {
            //print("Error fetching more restaurants: \(error.localizedDescription)")
            throw error
        }
    }

    func fetchHighestRatedRestaurants(category: RatingCategory, count: Int = 10, locationFilter: LocationFilter) async throws -> [Restaurant] {
        do {
            let collectionReference = FirestoreConstants.RestaurantCollection
            var query: Query = collectionReference
            
            if category == .overall {
                query = query.whereField("overallRating.average", isGreaterThan: 0)
                    .order(by: "overallRating.average", descending: true)
                    .order(by: "overallRating.totalCount", descending: true)
            } else {
                query = query.whereField("ratingStats.\(category.rawValue).average", isGreaterThan: 0)
                    .order(by: "ratingStats.\(category.rawValue).average", descending: true)
                    .order(by: "ratingStats.\(category.rawValue).totalCount", descending: true)
            }
            
            query = applyLocationFilter(query, filter: locationFilter)
            
            let restaurants = try await query
                .limit(to: count)
                .getDocuments(as: Restaurant.self)
            
            //print("Successfully fetched \(restaurants.count) highest \(category.rawValue) rated restaurants")
            return restaurants
        } catch {
            //print("Error fetching highest \(category.rawValue) rated restaurants: \(error.localizedDescription)")
            throw error
        }
    }

    func fetchMoreHighestRatedRestaurants(category: RatingCategory, locationFilter: LocationFilter) async throws {
        guard !isLoading && hasMoreRestaurants else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            let collectionReference = FirestoreConstants.RestaurantCollection
            var query: Query = collectionReference
            
            if category == .overall {
                query = query.whereField("overallRating.average", isGreaterThan: 0)
                    .order(by: "overallRating.average", descending: true)
                    .order(by: "overallRating.totalCount", descending: true)
            } else {
                query = query.whereField("ratingStats.\(category.rawValue).average", isGreaterThan: 0)
                    .order(by: "ratingStats.\(category.rawValue).average", descending: true)
                    .order(by: "ratingStats.\(category.rawValue).totalCount", descending: true)
            }
            
            query = applyLocationFilter(query, filter: locationFilter)
            
            if let lastRestaurantDocument = lastRestaurantDocument {
                query = query.start(afterDocument: lastRestaurantDocument)
            }
            
            let snapshot = try await query.limit(to: pageSize).getDocuments()
            
            let newRestaurants = try snapshot.documents.compactMap { try $0.data(as: Restaurant.self) }
            
            restaurants.append(contentsOf: newRestaurants)
            lastRestaurantDocument = snapshot.documents.last
            hasMoreRestaurants = newRestaurants.count == pageSize
        } catch {
            //print("Error fetching more highest \(category.rawValue) rated restaurants: \(error.localizedDescription)")
            throw error
        }
    }
    func getStartOfWeek() -> Timestamp {
        let calendar = Calendar.current
        let currentDate = Date()
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: currentDate)) ?? currentDate
        return Timestamp(date: startOfWeek)
    }
    private func getStartOfMonth() -> Timestamp {
        let calendar = Calendar.current
        let currentDate = Date()
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: currentDate)) ?? currentDate
        return Timestamp(date: startOfMonth)
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
    func fetchMorePosts(state: String? = nil, city: String? = nil, geohash: String? = nil) async throws {
        guard !isLoading && hasMorePosts else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            let startDate = timePeriod == .week ? getStartOfWeek() : getStartOfMonth()
            
            var query = FirestoreConstants.PostsCollection
                .whereField("timestamp", isGreaterThanOrEqualTo: startDate)
                .order(by: "likes", descending: true)
            
            if let state = state, state != "All States" {
                let stateAbbreviation = StateNameConverter.fullName(for: state)
                query = query.whereField("restaurant.state", isEqualTo: stateAbbreviation)
            }
            
            if let city = city, !city.isEmpty {
                query = query.whereField("restaurant.city", isEqualTo: city)
            }
            if let geohash = geohash {
                let geohashPrefix = String(geohash.prefix(4)) // Using first 5 characters of the geohash
                let geohashNeighbors = geohashNeighbors(geohash: geohashPrefix)
                query = query.whereField("restaurant.truncatedGeohash", in: geohashNeighbors)
            }
            if let lastPostDocument = lastPostDocument {
                query = query.start(afterDocument: lastPostDocument)
            }
            
            let snapshot = try await query.limit(to: pageSize).getDocuments()
            
            let newPosts = try snapshot.documents.compactMap { try $0.data(as: Post.self) }
            
            posts.append(contentsOf: newPosts)
            lastPostDocument = snapshot.documents.last
            hasMorePosts = newPosts.count == pageSize
        } catch {
            //print("Error fetching more posts: \(error.localizedDescription)")
            throw error
        }
    }
    
    func resetPagination() {
        posts = []
        restaurants = []
        lastPostDocument = nil
        lastRestaurantDocument = nil
        hasMorePosts = true
        hasMoreRestaurants = true
    }
    func fetchTopPosts(count: Int = 10, state: String? = nil, city: String? = nil, geohash: String? = nil) async throws -> [Post] {
        do {
            let startDate = timePeriod == .week ? getStartOfWeek() : getStartOfMonth()
            
            var query = FirestoreConstants.PostsCollection
                .whereField("timestamp", isGreaterThanOrEqualTo: startDate)
                .order(by: "likes", descending: true)
            
            if let state = state, state != "All States" {
                let stateAbbreviation = StateNameConverter.fullName(for: state)
                query = query.whereField("restaurant.state", isEqualTo: stateAbbreviation)
            }
            if let geohash = geohash {
                let geohashPrefix = String(geohash.prefix(4)) // Using first 5 characters of the geohash
                let geohashNeighbors = geohashNeighbors(geohash: geohashPrefix)
                query = query.whereField("restaurant.truncatedGeohash", in: geohashNeighbors)
            }
            // Add city logic if necessary:
            if let city = city, !city.isEmpty {
                query = query.whereField("restaurant.city", isEqualTo: city)
            }
            
            let posts = try await query
                .limit(to: count)
                .getDocuments(as: Post.self)
            
            return posts
        } catch {
            //print("Error fetching top posts: \(error.localizedDescription)")
            return []
        }
    }
}
// Enum for TimePeriod
enum TimePeriod {
    case week
    case month
}

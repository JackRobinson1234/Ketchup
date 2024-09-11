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
                query = query.whereField("restaurant.geoHash", isGreaterThanOrEqualTo: geohashPrefix)
                    .whereField("restaurant.geoHash", isLessThan: geohashPrefix + "~")
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
            print("Error fetching more posts: \(error.localizedDescription)")
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
                query = query.whereField("restaurant.geoHash", isGreaterThanOrEqualTo: geohashPrefix)
                    .whereField("restaurant.geoHash", isLessThan: geohashPrefix + "~")
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
            print("Error fetching top posts: \(error.localizedDescription)")
            return []
        }
    }
    func fetchTopRestaurants(count: Int = 10, state: String? = nil, city: String? = nil, geohash: String? = nil) async throws -> [Restaurant] {
        do {
            let startDate = timePeriod == .week ? getStartOfWeek() : getStartOfMonth()
            
            var query = FirestoreConstants.RestaurantCollection
            // Assuming restaurants have a 'lastPostTimestamp' field
                .order(by: "stats.postCount", descending: true)
            
            if let state = state, state != "All States" {
                let stateAbbreviation = StateNameConverter.fullName(for: state)
                query = query.whereField("state", isEqualTo: stateAbbreviation)
            }
            
            if let city = city, !city.isEmpty {
                query = query.whereField("city", isEqualTo: city)
            }
            if let geohash = geohash {
                let geohashPrefix = String(geohash.prefix(4)) // Using first 5 characters of the geohash
                query = query.whereField("geoHash", isGreaterThanOrEqualTo: geohashPrefix)
                    .whereField("geoHash", isLessThan: geohashPrefix + "~")
            }
            let restaurants = try await query
                .limit(to: count)
                .getDocuments(as: Restaurant.self)
            
            return restaurants
        } catch {
            print("Error fetching top restaurants: \(error.localizedDescription)")
            throw error
        }
    }
    func fetchMoreRestaurants(state: String? = nil, city: String? = nil, geohash: String? = nil) async throws {
        guard !isLoading && hasMoreRestaurants else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            let startDate = timePeriod == .week ? getStartOfWeek() : getStartOfMonth()
            
            var query = FirestoreConstants.RestaurantCollection
                .order(by: "stats.postCount", descending: true)
            
            if let state = state, state != "All States" {
                let stateAbbreviation = StateNameConverter.fullName(for: state)
                query = query.whereField("state", isEqualTo: stateAbbreviation)
            }
            if let geohash = geohash {
                let geohashPrefix = String(geohash.prefix(4)) // Using first 5 characters of the geohash
                query = query.whereField("geoHash", isGreaterThanOrEqualTo: geohashPrefix)
                    .whereField("geoHash", isLessThan: geohashPrefix + "~")
            }
            if let city = city, !city.isEmpty {
                query = query.whereField("city", isEqualTo: city)
            }
            
            if let lastRestaurantDocument = lastRestaurantDocument {
                query = query.start(afterDocument: lastRestaurantDocument)
            }
            
            let snapshot = try await query.limit(to: pageSize).getDocuments()
            
            let newRestaurants = try snapshot.documents.compactMap { try $0.data(as: Restaurant.self) }
            
            restaurants.append(contentsOf: newRestaurants)
            lastRestaurantDocument = snapshot.documents.last
            hasMoreRestaurants = newRestaurants.count == pageSize
        } catch {
            print("Error fetching more restaurants: \(error.localizedDescription)")
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
}
// Enum for TimePeriod
enum TimePeriod {
    case week
    case month
}


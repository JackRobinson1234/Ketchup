//
//  LeaderboardViewModel.swift
//  Ketchup
//
//  Created by Jack Robinson on 9/7/24.
//

import Foundation
import FirebaseCore
class LeaderboardViewModel: ObservableObject {
    @Published var timePeriod: TimePeriod = .month
    // Fetch top 10 most liked posts based on time period
    func fetchTopPosts(count: Int = 10, state: String? = nil, city: String? = nil) async throws -> [Post] {
        do {
            let startDate = timePeriod == .week ? getStartOfWeek() : getStartOfMonth()
            
            var query = FirestoreConstants.PostsCollection
                .whereField("timestamp", isGreaterThanOrEqualTo: startDate)
                .order(by: "likes", descending: true)
            
            if let state = state, state != "All States" {
                let stateAbbreviation = StateNameConverter.fullName(for: state)
                query = query.whereField("restaurant.state", isEqualTo: stateAbbreviation)
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
    func fetchTopRestaurants(count: Int = 10, state: String? = nil, city: String? = nil) async throws -> [Restaurant] {
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
            
            let restaurants = try await query
                .limit(to: count)
                .getDocuments(as: Restaurant.self)
            
            return restaurants
        } catch {
            print("Error fetching top restaurants: \(error.localizedDescription)")
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

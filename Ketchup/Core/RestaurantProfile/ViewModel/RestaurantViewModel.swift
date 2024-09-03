//
//  RestaurantViewModel.swift
//  Foodi
//
//  Created by Jack Robinson on 2/1/24.
//

import AVFoundation
import SwiftUI
import FirebaseAuth
import FirebaseFirestoreInternal

@MainActor
class RestaurantViewModel: ObservableObject {
    @Published var collections = [Collection]()
    @Published var restaurant: Restaurant?
    @Published var collectionsViewModel = CollectionsViewModel()
    private let restaurantId: String
    @Published var isDragging = false
    @Published var currentSection: Section = .posts
    @Environment(\.dismiss) var dismiss
    @Published var isBookmarked: Bool = false
    @Published var overallRating: Double?
    @Published var foodRating: Double?
    @Published var atmosphereRating: Double?
    @Published var valueRating: Double?
    @Published var serviceRating: Double?
    @Published var friendsWhoPosted: [PostUser] = []
    
    init(restaurantId: String) {
        self.restaurantId = restaurantId
        // DEBUG: see if you can delete this
    }
    func fetchRestaurant(id: String) async throws {
        print("ATTEMPTED ID", id)
        if self.restaurant == nil {
            do {
                self.restaurant = try await RestaurantService.shared.fetchRestaurant(withId: id)
                print("DEBUG: Fetched restaurant: \(String(describing: self.restaurant))")
                if let restaurant = self.restaurant {
                    print("DEBUG: Restaurant ratingStats: \(String(describing: restaurant.ratingStats))")
                    calculateRatings(from: restaurant.ratingStats)
                } else {
                    print("DEBUG: Restaurant is nil after fetching")
                }
            } catch {
                print("DEBUG: Failed to fetch restaurant with error: \(error.localizedDescription)")
            }
        } else {
            print("DEBUG: Restaurant already exists, not fetching")
        }
    }
    
    private func calculateRatings(from ratingStats: RatingStats?) {
        print("DEBUG: Calculating ratings from: \(String(describing: ratingStats))")
        guard let ratingStats = ratingStats else {
            print("DEBUG: RatingStats is nil")
            return
        }
        
        self.foodRating = calculateAverageRating(ratingStats.food)
        self.atmosphereRating = calculateAverageRating(ratingStats.atmosphere)
        self.valueRating = calculateAverageRating(ratingStats.value)
        self.serviceRating = calculateAverageRating(ratingStats.service)
        
        // Calculate overall rating
        var totalSum = 0.0
        var totalCount = 0
        
        if let food = ratingStats.food, let foodSum = food.sum, let foodCount = food.totalCount {
            totalSum += foodSum
            totalCount += foodCount
        }
        if let atmosphere = ratingStats.atmosphere, let atmosphereSum = atmosphere.sum, let atmosphereCount = atmosphere.totalCount {
            totalSum += atmosphereSum
            totalCount += atmosphereCount
        }
        if let value = ratingStats.value, let valueSum = value.sum, let valueCount = value.totalCount {
            totalSum += valueSum
            totalCount += valueCount
        }
        if let service = ratingStats.service, let serviceSum = service.sum, let serviceCount = service.totalCount {
            totalSum += serviceSum
            totalCount += serviceCount
        }
        
        if totalCount > 0 {
            self.overallRating = (totalSum / Double(totalCount)).rounded(to: 1)
        } else {
            self.overallRating = nil
        }
        
        print("DEBUG: Calculated ratings - Overall: \(String(describing: overallRating)), Food: \(String(describing: foodRating)), Atmosphere: \(String(describing: atmosphereRating)), Value: \(String(describing: valueRating)), Service: \(String(describing: serviceRating))")
    }
    
    private func calculateAverageRating(_ category: RatingCategory?) -> Double? {
        guard let category = category,
              let totalCount = category.totalCount,
              totalCount > 0,
              let sum = category.sum else {
            return nil
        }
        
        return (sum / Double(totalCount)).rounded(to: 1)
    }
    
    func fetchRestaurantCollections() async throws{
        if let restaurant = restaurant{
            self.collections = try await CollectionService.shared.fetchRestaurantCollections(restaurantId: restaurant.id)
        }
    }
    func checkBookmarkStatus() async {
        guard let restaurant = restaurant else { return }
        do {
            isBookmarked = try await RestaurantService.shared.isBookmarked(restaurant.id)
        } catch {
            print("Error checking bookmark status: \(error.localizedDescription)")
        }
    }
    
    func toggleBookmark() async {
        guard let restaurant = restaurant else { return }
        do {
            if isBookmarked {
                try await RestaurantService.shared.removeBookmark(for: restaurant.id)
            } else {
                try await RestaurantService.shared.createBookmark(for: restaurant)
            }
            isBookmarked.toggle()
        } catch {
            print("Error toggling bookmark: \(error.localizedDescription)")
        }
    }
    func fetchFriendsWhoPosted() async {
        guard let currentUserID = Auth.auth().currentUser?.uid,
              let restaurant = restaurant else { return }
        
        do {
            let followingPostsRef = Firestore.firestore().collection("followingposts").document(currentUserID).collection("posts")
            let query = followingPostsRef
                .whereField("restaurant.id", isEqualTo: restaurant.id)
            
            let snapshot = try await query.getDocuments()
            
            let users = snapshot.documents.compactMap { document -> PostUser? in
                let data = document.data()
                guard let userDict = data["user"] as? [String: Any],
                      let id = userDict["id"] as? String,
                      let fullname = userDict["fullname"] as? String,
                      let username = userDict["username"] as? String,
                      let privateMode = userDict["privateMode"] as? Bool else {
                    return nil
                }
                let profileImageUrl = userDict["profileImageUrl"] as? String
                return PostUser(id: id, fullname: fullname, profileImageUrl: profileImageUrl, privateMode: privateMode, username: username)
            }
            
            self.friendsWhoPosted = Array(Set(users))  // Remove duplicates
        } catch {
            print("Error fetching friends who posted: \(error.localizedDescription)")
        }
    }
}
// MARK: - Posts


extension Double {
    func rounded(to places: Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}

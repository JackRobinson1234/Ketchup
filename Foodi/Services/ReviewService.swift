//
//  ReviewService.swift
//  Foodi
//
//  Created by Jack Robinson on 5/20/24.
//

import Foundation
import Firebase
import MapKit
import GeoFire
import FirebaseFirestoreInternal
import SwiftUI

class ReviewService {
    static let shared = ReviewService() // Singleton instance
    private init() {}
    func fetchRestaurantReviews(restaurantId: String) {
        
    }
    func fetchUserReviews(userId: String) {
        
    }
    func uploadReview(restaurant: Restaurant, recommends: Bool, description: String, favoriteItems: [String]?, user: User) async throws -> Review? {
        let ref = FirestoreConstants.ReviewsCollection.document()
        do{
            let reviewRestaurant = ReviewRestaurant(id: restaurant.id, name: restaurant.name, geoPoint: restaurant.geoPoint, geoHash: restaurant.geoHash, address: restaurant.address, city: restaurant.city, state: restaurant.state, profileImageUrl: restaurant.profileImageUrl)
            let reviewUser = ReviewUser(id: user.id, fullname: user.fullname, profileImageUrl: user.profileImageUrl, privateMode: user.privateMode, username: user.username)
            let review = Review(id: ref.documentID, description: description, likes: 0, timestamp: Timestamp(), user: reviewUser, restaurant: reviewRestaurant, recommendation: recommends, favoriteItems: favoriteItems)
            
            guard let reviewData = try? Firestore.Encoder().encode(review) else {
                print("not encoding review right")
                return nil}
            try await ref.setData(reviewData)
            return review
        } catch {
            print("DEBUG: Failed to upload Review with error \(error.localizedDescription)")
            throw error
        }
    }
    
    func deleteReview() {
        
    }
    
    func likeReview() {
        
    }
    func unlikeReview() {
        
    }
}

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
    func fetchRestaurantReviews(restaurantId: String) async throws -> [Review] {
        do {
            let reviews = try await FirestoreConstants.ReviewsCollection.whereField("restaurant.id", isEqualTo: restaurantId)
                .order(by: "timestamp", descending: true)
                .getDocuments(as: Review.self)
            print(reviews, "reviews")
            
            return reviews
        }
        catch{
            print("Error fetching reviews")
            throw error
        }
    }
    
    func fetchUserReviews(userId: String) async throws -> [Review] {
        do {
            let reviews = try await FirestoreConstants.ReviewsCollection.whereField("user.id", isEqualTo: userId)
                .order(by: "timestamp", descending: true)
                .getDocuments(as: Review.self)
            return reviews
        }
        catch{
            print("Error fetching reviews")
            throw error
        }
        
    }
//    func uploadReview(restaurant: Restaurant, recommends: Bool, description: String, favoriteItems: [String]?, user: User) async throws -> Review? {
//        let ref = FirestoreConstants.ReviewsCollection.document()
//        do{
//            let reviewRestaurant = ReviewRestaurant(id: restaurant.id, name: restaurant.name, geoPoint: restaurant.geoPoint, geoHash: restaurant.geoHash, address: restaurant.address, city: restaurant.city, state: restaurant.state, profileImageUrl: restaurant.profileImageUrl)
//            let reviewUser = ReviewUser(id: user.id, fullname: user.fullname, profileImageUrl: user.profileImageUrl, privateMode: user.privateMode, username: user.username)
//            let review = Review(id: ref.documentID, description: description, likes: 0, timestamp: Timestamp(), user: reviewUser, restaurant: reviewRestaurant, recommendation: recommends, favoriteItems: favoriteItems)
//            
//            guard let reviewData = try? Firestore.Encoder().encode(review) else {
//                print("not encoding review right")
//                return nil}
//            try await ref.setData(reviewData)
//            return review
//        } catch {
//            print("DEBUG: Failed to upload Review with error \(error.localizedDescription)")
//            throw error
//        }
//    }
    
    func deleteReview(reviewId: String) async throws {
        try await FirestoreConstants.ReviewsCollection.document(reviewId)
            .delete()
        print("Review deleted successfully")
    }
}
extension ReviewService {
    // MARK: - likeReview
    /// Likes a review from the current user
    /// - Parameter review: review object to be liked
    func likeReview(_ review: Review) async throws {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        async let _ = try FirestoreConstants.ReviewsCollection.document(review.id).collection("review-likes").document(uid).setData([:])
    }
    
    
    // MARK: - unlikeReview
    /// Unlikes a review from the current user
    /// - Parameter review: review object to be unliked
    func unlikeReview(_ review: Review) async throws {
        guard review.likes > 0 else { return }
        guard let uid = Auth.auth().currentUser?.uid else { return }
        async let _ = try FirestoreConstants.ReviewsCollection.document(review.id).collection("review-likes").document(uid).delete()
    }
    
    
    // MARK: - checkIfUserLikedReview
    /// Checks to see if the current user liked a review
    /// - Parameter review: review that is being checked
    /// - Returns: Boolean if the user liked the review
    func checkIfUserLikedReview(_ review: Review) async throws -> Bool {
        guard let uid = Auth.auth().currentUser?.uid else { return false }
        let snapshot = try await FirestoreConstants.UserCollection.document(uid).collection("user-likes").document(review.id).getDocument()
        return snapshot.exists
    }
}


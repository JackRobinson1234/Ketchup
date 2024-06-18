//
//  ReviewViewModel.swift
//  Foodi
//
//  Created by Jack Robinson on 5/20/24.
//

import Foundation
@MainActor
class ReviewsViewModel: ObservableObject {
    @Published var reviews = [Review]()
    @Published var isLoading: Bool = true
    @Published var selectedRestaurant: Restaurant?
    @Published var selectedUser: User?
    init(restaurant: Restaurant? = nil, user: User? = nil) {
        self.selectedRestaurant = restaurant
        self.selectedUser = user
    }
    
    
    func uploadReview(description: String, recommends: Bool, favorites: [String]?) async throws {

        if let user = AuthService.shared.userSession, let restaurant = self.selectedRestaurant {
            do {
                let review = try await ReviewService.shared.uploadReview(restaurant: restaurant, recommends: recommends, description: description, favoriteItems: favorites, user: user)
                // Insert the review at position 0
                if let review = review {
                    reviews.insert(review, at: 0)
                }
                
            } catch {
                // Handle the error
                throw error
            }
        }
    }
    
    func fetchReviews() async throws {
        if self.selectedRestaurant != nil {
            try await fetchRestaurantReviews()
        } else if self.selectedUser != nil {
            try await fetchUserReviews()
        }
    }
    
    func fetchUserReviews() async throws {
        if let user = selectedUser{
            self.reviews = try await ReviewService.shared.fetchUserReviews(userId: user.id)
        }
        try await checkIfUserLikedReviews()
        self.isLoading = false
    }
    
    func fetchRestaurantReviews() async throws {
        if let restaurant = selectedRestaurant{
            self.reviews = try await ReviewService.shared.fetchRestaurantReviews(restaurantId: restaurant.id)
        }
        try await checkIfUserLikedReviews()
        self.isLoading = false
    }
    
    
    func deleteReview(reviewId: String) async throws {
        do{
            try await ReviewService.shared.deleteReview(reviewId: reviewId)
            if let index = reviews.firstIndex(where: { $0.id == reviewId }) {
                         
                           reviews.remove(at: index)
                       }
        } catch {
            print("error deleting review")
            throw error
        }
    }
}


extension ReviewsViewModel {
    func like(_ review: Review) async {
        guard let index = reviews.firstIndex(where: { $0.id == review.id }) else { return }
        reviews[index].didLike = true
        reviews[index].likes += 1
        
        do {
            try await ReviewService.shared.likeReview(review)
        } catch {
            print("DEBUG: Failed to like review with error \(error.localizedDescription)")
            reviews[index].didLike = false
            reviews[index].likes -= 1
        }
    }
    
    func unlike(_ review: Review) async {
        guard let index = reviews.firstIndex(where: { $0.id == review.id }) else { return }
        reviews[index].didLike = false
        reviews[index].likes -= 1
        
        do {
            try await ReviewService.shared.unlikeReview(review)
        } catch {
            print("DEBUG: Failed to unlike review with error \(error.localizedDescription)")
            reviews[index].didLike = true
            reviews[index].likes += 1
        }
    }
    
    func checkIfUserLikedReviews() async throws {
        guard !reviews.isEmpty else { return }
        var copy = reviews
        for i in 0..<copy.count {
            do {
                let review = copy[i]
                let didLike = try await ReviewService.shared.checkIfUserLikedReview(review)
                
                if didLike {
                    copy[i].didLike = didLike
                }
            } catch {
                print("DEBUG: Failed to check if user liked review")
            }
        }
        
        reviews = copy
    }
}

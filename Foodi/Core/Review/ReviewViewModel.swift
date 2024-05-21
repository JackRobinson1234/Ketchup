//
//  ReviewViewModel.swift
//  Foodi
//
//  Created by Jack Robinson on 5/20/24.
//

import Foundation

class ReviewsViewModel: ObservableObject {
    @Published var reviews = [Review]()
    @Published var isLoading: Bool = false
    @Published var selectedRestaurant: Restaurant?
    init(restaurant: Restaurant? = nil) {
        self.selectedRestaurant = restaurant
    }
    
    @MainActor
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
}

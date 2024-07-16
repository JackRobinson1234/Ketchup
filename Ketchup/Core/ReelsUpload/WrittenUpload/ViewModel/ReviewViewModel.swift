//
//  ReviewViewModel.swift
//  Foodi
//
//  Created by Jack Robinson on 5/20/24.
//

import Foundation
import SwiftUI
@MainActor
class ReviewsViewModel: ObservableObject {
    @ObservedObject var feedViewModel: FeedViewModel
    @Published var reviews = [Review]()
    @Published var isLoading: Bool = true
    @Published var selectedRestaurant: Restaurant?
    @Published var selectedUser: User?
    @Published var restaurantRequest: RestaurantRequest?
    
    // Add properties for storing the state from the view
    @Published var description: String = ""
    @Published var serviceRating: Double = 5
    @Published var atmosphereRating: Double = 5
    @Published var valueRating: Double = 5
    @Published var foodRating: Double = 5
    @Published var isEditingCaption = false
    @Published var isCaptionEditorFocused: Bool = false
    @Published var editedReview = false
    @Published var isPickingRestaurant = false
    @Published var setRestaurant = false
    @Published var pickingFavorites: Bool = false
    @Published var showAlert = false
    @Published var showDetailsAlert = false
    
    @Published var taggedUsers: [PostUser] = []
    
    @Published var filteredMentionedUsers: [User] = []
    @Published var isMentioning: Bool = false
    var mentionableUsers: [User] = []
    
    private let characterLimit = 300
    @Published var isEditingDescription = false
    
    init(restaurant: Restaurant? = nil, user: User? = nil, feedViewModel: FeedViewModel) {
        self.selectedRestaurant = restaurant
        self.selectedUser = user
        self.feedViewModel = feedViewModel
    }
    
    var overallRatingPercentage: Double {
        ((serviceRating + atmosphereRating + valueRating + foodRating) / 4) * 10
    }
    
    func uploadReview(description: String, overallRating: Double, serviceRating: Double, atmosphereRating: Double, valueRating: Double, foodRating: Double) async throws {
        if let restaurant = restaurantRequest {
            do {
                try await RestaurantService.shared.requestRestaurant(requestRestaurant: restaurant)
            } catch {
                print("error uploading restaurant request")
            }
        }
        if let user = AuthService.shared.userSession, let restaurant = self.selectedRestaurant {
            do {
                let postRestaurant = UploadService.shared.createPostRestaurant(from: restaurant)
                let review = try await UploadService.shared.uploadPost(
                    videoURL: nil,
                    images: nil,
                    mediaType: .written,
                    caption: description,
                    postRestaurant: postRestaurant,
                    fromInAppCamera: false,
                    overallRating: overallRating,
                    serviceRating: serviceRating,
                    atmosphereRating: atmosphereRating,
                    valueRating: valueRating,
                    foodRating: foodRating,
                    taggedUsers: taggedUsers,
                    captionMentions: []
                )
                
                feedViewModel.showPostAlert = true
                feedViewModel.posts.insert(review, at: 0)
                reset()
            } catch {
                print("error uploading post")
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
    
    func checkForMentioning() {
        let words = description.split(separator: " ")
        
        if description.last == " " {
            isMentioning = false
            filteredMentionedUsers = []
            return
        }

        guard let lastWord = words.last, lastWord.hasPrefix("@") else {
            isMentioning = false
            filteredMentionedUsers = []
            return
        }

        let searchQuery = String(lastWord.dropFirst()).lowercased()
        if searchQuery.isEmpty {
            filteredMentionedUsers = mentionableUsers
        } else {
            filteredMentionedUsers = mentionableUsers.filter { $0.username.lowercased().contains(searchQuery) }
        }

        isMentioning = !filteredMentionedUsers.isEmpty
    }
    
    func reset() {
        self.reviews = []
        self.isLoading = false
        self.selectedRestaurant = nil
        self.selectedUser = nil
        self.restaurantRequest = nil
        
        // Reset the state properties
        self.description = ""
        self.serviceRating = 5
        self.atmosphereRating = 5
        self.valueRating = 5
        self.foodRating = 5
        self.isEditingCaption = false
        self.isCaptionEditorFocused = false
        self.editedReview = false
        self.isPickingRestaurant = false
        self.setRestaurant = false
        self.pickingFavorites = false
        self.showAlert = false
        self.showDetailsAlert = false
        self.isEditingDescription = false
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

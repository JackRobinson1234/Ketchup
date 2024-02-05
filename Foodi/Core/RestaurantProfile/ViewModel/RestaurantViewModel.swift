//
//  RestaurantViewModel.swift
//  Foodi
//
//  Created by Jack Robinson on 2/1/24.
//

import AVFoundation
import SwiftUI

@MainActor
class RestaurantViewModel: ObservableObject, PostGridViewModelProtocol {
    @Published var posts = [Post]()
    @Published var restaurant: Restaurant
    
    private let restaurantService: RestaurantService
    private let postService: PostService
    
    init(restaurant: Restaurant, restaurantService: RestaurantService, postService: PostService) {
        self.restaurant = restaurant
        self.restaurantService = restaurantService
        self.postService = postService
        Task {
            fetchPosts()
        }
    }
}
    
// MARK: - Posts

extension RestaurantViewModel {
    func fetchRestaurantPosts() async {
        do {
            self.posts = try await postService.fetchRestaurantPosts(restaurant: restaurant)
        } catch {
            print("DEBUG: Failed to fetch posts with error: \(error.localizedDescription)")
        }
    }
    func fetchPosts() {
        Task{
            await fetchRestaurantPosts()
        }
    }
}

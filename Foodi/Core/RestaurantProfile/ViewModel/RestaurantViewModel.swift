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
    @Published var restaurant: Restaurant?
    
    private let restaurantId: String
    private let restaurantService: RestaurantService
    private let postService: PostService
    
    init(restaurantId: String, restaurantService: RestaurantService, postService: PostService) {
        self.restaurantId = restaurantId
        self.restaurantService = restaurantService
        self.postService = postService
        Task {
            await fetchRestaurant(id: restaurantId)
        }
    }
    func fetchRestaurant(id: String) async {
        do {
            self.restaurant = try await restaurantService.fetchRestaurant(withId: id)
        } catch {
            print("DEBUG: Failed to fetch posts with error: \(error.localizedDescription)")
        }
        if let unwrappedRestaurant = self.restaurant{
            await withThrowingTaskGroup(of: Void.self) { group in
                group.addTask {await self.fetchRestaurantPosts(restaurant: unwrappedRestaurant) }
            }
        }
    }
}
// MARK: - Posts

extension RestaurantViewModel {
    func fetchRestaurantPosts(restaurant: Restaurant) async {
            do {
                self.posts = try await postService.fetchRestaurantPosts(restaurant: restaurant)
            } catch {
                print("DEBUG: Failed to fetch posts with error: \(error.localizedDescription)")
            }
        }
    
    func fetchPosts() {
        Task{
            if let unwrappedRestaurant = self.restaurant{
                await fetchRestaurantPosts(restaurant: unwrappedRestaurant)
            }
        }
    }
}

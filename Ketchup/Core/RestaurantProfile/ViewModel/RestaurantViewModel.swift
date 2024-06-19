//
//  RestaurantViewModel.swift
//  Foodi
//
//  Created by Jack Robinson on 2/1/24.
//

import AVFoundation
import SwiftUI

@MainActor
class RestaurantViewModel: ObservableObject {
    @Published var posts: [Post] = []
    @Published var collections = [Collection]()
    @Published var restaurant: Restaurant?
    @Published var collectionsViewModel = CollectionsViewModel(user: AuthService.shared.userSession!)
    private let restaurantId: String
    @Published var isDragging = false
    @Published var currentSection: Section = .posts
    @Environment(\.dismiss) var dismiss
    
    
    
    init(restaurantId: String) {
        self.restaurantId = restaurantId
        // DEBUG: see if you can delete this
        
    }
    func fetchRestaurant(id: String) async throws {
        if self.restaurant == nil {
            do {
                self.restaurant = try await RestaurantService.shared.fetchRestaurant(withId: id)
            } catch {
                print("DEBUG: Failed to fetch posts with error: \(error.localizedDescription)")
                
            }
        }
        if let unwrappedRestaurant = self.restaurant{
            await withThrowingTaskGroup(of: Void.self) { group in
                group.addTask {
                    try await self.fetchRestaurantPosts(restaurant: unwrappedRestaurant) }
            }
        }
    }
    func fetchRestaurantCollections() async throws{
        if let restaurant = restaurant{
            self.collections = try await CollectionService.shared.fetchRestaurantCollections(restaurantId: restaurant.id)
        }
    }
}
// MARK: - Posts

extension RestaurantViewModel {
    func fetchRestaurantPosts(restaurant: Restaurant) async throws{
        if let unwrappedRestaurant = self.restaurant{
            do {
                self.posts = try await PostService.shared.fetchRestaurantPosts(restaurant: unwrappedRestaurant)
            } catch {
                print("DEBUG: Failed to fetch posts with error: \(error.localizedDescription)")
                
            }
        }
    }
}

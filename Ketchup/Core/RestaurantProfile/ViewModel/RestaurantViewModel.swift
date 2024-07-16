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
    @Published var collections = [Collection]()
    @Published var restaurant: Restaurant?
    @Published var collectionsViewModel = CollectionsViewModel()
    private let restaurantId: String
    @Published var isDragging = false
    @Published var currentSection: Section = .posts
    @Environment(\.dismiss) var dismiss
    
    
    init(restaurantId: String) {
        self.restaurantId = restaurantId
        // DEBUG: see if you can delete this
    }
    func fetchRestaurant(id: String) async throws {
        print("ATTEMPTED ID", id)
        if self.restaurant == nil {
            do {
                self.restaurant = try await RestaurantService.shared.fetchRestaurant(withId: id)
            } catch {
                print("DEBUG: Failed to fetch posts with error: \(error.localizedDescription)")
                
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



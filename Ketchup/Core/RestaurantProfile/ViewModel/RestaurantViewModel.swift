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
    @Published var isBookmarked: Bool = false
    
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
}



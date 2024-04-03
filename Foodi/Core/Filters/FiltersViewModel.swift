//
//  FiltersViewModel.swift
//  Foodi
//
//  Created by Jack Robinson on 4/1/24.
//
import Foundation
import SwiftUI

class FiltersViewModel: ObservableObject {
    @ObservedObject var feedViewModel: FeedViewModel
    @Published var selectedCuisines: [String] = []
    @Published var selectedPostTypes: [String] = ["brand", "restaurant", "recipe"]
    var filters: [String: [Any]] = [:]
    
    /// variables for the postType filter
    @Published var restaurantChecked: Bool = true
    @Published var brandChecked: Bool = true
    @Published var recipeChecked: Bool = true
    
    init(feedViewModel: FeedViewModel) {
            self.feedViewModel = feedViewModel
        }

    /// fetches filtered from firebase and preloads the next 3 posts in the cache based on the current filters
    func fetchFilteredPosts() async {
        
        /// if no cuisines are passed in, then it removes the value from filters, otherwise adds it as a paramater to be passed into fetchposts
        if selectedCuisines.isEmpty {
            filters.removeValue(forKey: "recipe.cuisine")
        } else {
            filters["cuisine"] = selectedCuisines
        }
        /// checks to see if selectedPostTypes has all three. If it does, it doesn't pass it as a paramater to fetchposts. If some are unselected, it will filter by the other two.
        updateSelectedPostTypes()
        if selectedPostTypes.isEmpty {
            filters.removeValue(forKey: "postType")
        } else {
            filters["postType"] = selectedPostTypes
        }
        print("DEBUG: \(filters)")
        await feedViewModel.fetchPosts(withFilters: self.filters)
    }
    
    private func updateSelectedPostTypes() {
        if restaurantChecked && brandChecked && recipeChecked {
                // If all toggles are on, make selectedPosts a blank array
                selectedPostTypes = []
            }
        else {
            var updatedPostTypes: [String] = []
            if restaurantChecked {
                updatedPostTypes.append("restaurant")
            }
            if brandChecked {
                updatedPostTypes.append("brand")
            }
            if recipeChecked {
                updatedPostTypes.append("recipe")
            }
            selectedPostTypes = updatedPostTypes
        }
    }
}

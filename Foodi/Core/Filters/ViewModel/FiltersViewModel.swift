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
    @Published var selectedPrice: [String] = []
    @Published var selectedPostTypes: [String] = [ "restaurant", "atHome"]
    var filters: [String: [Any]] = [:]
    
    /// variables for the postType filter
    @Published var restaurantChecked: Bool = true
    @Published var atHomeChecked: Bool = true
    
    init(feedViewModel: FeedViewModel) {
            self.feedViewModel = feedViewModel
        }

    /// fetches filtered from firebase and preloads the next 3 posts in the cache based on the current filters
    func fetchFilteredPosts() async {
        
        /// if no cuisines are passed in, then it removes the value from filters, otherwise adds it as a parameter to be passed into fetchPosts
        if selectedCuisines.isEmpty {
            filters.removeValue(forKey: "recipe.cuisine")
        } else {
            filters["cuisine"] = selectedCuisines
        }
        /// checks to see if selectedPostTypes has all three. If it does, it doesn't pass it as a parameter to fetchPosts. If some are unselected, it will filter by the other two.
        updateSelectedPostTypes()
        if selectedPostTypes.isEmpty {
            filters.removeValue(forKey: "postType")
        } else {
            filters["postType"] = selectedPostTypes
        }
        
        if selectedPrice.isEmpty {
            filters.removeValue(forKey: "postType")
        } else {
            filters["price"] = selectedPrice
        }
        
        print("DEBUG: \(filters)")
        await feedViewModel.fetchPosts(withFilters: self.filters)
    }
    
    private func updateSelectedPostTypes() {
        if restaurantChecked && atHomeChecked {
                /// If all postType toggles are on, make selectedPosts a blank array
                selectedPostTypes = []
            }
        else {
            var updatedPostTypes: [String] = []
            if restaurantChecked {
                updatedPostTypes.append("restaurant")
            }
            if atHomeChecked {
                updatedPostTypes.append("atHome")
            }
            selectedPostTypes = updatedPostTypes
        }
    }
}

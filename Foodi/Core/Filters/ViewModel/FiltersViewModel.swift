//
//  FiltersViewModel.swift
//  Foodi
//
//  Created by Jack Robinson on 4/1/24.
//
import Foundation
import SwiftUI
import MapKit
class FiltersViewModel: ObservableObject {
    @ObservedObject var feedViewModel: FeedViewModel
    
    var filters: [String: [Any]] = [:]
    
    @Published var selectedCuisines: [String] = []
    @Published var selectedPrice: [String] = []
    @Published var selectedDietary: [String] = []
    @Published var selectedCookingTime: [Int] = []
    
    
    /// variables for the location filter
    @Published var selectedLocation: [CLLocationCoordinate2D] = []
    @Published var radius: Int = 0
    
    
    /// variables for the postType filter
    @Published var restaurantChecked: Bool = true
    @Published var atHomeChecked: Bool = true
    @Published var selectedPostTypes: [String] = [ "restaurant", "atHome"]
    
    init(feedViewModel: FeedViewModel) {
            self.feedViewModel = feedViewModel
        }

    /// fetches filtered from firebase and preloads the next 3 posts in the cache based on the current filters
    func fetchFilteredPosts() async {
        
        /// if no cuisines are passed in, then it removes the value from filters, otherwise adds it as a parameter to be passed into fetchPosts
        if selectedCuisines.isEmpty {
            filters.removeValue(forKey: "cuisine")
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
        ///Price checking if there are any selected
        if selectedPrice.isEmpty {
            filters.removeValue(forKey: "price")
        } else {
            filters["price"] = selectedPrice
        }
        ///DIetary checking if there are any selected
        if selectedDietary.isEmpty {
            filters.removeValue(forKey: "recipe.dietary")
        } else {
            filters["recipe.dietary"] = selectedDietary
        }
        /// Cooking Time checking if there are any selected
        if selectedCookingTime.isEmpty {
            filters.removeValue(forKey: "recipe.cookingTime")
        } else {
            filters["recipe.cookingTime"] = selectedCookingTime
        }
        
        await feedViewModel.fetchPosts(withFilters: self.filters)
    }
    /// updates "selectedPostTypes" with what the boolean values for the toggle are selected to
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
            self.selectedPostTypes = updatedPostTypes
        }
    }
}

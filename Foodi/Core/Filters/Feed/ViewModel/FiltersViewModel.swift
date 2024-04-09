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
    @Published var selectedCity: String = ""
    @Published var selectedState: String = ""
    
    
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
            filters.removeValue(forKey: "cuisine")
        } else {
            filters["cuisine"] = selectedCuisines
        }
        /// checks to see if selectedPostTypes has both selected. If it does, it doesn't pass it as a parameter to fetchPosts.
        let selectedPostTypes = updateSelectedPostTypes()
        if selectedPostTypes.isEmpty {
            filters.removeValue(forKey: "postType")
        } else {
            filters["postType"] = selectedPostTypes
        }
        
        if selectedLocation.isEmpty {
            filters.removeValue(forKey: "location")
        } else {
            filters["location"] = selectedLocation
        }
        
        ///Price checking if there are any selected
        if selectedPrice.isEmpty {
            filters.removeValue(forKey: "price")
        } else {
            filters["price"] = selectedPrice
        }
        ///Dietary checking if there are any selected
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
    
    //MARK: update selected posts
    /// updates "selectedPostTypes" with what the boolean values for the toggle are selected to
    func updateSelectedPostTypes() -> [String] {
        if restaurantChecked && atHomeChecked {
                /// If all postType toggles are on, make selectedPosts a blank array
                return []
            }
        else {
            var updatedPostTypes: [String] = []
            if restaurantChecked {
                updatedPostTypes.append("restaurant")
            }
            if atHomeChecked {
                updatedPostTypes.append("atHome")
            }
            return updatedPostTypes
        }
    }
}

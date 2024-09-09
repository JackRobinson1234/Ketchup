//
//  FiltersViewModel.swift
//  Foodi
//
//  Created by Jack Robinson on 4/1/24.
//
import SwiftUI
import Combine
import CoreLocation
import MapKit

class FiltersViewModel: ObservableObject {
    @ObservedObject var feedViewModel: FeedViewModel
    
    @Published var filters: [String: [Any]] = [:]
    
    @Published var selectedCuisines: [String] = []
    @Published var selectedPrice: [String] = []
    @Published var selectedDietary: [String] = []
    @Published var selectedCookingTime: [Int] = []
    
    var hasNonLocationFilters: Bool {
            // Check if there are any filters excluding the "location" key
            return filters.filter { $0.key != "restaurant.city" }.isEmpty == false
        }
    /// variables for the location filter
    @Published var selectedLocations: [[String: String]] = []
    
    /// variables for the postType filter
    @Published var restaurantChecked: Bool = true
    @Published var atHomeChecked: Bool = true
    
    @Published var disableAtHomeFilters = false
    @Published var disableRestaurantFilters = false
    @State var filtersChanged = false
    
    init(feedViewModel: FeedViewModel) {
        self.feedViewModel = feedViewModel
    }
    
    /// fetches filtered from firebase and preloads the next 3 posts in the cache based on the current filters
    func fetchFilteredPosts() async {
        /// if no cuisines are passed in, then it removes the value from filters, otherwise adds it as a parameter to be passed into fetchPosts
        if selectedCuisines.isEmpty {
            filters.removeValue(forKey: "restaurant.cuisine")
        } else {
            filters["restaurant.cuisine"] = selectedCuisines
        }
        /// checks to see if selectedPostTypes has both selected. If it does, it doesn't pass it as a parameter to fetchPosts.
        
        if selectedLocations.isEmpty {
                filters.removeValue(forKey: "restaurant.city")
            } else {
                let selectedCities = selectedLocations.compactMap { $0["city"] }
                filters["restaurant.city"] = selectedCities
            }
        
        ///Price checking if there are any selected
        if selectedPrice.isEmpty {
            filters.removeValue(forKey: "restaurant.price")
        } else {
            filters["restaurant.price"] = selectedPrice
        }
        ///Dietary checking if there are any selected
        //print("Filters", filters)
        do{
            feedViewModel.isInitialLoading = true
            try await feedViewModel.fetchInitialPosts(withFilters: self.filters)
            feedViewModel.isInitialLoading = false
        } catch {
            //print("Error")
        }
    }
    
    //MARK: update selected posts
    /// updates "selectedPostTypes" with what the boolean values for the toggle are selected to
    
    
    func clearFilters() {
        selectedCuisines = []
        selectedPrice = []
        selectedDietary = []
        selectedCookingTime = []
//        selectedLocations = []
//        selectedCity = []
//        selectedState = []
        restaurantChecked = true
        atHomeChecked = true
        filters = [:]
    }
    

}

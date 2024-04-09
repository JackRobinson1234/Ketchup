//
//  MapViewModel.swift
//  Foodi
//
//  Created by Jack Robinson on 2/11/24.
//

import Foundation
import MapKit
import Firebase

@MainActor
class MapViewModel: ObservableObject {
    private let restaurantService = RestaurantService()
    @Published var restaurants = [Restaurant]()
    @Published var searchPreview = [Restaurant]()
    
    
    var filters: [String: [Any]] = [:]
    
    @Published var selectedCuisines: [String] = []
    @Published var selectedPrice: [String] = []
    @Published var selectedLocation: [CLLocationCoordinate2D] = []
    @Published var selectedCity: String = ""
    @Published var selectedState: String = ""
    
    
    
    /// variables for the postType filter
    
    //MARK: fetchFilteredRestaurants
    func fetchFilteredRestaurants() async {
        do{
            /// if no cuisines are passed in, then it removes the value from filters, otherwise adds it as a parameter to be passed into fetchPosts
            if selectedCuisines.isEmpty {
                filters.removeValue(forKey: "cuisine")
            } else {
                filters["cuisine"] = selectedCuisines
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
            self.restaurants = try await restaurantService.fetchRestaurants(withFilters: self.filters)
        }
        catch {
            print("DEBUG: Failed to fetch posts \(error.localizedDescription)")
        }
    }

     //MARK: filteredRestaurants
        func filteredRestaurants(_ query: String) -> [Restaurant] {
            let lowercasedQuery = query.lowercased()
            return restaurants.filter({
                $0.name.lowercased().contains(lowercasedQuery) ||
                $0.name.contains(lowercasedQuery)
            })
        }
}
    

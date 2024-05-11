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
    func fetchFilteredRestaurants(radius: Double = 500, limit: Int = 0) async -> Bool {
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
                filters["location"] = selectedLocation + [radius]
            }
            ///Price checking if there are any selected
            if selectedPrice.isEmpty {
                filters.removeValue(forKey: "price")
            } else {
                filters["price"] = selectedPrice
            }
            
            
            self.restaurants = try await RestaurantService.shared.fetchRestaurants(withFilters: self.filters, limit: limit)
            print(restaurants.count)
        }
        catch {
            print("DEBUG: Failed to fetch posts \(error.localizedDescription)")
        }
        return restaurants.count > 0
    }

     //MARK: filteredRestaurants
        func filteredRestaurants(_ query: String) -> [Restaurant] {
            let lowercasedQuery = query.lowercased()
            return restaurants.filter({
                $0.name.lowercased().contains(lowercasedQuery) ||
                $0.name.contains(lowercasedQuery)
            })
        }
    
    func checkForNearbyRestaurants() async {
        let kmRadiusToCheck = [1.0, 2.5, 5.0, 10.0, 20.0]
        for radius in kmRadiusToCheck {
            let restaurants = await fetchFilteredRestaurants(radius: radius * 1000, limit: 1)
            if restaurants {
                break
            }
        }
    }
    func clearFilters() {
        selectedCuisines = []
        selectedPrice = []
    }
}
    

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
    @Published var clusters = [Cluster]()
    
    
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
    
    func fetchFilteredClusters(region: MKCoordinateRegion, limit: Int = 0) async -> Bool {
        do{
            let (centers, radius) = centersAndRadiusOfSubregions(region: region)
            
            
            /// if no cuisines are passed in, then it removes the value from filters, otherwise adds it as a parameter to be passed into fetchPosts
            var savedClusters: [Cluster] = []
            for center in centers {
                if selectedCuisines.isEmpty {
                    filters.removeValue(forKey: "cuisine")
                } else {
                    filters["cuisine"] = selectedCuisines
                }
                filters["location"] = [center] + [radius]
                ///Price checking if there are any selected
                if selectedPrice.isEmpty {
                    filters.removeValue(forKey: "price")
                } else {
                    filters["price"] = selectedPrice
                }
                savedClusters.append(contentsOf: try await RestaurantService.shared.fetchClusters(withFilters: self.filters, limit: limit))
                
            }
            self.clusters = savedClusters
            print(self.clusters)
            return clusters.count > 0
            
        }
        catch {
            print("DEBUG: Failed to fetch posts \(error.localizedDescription)")
        }
        return restaurants.count > 0
    }
    
    
    
    func centersAndRadiusOfSubregions(region: MKCoordinateRegion) -> ([CLLocationCoordinate2D], Double) {
        let rows = 4.0
        let columns = 4.0
        let fullWidth = region.span.longitudeDelta
        let fullHeight = region.span.latitudeDelta
        
        print("fullWidth", fullWidth)
        print("fullheight", fullHeight)
            let rectWidth = fullWidth / rows
            let rectHeight = fullHeight / columns
            
            // Convert width and height from degrees to kilometers (approximation)
            let kmPerDegreeLatitude = 111.32
            let kmPerDegreeLongitude = 111.32 * cos(region.center.latitude * .pi / 180)
            
            let rectWidthInKM = rectWidth * kmPerDegreeLongitude
            let rectHeightInKM = rectHeight * kmPerDegreeLatitude
            
            // The radius of the largest circle that fits inside the rectangle
            //let radiusInKM = min(rectWidthInKM, rectHeightInKM) / 2.0
            
            var centers: [CLLocationCoordinate2D] = []
            
            for row in 3..<6 {
                for col in 3..<6 {
                    let centerLat = region.center.latitude - (fullHeight / 2) + (Double(row) + 0.5) * rectHeight
                    let centerLon = region.center.longitude - (fullWidth / 2) + (Double(col) + 0.5) * rectWidth
                    let center = CLLocationCoordinate2D(latitude: centerLat, longitude: centerLon)
                    centers.append(center)
                    
                }
            }
            let newRadius = 100.0//calculateDistanceInMeters(from: centers[0], to: centers[1])/3
            print("distance in M", calculateDistanceInMeters(from: centers[0], to: centers[1]))
            return (centers, newRadius)
        
    }
    private func calculateDistanceInMeters(from coordinate1: CLLocationCoordinate2D, to coordinate2: CLLocationCoordinate2D) -> Double{
        let location1 = CLLocation(latitude: coordinate1.latitude, longitude: coordinate1.longitude)
        let location2 = CLLocation(latitude: coordinate2.latitude, longitude: coordinate2.longitude)
        let distanceInMeters = location1.distance(from: location2)
        return distanceInMeters
        
    }
}

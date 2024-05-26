//
//  MapViewModel.swift
//  Foodi
//
//  Created by Jack Robinson on 2/11/24.
//

import Foundation
import MapKit
import Firebase
import ClusterMap
import SwiftUI
@MainActor
class MapViewModel: ObservableObject {
    let clusterManager = ClusterManager<RestaurantMapAnnotation>()
    @Published var restaurants = [Restaurant]()
    @Published var searchPreview = [Restaurant]()
    var filters: [String: [Any]] = [:]
    @Published var selectedCuisines: [String] = []
    @Published var selectedPrice: [String] = []
    @Published var selectedLocation: [CLLocationCoordinate2D] = []
    @Published var selectedCity: String = ""
    @Published var selectedState: String = ""
    //@Published var clusters = [Cluster]()
    var annotations: [RestaurantMapAnnotation] = []
    var clusters: [ExampleClusterAnnotation] = []
    var mapSize: CGSize = .zero
    @Published var currentRegion: MKCoordinateRegion = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 34.0549, longitude: -118.2426), span: MKCoordinateSpan(latitudeDelta: 0.03, longitudeDelta: 0.03))
    
    /// variables for the postType filter
    
    //MARK: fetchFilteredRestaurants
    func fetchFilteredRestaurants(radius: Double = 500, limit: Int = 0) async -> Bool {
        do{
            //TODO: Test
            Task{
                await clusterManager.removeAll()
            }
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
            
            
            let restaurants: [Restaurant] = try await RestaurantService.shared.fetchRestaurants(withFilters: self.filters, limit: limit)
            self.restaurants = restaurants
            print("restaurant count", restaurants.count)
            let restaurantAnnotations: [RestaurantMapAnnotation] = restaurants.compactMap { restaurant in
                if let coordinates = restaurant.coordinates {
                    return RestaurantMapAnnotation(coordinate: coordinates, restaurant: restaurant)
                } else {
                    return nil
                }
            }
            print("restaurantAnnotations", restaurantAnnotations.count)
            Task{
                await clusterManager.add(restaurantAnnotations)
                await reloadAnnotations()
            }
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
    @MainActor
    private func applyChanges(_ difference: ClusterManager<RestaurantMapAnnotation>.Difference) {
        for removal in difference.removals {
            switch removal {
            case .annotation(let annotation):
                annotations.removeAll { $0 == annotation }
            case .cluster(let clusterAnnotation):
                clusters.removeAll { $0.id == clusterAnnotation.id }
            }
        }
        for insertion in difference.insertions {
            switch insertion {
            case .annotation(let newItem):
                annotations.append(newItem)
            case .cluster(let newItem):
                clusters.append(ExampleClusterAnnotation(
                    id: newItem.id,
                    coordinate: newItem.coordinate,
                    count: newItem.memberAnnotations.count
                ))
            }
        }
    }
    
    
    func removeAnnotations() async {
        await clusterManager.removeAll()
        await reloadAnnotations()
    }
    
    func reloadAnnotations() async {
        async let changes = clusterManager.reload(mapViewSize: mapSize, coordinateRegion: currentRegion)
        await applyChanges(changes)
    }
}



struct RestaurantMapAnnotation: CoordinateIdentifiable, Identifiable, Hashable, Equatable {
    let id = UUID()
    var coordinate: CLLocationCoordinate2D
    var restaurant: Restaurant
}

struct ExampleClusterAnnotation: Identifiable {
    var id = UUID()
    var coordinate: CLLocationCoordinate2D
    var count: Int
}

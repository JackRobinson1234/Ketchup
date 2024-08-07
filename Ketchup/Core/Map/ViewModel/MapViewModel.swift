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
    @Published var filters: [String: [Any]] = [:]
    @Published var selectedCuisines: [String] = []
    @Published var selectedPrice: [String] = []
    @Published var selectedLocation: [CLLocationCoordinate2D] = []
    @Published var selectedCity: String = ""
    @Published var selectedState: String = ""
    @Published var annotations: [RestaurantMapAnnotation] = []
    @Published var clusters: [ExampleClusterAnnotation] = []
    @Published var largeClusters: [LargeClusterAnnotation] = []
    @Published var currentRegion: MKCoordinateRegion = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 34.0549, longitude: -118.2426), span: MKCoordinateSpan(latitudeDelta: 0.03, longitudeDelta: 0.03))
    @Published var isLoading = false
    @Published var currentZoomLevel: String = "neighborhood"
    
    var mapSize: CGSize = .zero
    let maxZoomOutSpan: Double = 0.2
    let longitudeDeltaToConvertToRestaurant: Double = 0.006
    
    var isZoomedEnoughForClusters: Bool {
        return currentRegion.span.longitudeDelta > longitudeDeltaToConvertToRestaurant
    }
    
    func determineZoomLevel() -> String {
        let span = currentRegion.span
        if span.longitudeDelta > maxZoomOutSpan {
            return "max_zoom_out"
        } else if span.longitudeDelta > 0.03 {
            return "region"
        } else if span.longitudeDelta > 0.007 {
            return "city"
        } else {
            return "neighborhood"
        }
    }
    
    func updateZoomLevelAndFetchIfNeeded() async {
        let newZoomLevel = determineZoomLevel()
        if newZoomLevel != currentZoomLevel {
            currentZoomLevel = newZoomLevel
            if newZoomLevel != "max_zoom_out" {
                await fetchFilteredClusters()
            } else {
                await removeAnnotations()
            }
        }
    }
    
    func fetchFilteredClusters(limit: Int = 0) async -> Bool {
        do {
            isLoading = true
            await clusterManager.removeAll()

            let radius = calculateRadius()
            updateFilters(radius: radius)

            let restaurants: [Restaurant]
            let clusters: [Cluster]

            if isZoomedEnoughForClusters {
                clusters = try await ClusterService.shared.fetchClustersWithLocation(filters: self.filters, center: self.currentRegion.center, radiusInM: radius, zoomLevel: determineZoomLevel(), limit: limit)
                restaurants = []
                print("DEBUG: Fetched \(clusters.count) clusters")
            } else {
                restaurants = try await RestaurantService.shared.fetchRestaurants(withFilters: self.filters, limit: limit)
                clusters = []
                print("DEBUG: Fetched \(restaurants.count) restaurants")
            }

            self.restaurants = restaurants
//            self.clusters = clusters.map { cluster in
//                ExampleClusterAnnotation(
//                    id: UUID(),
//                    coordinate: CLLocationCoordinate2D(latitude: cluster.center.latitude, longitude: cluster.center.longitude),
//                    count: cluster.count,
//                    memberAnnotations: cluster.restaurants.map { restaurant in
//                        RestaurantMapAnnotation(coordinate: restaurant.geoPoint.coordinate, restaurant: Restaurant(
//                            id: restaurant.id,
//                            name: restaurant.name,
//                            cuisine: restaurant.cuisine,
//                            price: restaurant.price,
//                            profileImageUrl: restaurant.profileImageUrl,
//                            geoPoint: restaurant.geoPoint,
//                            fullGeoHash: restaurant.fullGeoHash,
//                            attributes: restaurant.attributes
//                        ))
//                    }
//                )
//            }

            self.largeClusters = clusters.map { cluster in
                LargeClusterAnnotation(
                    id: UUID(),
                    coordinate: CLLocationCoordinate2D(latitude: cluster.center.latitude, longitude: cluster.center.longitude),
                    count: cluster.count,
                    memberAnnotations: cluster.restaurants
                )
            }

            let restaurantAnnotations: [RestaurantMapAnnotation] = restaurants.compactMap { restaurant in
                if let coordinates = restaurant.coordinates {
                    return RestaurantMapAnnotation(coordinate: coordinates, restaurant: restaurant)
                } else {
                    return nil
                }
            }

            await clusterManager.add(restaurantAnnotations)
            await reloadAnnotations()
            isLoading = false
        } catch {
            print("DEBUG: Failed to fetch clusters \(error.localizedDescription)")
            isLoading = false
            return false
        }

        return !restaurants.isEmpty || !clusters.isEmpty
    }
    
    func removeAnnotations() async {
        await clusterManager.removeAll()
        await reloadAnnotations()
    }
    
    func reloadAnnotations() async {
        async let changes = clusterManager.reload(mapViewSize: mapSize, coordinateRegion: currentRegion)
        await applyChanges(changes)
    }
    
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
                    count: newItem.memberAnnotations.count,
                    memberAnnotations: newItem.memberAnnotations
                ))
            }
        }
    }
    
    private func updateFilters(radius: Double) {
        if selectedCuisines.isEmpty {
            filters.removeValue(forKey: "categoryName")
        } else {
            filters["categoryName"] = selectedCuisines
        }

        if selectedLocation.isEmpty {
            filters.removeValue(forKey: "location")
        } else {
            filters["location"] = selectedLocation + [radius]
        }

        if selectedPrice.isEmpty {
            filters.removeValue(forKey: "price")
        } else {
            filters["price"] = selectedPrice
        }
    }
    
    private func calculateRadius() -> Double {
        let mapWidth = mapSize.width
        let mapHeight = mapSize.height
        let span = currentRegion.span
        
        // Calculate the diagonal distance of the visible map area in degrees
        let diagonalSpan = sqrt(pow(span.latitudeDelta, 2) + pow(span.longitudeDelta, 2))
        
        // Convert the diagonal span to meters
        let metersPerDegree = 111319.9 // Approximate meters per degree at the equator
        let diagonalMeters = diagonalSpan * metersPerDegree
        
        // Adjust the radius based on the map size and zoom level
        let baseRadius = diagonalMeters / 2
        let zoomFactor = max(mapWidth, mapHeight) / 1000 // Adjust this factor as needed
        
        let adjustedRadius = baseRadius * zoomFactor
        
        // Clamp the radius to a reasonable range (e.g., between 500m and 50km)
        return min(max(adjustedRadius, 500), 50000) * 0.9
    }
    
    func checkForNearbyRestaurants() async {
        // Implementation of checkForNearbyRestaurants
    }
    
    func clearFilters() {
        selectedCuisines = []
        selectedPrice = []
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
    var memberAnnotations: [RestaurantMapAnnotation]
}
struct LargeClusterAnnotation: Identifiable {
    var id = UUID()
    var coordinate: CLLocationCoordinate2D
    var count: Int
    var memberAnnotations: [ClusterRestaurant]
}

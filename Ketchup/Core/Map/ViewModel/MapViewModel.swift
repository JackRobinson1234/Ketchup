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
    @Published var currentZoomLevel: ZoomLevel = .neighborhood
       @Published var lastFetchedRegion: MKCoordinateRegion?
       
       private var fetchTask: Task<Void, Never>?
       private let fetchDebouncer = Debouncer(delay: 0.3)
       
       enum ZoomLevel: String {
           case maxZoomOut = "max_zoom_out"
           case region = "region"
           case city = "city"
           case neighborhood = "neighborhood"
       }
    
    
    var mapSize: CGSize = .zero
    let maxZoomOutSpan: Double = 0.2
    let longitudeDeltaToConvertToRestaurant: Double = 0.006
    
    var isZoomedEnoughForClusters: Bool {
        return currentRegion.span.longitudeDelta > longitudeDeltaToConvertToRestaurant
    }
    
    private func determineZoomLevel(for region: MKCoordinateRegion) -> ZoomLevel {
            let span = region.span
            if span.longitudeDelta > maxZoomOutSpan {
                return .maxZoomOut
            } else if span.longitudeDelta > 0.03 {
                return .region
            } else if span.longitudeDelta > 0.007 {
                return .city
            } else {
                return .neighborhood
            }
        }
    
 
    func updateMapState(newRegion: MKCoordinateRegion) {
            let newZoomLevel = determineZoomLevel(for: newRegion)
            
            // Cancel any ongoing fetch task
            fetchTask?.cancel()
            
            // Debounce the fetch operation
            fetchDebouncer.schedule { [weak self] in
                guard let self = self else { return }
                
                self.fetchTask = Task { @MainActor in
                    // Check if the task was cancelled
                    if Task.isCancelled { return }
                    
                    let shouldFetch = self.shouldFetchNewData(newRegion: newRegion, newZoomLevel: newZoomLevel)
                    
                    if shouldFetch {
                        self.currentRegion = newRegion
                        self.currentZoomLevel = newZoomLevel
                        await self.fetchFilteredClusters()
                        self.lastFetchedRegion = newRegion
                    }
                }
            }
        }
    private func shouldFetchNewData(newRegion: MKCoordinateRegion, newZoomLevel: ZoomLevel) -> Bool {
           guard let lastFetchedRegion = lastFetchedRegion else {
               return true // First fetch
           }
           
           // Check if zoom level changed
           if newZoomLevel != currentZoomLevel {
               return true
           }
           
           // Check if the map has moved significantly
           let distanceThreshold = calculateDistanceThreshold(for: newRegion)
           let distance = calculateDistance(from: lastFetchedRegion.center, to: newRegion.center)
           
           return distance >= distanceThreshold
       }
    private func calculateDistanceThreshold(for region: MKCoordinateRegion) -> CLLocationDistance {
            // Adjust this calculation based on your app's requirements
            return max(region.span.longitudeDelta, region.span.latitudeDelta) * 111000 * 0.25 // 25% of the visible region
        }
        
        private func calculateDistance(from coord1: CLLocationCoordinate2D, to coord2: CLLocationCoordinate2D) -> CLLocationDistance {
            let location1 = CLLocation(latitude: coord1.latitude, longitude: coord1.longitude)
            let location2 = CLLocation(latitude: coord2.latitude, longitude: coord2.longitude)
            return location1.distance(from: location2)
        }
    
    func fetchFilteredClusters(limit: Int = 0) async {
        do {
            isLoading = true
            await clusterManager.removeAll()

            let radius = calculateRadius()
            updateFilters(radius: radius)

            if currentZoomLevel == .maxZoomOut {
                await removeAnnotations()
                isLoading = false
                return
            }

            let restaurants: [Restaurant]
            let clusters: [Cluster]

            if isZoomedEnoughForClusters {
                clusters = try await ClusterService.shared.fetchClustersWithLocation(
                    filters: self.filters,
                    center: self.currentRegion.center,
                    radiusInM: radius,
                    zoomLevel: currentZoomLevel.rawValue,
                    limit: limit
                )
                restaurants = []
                print("DEBUG: Fetched \(clusters.count) clusters")
            } else {
                restaurants = try await RestaurantService.shared.fetchRestaurants(
                    withFilters: self.filters,
                    limit: limit
                )
                clusters = []
                print("DEBUG: Fetched \(restaurants.count) restaurants")
            }

            await MainActor.run {
                self.restaurants = restaurants

                self.largeClusters = clusters.map { cluster in
                    LargeClusterAnnotation(
                        id: UUID(),
                        coordinate: CLLocationCoordinate2D(latitude: cluster.center.latitude, longitude: cluster.center.longitude),
                        count: cluster.count,
                        memberAnnotations: cluster.restaurants
                    )
                }

                let restaurantAnnotations: [RestaurantMapAnnotation] = restaurants.compactMap { restaurant in
                    guard let coordinates = restaurant.coordinates else { return nil }
                    return RestaurantMapAnnotation(coordinate: coordinates, restaurant: restaurant)
                }

                Task {
                    await self.clusterManager.add(restaurantAnnotations)
                    await self.reloadAnnotations()
                }
            }

            isLoading = false
        } catch {
            print("DEBUG: Failed to fetch clusters \(error.localizedDescription)")
            isLoading = false
        }
    }
    func removeAnnotations() async {
        await clusterManager.removeAll()
        await reloadAnnotations()
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
        return min(max(adjustedRadius, 500), 50000)
    }
    func reloadAnnotations() async {
        let changes = await clusterManager.reload(mapViewSize: mapSize, coordinateRegion: currentRegion)
        await applyChanges(changes)
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

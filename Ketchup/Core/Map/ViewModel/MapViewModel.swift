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
enum ZoomLevel: String {
    case maxZoomOut = "max_zoom_out"
    case region = "region"
    case city = "city"
    case neighborhood = "neighborhood"
}
@MainActor
class MapViewModel: ObservableObject {
    let clusterManager = ClusterManager<RestaurantMapAnnotation>()
    @Published var visibleRestaurants: [ClusterRestaurant] = []
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
    private var allClusters: [Cluster] = []
    
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
            } else if span.longitudeDelta > 0.04 {
                return .region
            } else if span.longitudeDelta > 0.007 {
                return .city
            } else {
                return .neighborhood
            }
        }
    
 
    func updateMapState(newRegion: MKCoordinateRegion) {
            let newZoomLevel = determineZoomLevel(for: newRegion)
            
            fetchTask?.cancel()
            
            fetchDebouncer.schedule { [weak self] in
                guard let self = self else { return }
                
                self.fetchTask = Task { @MainActor in
                    if Task.isCancelled { return }
                    
                    let shouldFetch = self.shouldFetchNewData(newRegion: newRegion, newZoomLevel: newZoomLevel)
                    
                    if shouldFetch {
                        self.currentRegion = newRegion
                        self.currentZoomLevel = newZoomLevel
                        
                        if self.clusters.isEmpty || newZoomLevel == .maxZoomOut {
                            await self.fetchFilteredClusters()
                        } else {
                            self.updateVisibleData(for: newRegion, zoomLevel: newZoomLevel)
                        }
                        
                        self.lastFetchedRegion = newRegion
                    }
                }
            }
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

               let fetchedClusters = try await ClusterService.shared.fetchClustersWithLocation(
                   filters: self.filters,
                   center: self.currentRegion.center,
                   radiusInM: radius,
                   zoomLevel: currentZoomLevel.rawValue,
                   limit: limit
               )

               await MainActor.run {
                   self.allClusters = fetchedClusters
                   updateVisibleData(for: currentRegion, zoomLevel: currentZoomLevel)
               }

               isLoading = false
           } catch {
               print("DEBUG: Failed to fetch clusters \(error.localizedDescription)")
               isLoading = false
           }
       }

       private func updateVisibleData(for region: MKCoordinateRegion, zoomLevel: ZoomLevel) {
           if zoomLevel == .neighborhood || zoomLevel == .city {
               // Show individual restaurants
               visibleRestaurants = allClusters.flatMap { $0.restaurants }
               largeClusters = []
           } else {
               // Show clusters
               visibleRestaurants = []
               largeClusters = allClusters.map { cluster in
                   LargeClusterAnnotation(
                       id: UUID(),
                       coordinate: CLLocationCoordinate2D(latitude: cluster.center.latitude, longitude: cluster.center.longitude),
                       count: cluster.count,
                       memberAnnotations: cluster.restaurants
                   )
               }
           }

           updateAnnotations()
       }

    private func updateAnnotations() {
        let restaurantAnnotations = visibleRestaurants.map { restaurant in
            let coordinate = CLLocationCoordinate2D(latitude: restaurant.geoPoint.latitude, longitude: restaurant.geoPoint.longitude)
            return RestaurantMapAnnotation(coordinate: coordinate, restaurant: restaurant)
        }

        Task {
            await clusterManager.removeAll()
            await clusterManager.add(restaurantAnnotations)
            await reloadAnnotations()
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
            return max(region.span.longitudeDelta, region.span.latitudeDelta) * 111000 * 0.20 // 25% of the visible region
        }
        
        private func calculateDistance(from coord1: CLLocationCoordinate2D, to coord2: CLLocationCoordinate2D) -> CLLocationDistance {
            let location1 = CLLocation(latitude: coord1.latitude, longitude: coord1.longitude)
            let location2 = CLLocation(latitude: coord2.latitude, longitude: coord2.longitude)
            return location1.distance(from: location2)
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
        return min(max(adjustedRadius, 500), 5000) * 0.8
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
    var restaurant: ClusterRestaurant
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

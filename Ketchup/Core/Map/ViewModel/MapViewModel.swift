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
enum MapMode {
    case following
    case all
}
@MainActor
class MapViewModel: ObservableObject {
    let clusterManager = ClusterManager<RestaurantMapAnnotation>()
    @Published var visibleRestaurants: [ClusterRestaurant] = []
    @Published var filters: [String: [Any]] = [:]
    @Published var selectedCuisines: [String] = []{
        didSet {
            updateFilters(radius: calculateRadius())
        }
    }
    @Published var selectedPrice: [String] = []{
        didSet {
            updateFilters(radius: calculateRadius())
        }
    }
    @Published var selectedRating: Double = 0.0 {
        didSet {
            print(selectedRating)
            updateFilters(radius: calculateRadius())
        }
    }
    @Published var selectedLocation: [CLLocationCoordinate2D] = []
    @Published var annotations: [RestaurantMapAnnotation] = []
    @Published var clusters: [ExampleClusterAnnotation] = []
    @Published var largeClusters: [LargeClusterAnnotation] = []
    @Published var currentRegion: MKCoordinateRegion = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 34.0549, longitude: -118.2426), span: MKCoordinateSpan(latitudeDelta: 0.03, longitudeDelta: 0.03))
    @Published var isLoading = false
    @Published var currentZoomLevel: ZoomLevel = .neighborhood
    @Published var lastFetchedRegion: MKCoordinateRegion?
    
    private var fetchTask: Task<Void, Never>?
    private let fetchDebouncer = Debouncer(delay: 0.3)
    @Published var allClusters: [Cluster] = [] {
        didSet {
            self.flattenedRestaurants = allClusters.flatMap { $0.restaurants }
        }
    }
    @Published var flattenedRestaurants: [ClusterRestaurant] = []
    
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
        } else if span.longitudeDelta > 0.06 {
            return .region
        } else  {
            return .city
        }
    }
    
    
    func updateMapState(newRegion: MKCoordinateRegion, shouldAutoFetch: Bool = false) {
        let newZoomLevel = determineZoomLevel(for: newRegion)
        
        fetchTask?.cancel()
        
        fetchDebouncer.schedule { [weak self] in
            guard let self = self else { return }
            self.fetchTask = Task { @MainActor in
                if Task.isCancelled { return }
                
                let shouldFetch = self.shouldFetchNewData(newRegion: newRegion, newZoomLevel: newZoomLevel)
                
                if shouldFetch || shouldAutoFetch{
                    self.currentRegion = newRegion
                    self.currentZoomLevel = newZoomLevel
                    
                    if self.clusters.isEmpty || newZoomLevel == .maxZoomOut {
                        self.lastFetchedRegion = newRegion
                        await self.fetchFilteredClusters()
                    } else {
                        self.updateVisibleData(for: newRegion, zoomLevel: newZoomLevel)
                    }
                    
                   
                }
            }
        }
    }
    func centerMapOnLocation(location: CLLocation) {
        let newRegion = MKCoordinateRegion(
            center: location.coordinate,
            span: currentRegion.span // Keep the current span to maintain zoom level
        )
        selectedLocation = [location.coordinate]
        currentRegion = newRegion
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
            if determineZoomLevel(for: currentRegion) == .maxZoomOut {
                return
            }
            print(filters)
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
            ////print("DEBUG: Failed to fetch clusters \(error.localizedDescription)")
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
        var multiplier = 0.08
        if currentZoomLevel == .city{
            multiplier = 0.08
        } else if currentZoomLevel == .region {
            multiplier = 0.18
        }
                    
        return min(region.span.longitudeDelta, region.span.latitudeDelta) * 111000 * multiplier // 25% of the visible region
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
        applyChanges(changes)
    }
    private func updateFilters(radius: Double) {
        if selectedCuisines.isEmpty {
            filters.removeValue(forKey: "macrocategory")
        } else {
            filters["macrocategory"] = selectedCuisines
        }
        if selectedPrice.isEmpty {
            filters.removeValue(forKey: "price")
        } else {
            filters["price"] = selectedPrice
        }
        
        // Add rating filter
        if selectedRating > 0 {
            filters["overallRating"] = [selectedRating]
        } else {
            filters.removeValue(forKey: "overallRating")
        }
        // Update location filter
        if selectedLocation.isEmpty {
            filters.removeValue(forKey: "location")
        } else {
            filters["location"] = selectedLocation + [radius]
        }
    }
    private func applyChanges(_ difference: ClusterManager<RestaurantMapAnnotation>.Difference) {
        for removal in difference.removals {
            switch removal {
            case .annotation(let annotation):
                annotations.removeAll { $0 == annotation }
            case .cluster(let clusterAnnotation):
                clusters.removeAll { $0.id == clusterAnnotation.id.uuidString }
            }
        }
        for insertion in difference.insertions {
            switch insertion {
            case .annotation(let newItem):
                annotations.append(newItem)
            case .cluster(let newItem):
                clusters.append(ExampleClusterAnnotation(
                    id: newItem.id.uuidString,
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
    func clearData() {
        visibleRestaurants = []
        annotations = []
        clusters = []
        largeClusters = []
        allClusters = []
        // Reset other properties if necessary
    }
}



class RestaurantMapAnnotation: NSObject, MKAnnotation, CoordinateIdentifiable, Identifiable, IdentifiableAnnotation {
    var id: String = UUID().uuidString
    var coordinate: CLLocationCoordinate2D
    let restaurant: ClusterRestaurant
    var title: String?
    var isSelected: Bool = false // Add this property

    init(coordinate: CLLocationCoordinate2D, restaurant: ClusterRestaurant) {
        self.coordinate = coordinate
        self.restaurant = restaurant
        self.title = restaurant.name
        super.init()
    }
}
protocol IdentifiableAnnotation: MKAnnotation {
    var id: String { get }
}
// MARK: - ExampleClusterAnnotation
class ExampleClusterAnnotation: NSObject, MKAnnotation, CoordinateIdentifiable, Identifiable, IdentifiableAnnotation {
    var id: String = UUID().uuidString
    var coordinate: CLLocationCoordinate2D
    let count: Int
    let memberAnnotations: [RestaurantMapAnnotation]
    var title: String?
    var isSelected: Bool = false // Add this property

    init(id: String, coordinate: CLLocationCoordinate2D, count: Int, memberAnnotations: [RestaurantMapAnnotation]) {
        self.id = id
        self.coordinate = coordinate
        self.count = count
        self.memberAnnotations = memberAnnotations
        self.title = "Cluster of \(count) Restaurants"
        super.init()
    }
}

// MARK: - LargeClusterAnnotation
class LargeClusterAnnotation: NSObject, MKAnnotation, CoordinateIdentifiable, Identifiable, IdentifiableAnnotation  {
    var id: String = UUID().uuidString
    var coordinate: CLLocationCoordinate2D
    let count: Int
    let memberAnnotations: [ClusterRestaurant]
    var title: String? // Add this line
    
    init(coordinate: CLLocationCoordinate2D, count: Int, memberAnnotations: [ClusterRestaurant]) {
        self.coordinate = coordinate
        self.count = count
        self.memberAnnotations = memberAnnotations
        self.title = "Cluster of \(count) Restaurants" // Set an appropriate title
        super.init()
    }
} 

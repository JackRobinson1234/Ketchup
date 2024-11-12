//
//  PostMapViewModel.swift
//  Ketchup
//
//  Created by Jack Robinson on 9/3/24.
//

import Foundation
import SwiftUI
import MapKit
import FirebaseFirestore
import ClusterMap
import FirebaseAuth
@MainActor
enum PostZoomLevel: String {
    case maxZoomOut = "max_zoom_out"
    case region = "region"
    case city = "city"
    //case neighborhood = "neighborhood"
}
@MainActor
class FollowingPostsMapViewModel: ObservableObject {
    let clusterManager = ClusterManager<GroupedPostMapAnnotation>()
    @Published var visiblePosts: [SimplifiedPost] = []
    @Published var annotations: [GroupedPostMapAnnotation] = []
    @Published var clusters: [GroupedPostClusterAnnotation] = []
    @Published var currentRegion: MKCoordinateRegion = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 34.0549, longitude: -118.2426), span: MKCoordinateSpan(latitudeDelta: 0.03, longitudeDelta: 0.03))
    @Published var filters: [String: [Any]] = [:]
    @Published var selectedCuisines: [String] = []{
        didSet {
            updateFilters()
        }
    }
    @Published var selectedPrice: [String] = []{
        didSet {
            updateFilters()
        }
    }
    @Published var lastFetchedRegion: MKCoordinateRegion?

    @Published var isLoading = false
    @Published var currentZoomLevel: ZoomLevel = .city
    @Published var selectedLocation: [CLLocationCoordinate2D] = []
    private var fetchTask: Task<Void, Never>?
    private let fetchDebouncer = Debouncer(delay: 0.3)
    var mapSize: CGSize = .zero

    func updateMapState(newRegion: MKCoordinateRegion, shouldAutoFetch: Bool = false) {
            let newZoomLevel = determineZoomLevel(for: newRegion)
            ////print("DEBUG: New zoom level determined: \(newZoomLevel)")
            
            fetchTask?.cancel()
            ////print("DEBUG: Previous fetch task cancelled, if any.")

            fetchDebouncer.schedule { [weak self] in
                guard let self = self else {
                    ////print("DEBUG: Self is nil, aborting scheduled fetch.")
                    return
                }
                self.fetchTask = Task { @MainActor in
                    if Task.isCancelled {
                        ////print("DEBUG: Fetch task was cancelled, aborting.")
                        return
                    }

                    let shouldFetch = self.shouldFetchNewData(newRegion: newRegion, newZoomLevel: newZoomLevel)
                    print("DEBUG: Should fetch new data: \(shouldFetch)")

                    if shouldFetch || shouldAutoFetch{
                        print("DEBUG: Fetching new data...")
                        self.currentRegion = newRegion
                        self.currentZoomLevel = newZoomLevel
                        await self.fetchFollowingPosts()
                        self.lastFetchedRegion = newRegion
                        print("DEBUG: Data fetch complete, region updated.")
                    } else {
                        print("DEBUG: No need to fetch new data, updating clusters only.")
                        self.currentRegion = newRegion
                        self.currentZoomLevel = newZoomLevel
                        self.updateAnnotations()
                    }
                }
            }
        }
    func determineZoomLevel(for region: MKCoordinateRegion, maxZoomOutSpan: Double = 0.2) -> ZoomLevel {
        let span = region.span
        if span.longitudeDelta > maxZoomOutSpan {
            return .maxZoomOut
        } else if span.longitudeDelta > 0.05 {
            return .maxZoomOut
        } else {
            return .city
        }
    }

    private func shouldFetchNewData(newRegion: MKCoordinateRegion, newZoomLevel: ZoomLevel) -> Bool {
        if currentZoomLevel == .maxZoomOut {
            return false
        }
        guard let lastFetchedRegion = lastFetchedRegion else {
            ////print("DEBUG: No last fetched region, performing initial fetch.")
            return true // First fetch
        }
        

        if newZoomLevel != currentZoomLevel {
            ////print("DEBUG: Zoom level has changed from \(currentZoomLevel) to \(newZoomLevel), fetching new data.")
            return true
        }
       

        let distanceThreshold = MapUtils.calculateDistanceThreshold(for: newRegion)
        ////print("DEBUG: Distance threshold calculated: \(distanceThreshold) km")

        let distance = calculateDistance(from: lastFetchedRegion.center, to: newRegion.center)
        ////print("DEBUG: Distance moved from last fetched region: \(distance) km")

        let shouldFetch = distance >= distanceThreshold
        print("DEBUG: Should fetch based on distance: \(shouldFetch)")
        
        return shouldFetch
    }
    
    private func calculateDistance(from coord1: CLLocationCoordinate2D, to coord2: CLLocationCoordinate2D) -> CLLocationDistance {
            let location1 = CLLocation(latitude: coord1.latitude, longitude: coord1.longitude)
            let location2 = CLLocation(latitude: coord2.latitude, longitude: coord2.longitude)
            return location1.distance(from: location2) / 1000 // Convert to kilometers
        }
    func fetchFollowingPosts() async {
        ////print("DEBUG: Fetching Following Posts")
        guard let currentUserID = Auth.auth().currentUser?.uid else { return }
        if determineZoomLevel(for: currentRegion) == .maxZoomOut {
            return
        }
        
        do {
            updateFilters()
            isLoading = true
            await clusterManager.removeAll()
            // Define filters if needed
            
            // Calculate the radius based on the current region
            let radiusInM = calculateRadius()
            
            // Fetch posts using the new function
            let posts = try await ClusterService.shared.fetchFollowerPostsWithLocation(
                filters: filters,
                center: currentRegion.center,
                radiusInM: radiusInM,
                zoomLevel: currentZoomLevel.rawValue
            )
            await MainActor.run {
                self.visiblePosts = posts
                let groupedPosts = Dictionary(grouping: visiblePosts) { $0.restaurant.id }
                let groupedAnnotations = groupedPosts.compactMap { (restaurantId, posts) -> GroupedPostMapAnnotation? in
                    guard let firstPost = posts.first,
                          let coordinate = firstPost.coordinates else { return nil }
                    let uniqueUserCount = Set(posts.map { $0.user.id }).count
                    return GroupedPostMapAnnotation(
                        coordinate: coordinate,
                        restaurant: firstPost.restaurant,
                        postCount: posts.count,
                        userCount: uniqueUserCount,
                        posts: posts
                    )
                }
                Task {
                    await clusterManager.removeAll()
                    await clusterManager.add(groupedAnnotations)
                    await reloadAnnotations()
                }
                //self.updateAnnotations()
                self.selectedLocation = [self.currentRegion.center]
            }
            isLoading = false
        } catch {
            ////print("ERROR: Failed to fetch following posts: \(error.localizedDescription)")
            isLoading = false
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
        return min(max(adjustedRadius, 500), 5000) * 0.8
    }
    private func updateAnnotations() {
            Task {
                await reloadAnnotations()
            }
        }


    func reloadAnnotations() async {
        let changes = await clusterManager.reload(mapViewSize: mapSize, coordinateRegion: currentRegion)
        applyChanges(changes)
    }

    private func applyChanges(_ difference: ClusterManager<GroupedPostMapAnnotation>.Difference) {
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
                clusters.append(GroupedPostClusterAnnotation(
                    id: newItem.id,
                    coordinate: newItem.coordinate,
                    count: newItem.memberAnnotations.count,
                    memberAnnotations: newItem.memberAnnotations
                ))
            }
        }
        
    }
    private func updateFilters() {
        if selectedCuisines.isEmpty {
            filters.removeValue(forKey: "restaurant.cuisine")
        } else {
            filters["restaurant.cuisine"] = selectedCuisines
        }
        if selectedPrice.isEmpty {
            filters.removeValue(forKey: "restaurant.price")
        } else {
            filters["restaurant.price"] = selectedPrice
        }
        ////print("updatedFilters", filters)
    }
    
}
class GroupedPostMapAnnotation: NSObject, MKAnnotation, CoordinateIdentifiable, Identifiable {
    let id = UUID()
    var coordinate: CLLocationCoordinate2D
    var restaurant: PostRestaurant
    var postCount: Int
    var userCount: Int
    var posts: [SimplifiedPost]
    var title: String?

    init(coordinate: CLLocationCoordinate2D, restaurant: PostRestaurant, postCount: Int, userCount: Int, posts: [SimplifiedPost]) {
        self.coordinate = coordinate
        self.restaurant = restaurant
        self.postCount = postCount
        self.userCount = userCount
        self.posts = posts
        self.title = "\(restaurant.name) (\(postCount) posts)"
        super.init()
    }
}
class GroupedPostClusterAnnotation: NSObject, MKAnnotation, Identifiable {
    let id: UUID
    var coordinate: CLLocationCoordinate2D
    var count: Int
    var memberAnnotations: [GroupedPostMapAnnotation]
    var title: String?

    init(id: UUID, coordinate: CLLocationCoordinate2D, count: Int, memberAnnotations: [GroupedPostMapAnnotation]) {
        self.id = id
        self.coordinate = coordinate
        self.count = count
        self.memberAnnotations = memberAnnotations
        self.title = "Cluster of \(count) Posts"
        super.init()
    }
}

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
import GeoFire
import GeohashKit

class FiltersViewModel: ObservableObject {
    @ObservedObject var feedViewModel: FeedViewModel
    
    @Published var filters: [String: [Any]] = [:]
    @Published var selectedCuisines: [String] = []
    @Published var selectedPrice: [String] = []
    @Published var selectedDietary: [String] = []
    @Published var selectedCookingTime: [Int] = []
    
    @Published var city: String?
    @Published var state: String?
    @Published var surroundingGeohash: String?
    @Published var surroundingCounty: String = "Nearby"
    
    private let locationManager = CLLocationManager()
    
    var hasNonLocationFilters: Bool {
        return filters.filter { $0.key != "restaurant.truncatedGeohash" }.isEmpty == false
    }
    
    init(feedViewModel: FeedViewModel) {
        self.feedViewModel = feedViewModel
        setupLocationManager()
        loadInitialLocation()
    }
    
    private func setupLocationManager() {
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
    }
    
    private func loadInitialLocation() {
        if let location = locationManager.location {
            updateLocation(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
        } else if let userSession = AuthService.shared.userSession,
                  let userLocation = userSession.location,
                  let geoPoint = userLocation.geoPoint {
            updateLocation(latitude: geoPoint.latitude, longitude: geoPoint.longitude)
        }
    }
    
    func updateLocation(latitude: Double, longitude: Double) {
        surroundingGeohash = GFUtils.geoHash(forLocation: CLLocationCoordinate2D(latitude: latitude, longitude: longitude))
        reverseGeocodeLocation(latitude: latitude, longitude: longitude)
    }
    
    private func reverseGeocodeLocation(latitude: Double, longitude: Double) {
        let location = CLLocation(latitude: latitude, longitude: longitude)
        let geocoder = CLGeocoder()
        
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Reverse geocoding error: \(error.localizedDescription)")
                return
            }
            
            if let placemark = placemarks?.first {
                self.city = placemark.locality
                self.state = placemark.administrativeArea
                self.surroundingCounty = placemark.subAdministrativeArea ?? "Nearby"
            }
        }
    }
    
    func fetchFilteredPosts() async {
        if let geohash = surroundingGeohash {
            let geohashPrefix = String(geohash.prefix(4))
            filters["restaurant.truncatedGeohash"] = geohashNeighbors(geohash: geohashPrefix)
        } else {
            filters.removeValue(forKey: "restaurant.truncatedGeohash")
        }
        
        // Add other filters (cuisine, price, etc.) here...
        
        do {
            feedViewModel.filters = filters
            feedViewModel.isInitialLoading = true
            try await feedViewModel.fetchInitialPosts()
            feedViewModel.isInitialLoading = false
        } catch {
            print("Error fetching filtered posts: \(error)")
        }
    }
    
    private func geohashNeighbors(geohash: String) -> [String] {
        if let geoHash = Geohash(geohash: geohash) {
            if let neighbors = geoHash.neighbors {
                let neighborGeohashes = neighbors.all.map { $0.geohash }
                return [geohash] + neighborGeohashes
            }
        }
        return [geohash]
    }
    
    func clearFilters() {
        selectedCuisines = []
        selectedPrice = []
        selectedDietary = []
        selectedCookingTime = []
        loadInitialLocation()
        filters = [:]
    }
}

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
    
    //@Published var filters: [String: [Any]] = [:]
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
        if let filters = feedViewModel.filters{
            return filters.filter { $0.key != "restaurant.truncatedGeohash" }.isEmpty == false
        }
        return false
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
                //print("Reverse geocoding error: \(error.localizedDescription)")
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
        /// if no cuisines are passed in, then it removes the value from filters, otherwise adds it as a parameter to be passed into fetchPosts
        if var filters = feedViewModel.filters {
            if selectedCuisines.isEmpty {
                filters.removeValue(forKey: "restaurant.cuisine")
            } else {
                filters["restaurant.cuisine"] = selectedCuisines
            }
            /// checks to see if selectedPostTypes has both selected. If it does, it doesn't pass it as a parameter to fetchPosts.
            
            ///Price checking if there are any selected
            if selectedPrice.isEmpty {
                filters.removeValue(forKey: "restaurant.price")
            } else {
                filters["restaurant.price"] = selectedPrice
            }
            ///Dietary checking if there are any selected
            ////print("Filters", filters)
            do{
                feedViewModel.filters = filters
                feedViewModel.isInitialLoading = true
                try await feedViewModel.fetchInitialPosts(withFilters: filters)
                feedViewModel.isInitialLoading = false
            } catch {
                ////print("Error")
            }
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
       
    }
}

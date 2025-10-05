//
//  SearchViewModel.swift
//  Ketchup
//
//  Created by Jack Robinson on 6/24/24.
//

import InstantSearch
import InstantSearchCore
import InstantSearchSwiftUI
import Foundation
import SwiftUI
import CoreLocation

final class SearchViewModel: ObservableObject {
    @Published var searchConfig: SearchModelConfig
    @Published var searchQuery: String = ""
    @Published var locationSearchTerm: String = ""
    @Published var collectionHits: PaginatedDataViewModel<AlgoliaHitsPage<Hit<Collection>>>
    @Published var userHits: PaginatedDataViewModel<AlgoliaHitsPage<Hit<User>>>
    @Published var restaurantHits: PaginatedDataViewModel<AlgoliaHitsPage<Hit<Restaurant>>>
    private var restaurantItemsSearcher: HitsSearcher
    private var collectionsItemsSearcher: HitsSearcher
    private var usersItemsSearcher: HitsSearcher
    private var filterState = FilterState()
    let appID: ApplicationID = ""
    let apiKey: APIKey = ""
    @Published var selectedLocation: CLLocation?
    
    init(initialSearchConfig: SearchModelConfig) {
        self.searchConfig = initialSearchConfig
        self.restaurantItemsSearcher = HitsSearcher(appID: appID, apiKey: apiKey, indexName: "restaurants7")
        self.collectionsItemsSearcher = HitsSearcher(appID: appID, apiKey: apiKey, indexName: "collections")
        self.usersItemsSearcher = HitsSearcher(appID: appID, apiKey: apiKey, indexName: "users")
        
        let privateFilter = Filter.Facet(attribute: "privateMode", boolValue: false)
        self.filterState[and: "privateMode"].add(privateFilter)
        self.collectionsItemsSearcher.connectFilterState(filterState)
        self.searchQuery = ""
        self.collectionHits = collectionsItemsSearcher.paginatedData(of: Hit<Collection>.self)
        self.userHits = usersItemsSearcher.paginatedData(of: Hit<User>.self)
        self.restaurantHits = restaurantItemsSearcher.paginatedData(of: Hit<Restaurant>.self)

    }
    
    func notifyQueryChanged() {
        switch searchConfig {
        case .users:
            usersItemsSearcher.request.query.query = searchQuery
            usersItemsSearcher.search()
        case .restaurants:
            restaurantItemsSearcher.request.query.query = searchQuery
            // Add location-based filtering here if needed
            if let location = selectedLocation {
                //print("LOCATION", location)
                restaurantItemsSearcher.request.query.aroundLatLng = .init(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
            }
            restaurantItemsSearcher.search()
        case .collections:
            collectionsItemsSearcher.request.query.query = searchQuery
            collectionsItemsSearcher.search()
        }
    }

    func clearLocationSearchTerm() {
        locationSearchTerm = ""
    }

    func updateSelectedLocation(_ location: CLLocation) {
        selectedLocation = location
        updateLocationSearchTerm()
    }

    private func updateLocationSearchTerm() {
        guard let location = selectedLocation else { return }
        
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
            guard let self = self, let placemark = placemarks?.first else {
                //print("Reverse geocoding failed: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            if location == LocationManager.shared.userLocation {
                self.locationSearchTerm = "Current location"
            } else {
                self.locationSearchTerm = [placemark.locality, placemark.administrativeArea]
                    .compactMap { $0 }
                    .joined(separator: ", ")
            }
        }
    }
}


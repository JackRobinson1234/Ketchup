//
//  SwiftUIView.swift
//  Ketchup
//
//  Created by Jack Robinson on 9/13/24.
//

import SwiftUI
import MapKit
struct RestaurantLocationSearchView: View {
    @Binding var inSearchView: Bool
    @Binding var isLocationSearchActive: Bool
    @StateObject private var mapSearch = MapSearch()
    @FocusState private var isFocused: Bool
    @State private var currentLocation: CLLocation?
    @State private var isCurrentLocation: Bool = true
    @State private var displayLocationText: String = ""
    @ObservedObject var searchViewModel: SearchViewModel
    @State private var hasSelectedNewLocation: Bool = false
    @State private var previousLocation: CLLocation?
    @State private var isLoadingLocation: Bool = true

    var autoCompleteNumber: Int = 4
    
    var body: some View {
        VStack {
            HStack {
                Image(systemName: "location")
                    .foregroundColor(Color("Colors/AccentColor"))
                ZStack(alignment: .leading) {
                    TextField("", text: $mapSearch.searchTerm)
                        .font(.custom("MuseoSansRounded-500", size: 16))
                        .focused($isFocused)
                        .onChange(of: isFocused) { newValue in
                            isLocationSearchActive = newValue
                            if newValue {
                                mapSearch.searchTerm = ""
                            } else {
                                updateDisplayLocation()
                            }
                        }
                    if mapSearch.searchTerm.isEmpty {
                        Text(isFocused ? "Search for a location" : displayLocationText)
                            .font(.custom("MuseoSansRounded-500", size: 16))
                            .foregroundColor(isFocused ? .gray : (isCurrentLocation ? .red : .black))
                            .onTapGesture {
                                isFocused = true
                            }
                    }
                }
                if isFocused && !mapSearch.searchTerm.isEmpty {
                    Button(action: {
                        mapSearch.searchTerm = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(8)
            .background(Color(.systemGray6))
            .cornerRadius(10)
            .padding(.horizontal)
            
            if isFocused && !mapSearch.locationResults.isEmpty {
                List(mapSearch.locationResults.prefix(autoCompleteNumber), id: \.self) { location in
                    Button(action: {
                        reverseGeo(location: location)
                    }) {
                        VStack{
                            HStack {
                                Image(systemName: "location")
                                    .foregroundColor(.gray)
                                    .font(.custom("MuseoSansRounded-500", size: 16))
                                Text(location.title)
                                    .foregroundColor(.primary)
                                    .font(.custom("MuseoSansRounded-500", size: 16))
                                Spacer()
                            }
                            HStack{
                                Text(location.subtitle)
                                    .foregroundColor(.secondary)
                                    .font(.custom("MuseoSansRounded-300", size: 14))
                                Spacer()
                            }
                        }
                    }
                }
                .listStyle(PlainListStyle())
            }
        }
        .onAppear(perform: loadInitialLocation)
        .onChange(of: inSearchView) { newValue in
            if !newValue {
                updateDisplayLocation()
                isFocused = false
                isLocationSearchActive = false
            }
        }
    }
    
    private func loadInitialLocation() {
        isLoadingLocation = true
        LocationManager.shared.requestLocation { success in
            DispatchQueue.main.async {
                if success, let location = LocationManager.shared.userLocation {
                    currentLocation = location
                    previousLocation = location
                    searchViewModel.selectedLocation = location
                    isCurrentLocation = true
                } else if let location = searchViewModel.selectedLocation {
                    currentLocation = location
                    previousLocation = location
                    isCurrentLocation = false
                } else if let geoPoint = AuthService.shared.userSession?.location?.geoPoint {
                    let location = CLLocation(latitude: geoPoint.latitude, longitude: geoPoint.longitude)
                    currentLocation = location
                    previousLocation = location
                    searchViewModel.selectedLocation = location
                    isCurrentLocation = false
                }
                isLoadingLocation = false
                updateDisplayLocation()
            }
        }
    }
    
    private func updateDisplayLocation() {
        guard let location = searchViewModel.selectedLocation else { return }
        reverseGeocodeLocation(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
    }
    
    private func reverseGeocodeLocation(latitude: Double, longitude: Double) {
        let location = CLLocation(latitude: latitude, longitude: longitude)
        CLGeocoder().reverseGeocodeLocation(location) { placemarks, error in
            guard let placemark = placemarks?.first else {
                //print("Reverse geocoding failed: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            DispatchQueue.main.async {
                if isCurrentLocation {
                    displayLocationText = "Current location"
                } else {
                    let mainComponents = [placemark.locality, placemark.administrativeArea]
                           .compactMap { $0 }
                           .joined(separator: ", ")
                       
                       let subLocalityComponent = placemark.subLocality.map { " (\($0))" } ?? ""
                       
                       displayLocationText = mainComponents + subLocalityComponent
                }
                if !isFocused {
                    mapSearch.searchTerm = displayLocationText
                }
            }
        }
    }
    
    private func reverseGeo(location: MKLocalSearchCompletion) {
        let searchRequest = MKLocalSearch.Request(completion: location)
        let search = MKLocalSearch(request: searchRequest)
        search.start { (response, error) in
            guard let coordinate = response?.mapItems.first?.placemark.coordinate else {
                //print("Failed to get coordinates: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
            searchViewModel.selectedLocation = location
            
            searchViewModel.searchQuery = ""
            searchViewModel.notifyQueryChanged()
            isCurrentLocation = false
            updateDisplayLocation()
            
            inSearchView = false
            isFocused = false
        }
    }
}

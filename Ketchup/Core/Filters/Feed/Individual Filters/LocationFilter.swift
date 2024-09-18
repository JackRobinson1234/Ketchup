//
//  LocationFilter.swift
//  Foodi
//  Created by Jack Robinson on 4/6/24.
//
import SwiftUI
import Combine
import CoreLocation
import MapKit
import GeoFire

import SwiftUI
import MapKit
import CoreLocation

struct LocationFilter: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var feedViewModel: FeedViewModel
    @StateObject private var mapSearch = MapSearch()
    @FocusState private var isFocused: Bool
    @State private var isUsingCurrentLocation: Bool = false
    @State private var selectedLocation: CLLocation?
    @State private var displayLocationText: String = "Select a city"
    @State private var isAnywhereSelected: Bool = false
    @State private var isLoadingLocation: Bool = false

    // Temporary state variables to hold the selections
    @State private var tempCurrentLocationFilter: FeedLocationSetting = .surrounding
    @State private var tempCity: String?
    @State private var tempState: String?
    @State private var tempSurroundingGeohash: String?
    @State private var tempSurroundingCounty: String = "Nearby"
    @State private var tempSelectedLocation: CLLocation?
    @State private var tempIsUsingCurrentLocation: Bool = false
    @State private var tempIncludeSurroundingArea: Bool = true

    var body: some View {
        VStack {
            VStack(alignment: .leading) {
                // Toggle between exact city and surrounding area
                Toggle(isOn: $tempIncludeSurroundingArea) {
                    Text( "Include Surrounding Area")
                        .foregroundColor(.primary)
                        .font(.custom("MuseoSansRounded-500", size: 16))
                }
                .disabled(isAnywhereSelected)
                .opacity(isAnywhereSelected ? 0.3 : 1.0)
                Toggle(isOn: $isAnywhereSelected) {
                    Text("All Locations")
                        .foregroundColor(.primary)
                        .font(.custom("MuseoSansRounded-500", size: 16))
                }
            
                    .onChange(of: isAnywhereSelected) {newValue in
                        handleAnywhereToggleChange(newValue)
                    }
                // 'Anywhere' option with checkmark
                //                Button(action: {
                //                    isAnywhereSelected.toggle()
                //                    if isAnywhereSelected {
                //                        tempCurrentLocationFilter = .anywhere
                //                        tempIsUsingCurrentLocation = false
                //                        tempSelectedLocation = nil
                //                        displayLocationText = "Anywhere"
                //                        mapSearch.searchTerm = ""
                //                    } else {
                //                        tempCurrentLocationFilter = .surrounding
                //                    }
                //                }) {
                //                    HStack {
                //                        Image(systemName: isAnywhereSelected ? "checkmark.circle.fill" : "circle")
                //                            .foregroundColor(.blue)
                //                        Text("Anywhere")
                //                            .font(.headline)
                //                    }
                //                }
            }
            .padding()
            // Search bar for city selection
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                ZStack(alignment: .leading) {
                    TextField("", text: $mapSearch.searchTerm)
                        .font(.custom("MuseoSansRounded-500", size: 16))
                        .focused($isFocused)
                        .onChange(of: isFocused) { newValue in
                            if newValue {
                                mapSearch.searchTerm = ""
                            } else {
                                updateDisplayLocation()
                            }
                        }
                    if mapSearch.searchTerm.isEmpty {
                        Text(isFocused ? "Search for a city" : displayLocationText)
                            .font(.custom("MuseoSansRounded-500", size: 16))
                            .foregroundColor(isFocused ? .gray : (isUsingCurrentLocation ? .red : .black))
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
            .padding()
            .opacity(isAnywhereSelected ? 0.3 : 1.0)
            .disabled(isAnywhereSelected)

            // Search results list
            if isFocused && !mapSearch.locationResults.isEmpty {
                List(mapSearch.locationResults.prefix(5), id: \.self) { location in
                    Button(action: {
                        selectLocation(location)
                    }) {
                        HStack {
                            Image(systemName: "location")
                                .foregroundColor(.gray)
                                .font(.custom("MuseoSansRounded-500", size: 16))
                            Text(location.title)
                                .foregroundColor(.primary)
                                .font(.custom("MuseoSansRounded-500", size: 16))
                            Spacer()
                        }
                    }
                }
                .listStyle(PlainListStyle())
            }

            Spacer()

         
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Location Filter")
                    .font(.custom("MuseoSansRounded-700", size: 16))
                    .foregroundStyle(.black)
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button{
                    applyFilters()
                    dismiss()
                } label: {
                    Text("Apply Filter")
                    .font(.custom("MuseoSansRounded-500", size: 16))
                    .foregroundStyle(Color("Colors/AccentColor"))
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            initializeTempVariables()
        }
    }

    private func initializeTempVariables() {
        tempCurrentLocationFilter = feedViewModel.currentLocationFilter
        tempCity = feedViewModel.city
        tempState = feedViewModel.state
        tempSurroundingGeohash = feedViewModel.surroundingGeohash
        tempSurroundingCounty = feedViewModel.surroundingCounty
        tempIsUsingCurrentLocation = isUsingCurrentLocation
        tempIncludeSurroundingArea = feedViewModel.currentLocationFilter == .surrounding

        if tempCurrentLocationFilter == .anywhere {
            isAnywhereSelected = true
            displayLocationText = "Anywhere"
        } else {
            isAnywhereSelected = false
            if tempSelectedLocation != nil {
                updateDisplayLocation()
            } else if let city = tempCity, let state = tempState {
                displayLocationText = "\(city), \(state)"
            } else {
                displayLocationText = "Select a city"
            }
        }
    }

    private func selectLocation(_ location: MKLocalSearchCompletion) {
        let searchRequest = MKLocalSearch.Request(completion: location)
        let search = MKLocalSearch(request: searchRequest)
        search.start { response, error in
            guard let coordinate = response?.mapItems.first?.placemark.coordinate else {
                print("Failed to get coordinates: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            tempSelectedLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
            tempIsUsingCurrentLocation = false
            updateDisplayLocation()
            isFocused = false
        }
    }

    private func updateDisplayLocation() {
        guard let location = tempSelectedLocation else { return }
        CLGeocoder().reverseGeocodeLocation(location) { placemarks, error in
            guard let placemark = placemarks?.first else {
                print("Reverse geocoding failed: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            DispatchQueue.main.async {
                if tempIsUsingCurrentLocation {
                    displayLocationText = "Current Location"
                } else {
                    displayLocationText = [placemark.locality, placemark.administrativeArea]
                        .compactMap { $0 }
                        .joined(separator: ", ")
                }
                if !isFocused {
                    mapSearch.searchTerm = displayLocationText
                }
                tempCity = placemark.locality
                tempState = placemark.administrativeArea
                tempSurroundingCounty = placemark.subAdministrativeArea ?? "Nearby"
                // Update tempSurroundingGeohash
                let geohash = GFUtils.geoHash(forLocation: coordinate2D(location))
                tempSurroundingGeohash = geohash
            }
        }
    }
    private func handleAnywhereToggleChange(_ isSelected: Bool) {
        if isSelected {
            tempCurrentLocationFilter = .anywhere
            tempIsUsingCurrentLocation = false
            tempSelectedLocation = nil
            displayLocationText = "Anywhere"
            mapSearch.searchTerm = ""
        } else {
            tempCurrentLocationFilter = .surrounding
            // Optionally reset other variables or keep them as is
        }
    }
    private func coordinate2D(_ location: CLLocation) -> CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
    }

    private func applyFilters() {
        feedViewModel.currentLocationFilter = isAnywhereSelected ? .anywhere : (tempIncludeSurroundingArea ? .surrounding : .exactCity)
        feedViewModel.city = tempCity
        feedViewModel.state = tempState
        feedViewModel.surroundingCounty = tempSurroundingCounty
        feedViewModel.surroundingGeohash = tempSurroundingGeohash

        feedViewModel.applyLocationFilter()
        Task {
            feedViewModel.isInitialLoading = true
            await feedViewModel.fetchInitialPosts()
            feedViewModel.isInitialLoading = false
        }
    }
}

//MARK: ViewModel
/// Taken from "stackoverflow.com/questions/70571615/swiftui-using-mapkit-for-address-auto-complete"
class MapSearch : NSObject, ObservableObject {
    @Published var locationResults : [MKLocalSearchCompletion] = []
    @Published var searchTerm = ""
    private var cancellables : Set<AnyCancellable> = []
    private var searchCompleter = MKLocalSearchCompleter()
    private var currentPromise : ((Result<[MKLocalSearchCompletion], Error>) -> Void)?
    
    override init() {
        super.init()
        searchCompleter.delegate = self
        searchCompleter.resultTypes = MKLocalSearchCompleter.ResultType([.address])
        
        $searchTerm
            .debounce(for: .seconds(0.2), scheduler: RunLoop.main)
            .removeDuplicates()
            .flatMap({ (currentSearchTerm) in
                self.searchTermToResults(searchTerm: currentSearchTerm)
            })
            .sink(receiveCompletion: { (completion) in
                //handle error
            }, receiveValue: { (results) in
                self.locationResults = results.filter { $0.subtitle.contains("United States") } // This parses the subtitle to show only results that have United States as the country. You could change this text to be Germany or Brazil and only show results from those countries.
            })
            .store(in: &cancellables)
    }
    
    func searchTermToResults(searchTerm: String) -> Future<[MKLocalSearchCompletion], Error> {
        Future { promise in
            self.searchCompleter.queryFragment = searchTerm
            self.currentPromise = promise
        }
    }
}


extension MapSearch : MKLocalSearchCompleterDelegate {
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        currentPromise?(.success(completer.results))
    }
    
    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        //could deal with the error here, but beware that it will finish the Combine publisher stream
        //currentPromise?(.failure(error))
    }
}

struct ReversedGeoLocation {
    let streetNumber: String    // eg. 1
    let streetName: String      // eg. Infinite Loop
    let city: String            // eg. Cupertino
    let state: String           // eg. CA
    let zipCode: String         // eg. 95014
    let country: String         // eg. United States
    let isoCountryCode: String  // eg. US
    
    var formattedAddress: String {
        return """
        \(streetNumber) \(streetName),
        \(city), \(state) \(zipCode)
        \(country)
        """
    }
    
    // Handle optionals as needed
    init(with placemark: CLPlacemark) {
        self.streetName     = placemark.thoroughfare ?? ""
        self.streetNumber   = placemark.subThoroughfare ?? ""
        self.city           = placemark.locality ?? ""
        self.state          = placemark.administrativeArea ?? ""
        self.zipCode        = placemark.postalCode ?? ""
        self.country        = placemark.country ?? ""
        self.isoCountryCode = placemark.isoCountryCode ?? ""
    }
}

//
//  LocationSearchView.swift
//  Ketchup
//
//  Created by Jack Robinson on 9/10/24.
//

import SwiftUI
import MapKit
import GeoFire

struct LocationSearchView: View {
    @ObservedObject var locationViewModel: LocationViewModel
    @StateObject private var mapSearch = MapSearch()
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isFocused: Bool
    
    var body: some View {
        NavigationView {
            VStack {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .imageScale(.small)
                    TextField("Search locations", text: $mapSearch.searchTerm)
                        .font(.custom("MuseoSansRounded-300", size: 16))
                        .focused($isFocused)
                }
                .frame(height: 44)
                .background(Color.gray.opacity(0.1))
                .padding(.horizontal)
                .cornerRadius(8)
                
                List {
                    ForEach(mapSearch.locationResults, id: \.self) { location in
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
                }
                .listStyle(PlainListStyle())
            }
            .navigationTitle("Choose Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func selectLocation(_ location: MKLocalSearchCompletion) {
        let searchRequest = MKLocalSearch.Request(completion: location)
        let search = MKLocalSearch(request: searchRequest)
        
        search.start { (response, error) in
            if let error = error {
                // Handle error
                return
            }
            
            if let placemark = response?.mapItems.first?.placemark {
                DispatchQueue.main.async {
                    locationViewModel.city = placemark.locality
                    locationViewModel.state = placemark.administrativeArea
                    
                    if let coordinate = placemark.location?.coordinate {
                        locationViewModel.selectedLocationCoordinate = coordinate
                        locationViewModel.surroundingGeohash = GFUtils.geoHash(forLocation: coordinate)
                        locationViewModel.updateLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
                    }
                }
                dismiss()
            }
        }
    }
}

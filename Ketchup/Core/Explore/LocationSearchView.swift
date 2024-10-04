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
    @Binding var city: String?
    @Binding var state: String?
    @Binding var surroundingGeohash: String?
    @Binding var surroundingCounty: String
    var onLocationSelected: () -> Void
    @StateObject private var mapSearch = MapSearch()
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isFocused: Bool
    
    private var originalCity: String? { AuthService.shared.userSession?.location?.city }
    private var originalState: String? { AuthService.shared.userSession?.location?.state }
    
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
                print("Error searching for location: \(error.localizedDescription)")
                return
            }
            
            if let placemark = response?.mapItems.first?.placemark {
                city = placemark.locality
                state = placemark.administrativeArea
                
                if let coordinate = placemark.location?.coordinate {
                    surroundingGeohash = GFUtils.geoHash(forLocation: coordinate)
                    reverseGeocodeForCounty(latitude: coordinate.latitude, longitude: coordinate.longitude)
                }
                
                onLocationSelected()
                dismiss()
            }
        }
    }
    
    private func reverseGeocodeForCounty(latitude: Double, longitude: Double) {
        let location = CLLocation(latitude: latitude, longitude: longitude)
        let geocoder = CLGeocoder()
        
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            if let error = error {
                print("Reverse geocoding error: \(error.localizedDescription)")
                return
            }
            
            if let placemark = placemarks?.first {
                if let county = placemark.subAdministrativeArea {
                    DispatchQueue.main.async {
                        surroundingCounty = county
                    }
                } else {
                    print("County information not available")
                    DispatchQueue.main.async {
                        surroundingCounty = "Nearby"
                    }
                }
            }
        }
    }
    
    private func resetToOriginalLocation() {
        city = originalCity
        state = originalState
        if let geoPoint = AuthService.shared.userSession?.location?.geoPoint {
            let coordinate = CLLocationCoordinate2D(latitude: geoPoint.latitude, longitude: geoPoint.longitude)
            surroundingGeohash = GFUtils.geoHash(forLocation: coordinate)
            reverseGeocodeForCounty(latitude: geoPoint.latitude, longitude: geoPoint.longitude)
        }
        onLocationSelected()
        dismiss()
    }
}

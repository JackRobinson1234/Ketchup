//
//  LocationSearchSheet.swift
//  Ketchup
//
//  Created by Jack Robinson on 11/8/24.
//

import SwiftUI
import MapKit
import _MapKit_SwiftUI
@available(iOS 17.0, *)
struct LocationSearchSheet: View {
    @Environment(\.dismiss) var dismiss
    @Binding var cameraPosition: MapCameraPosition
    @StateObject private var mapSearch = MapSearch()
    @FocusState private var isFocused: Bool
    var autoCompleteNumber: Int = 4
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search Bar
                HStack {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .imageScale(.small)
                            .foregroundColor(.gray)
                        TextField("Search destinations", text: $mapSearch.searchTerm)
                            .font(.custom("MuseoSansRounded-300", size: 16))
                            .focused($isFocused)
                            .autocorrectionDisabled()
                    }
                    .frame(height: 44)
                    .padding(.horizontal)
                    .background(Color(UIColor.systemGray6))
                    .cornerRadius(8)
                    
                    Button {
                        mapSearch.searchTerm = ""
                        dismiss()
                    } label: {
                        Text("Cancel")
                            .foregroundStyle(Color("Colors/AccentColor"))
                            .font(.custom("MuseoSansRounded-500", size: 14))
                    }
                }
                .padding()
                
                // Auto-complete results
                if !mapSearch.locationResults.isEmpty {
                    ScrollView {
                        VStack(spacing: 0) {
                            ForEach(mapSearch.locationResults.prefix(autoCompleteNumber), id: \.self) { location in
                                Button {
                                    reverseGeo(location: location)
                                } label: {
                                    HStack(spacing: 12) {
                                        Image(systemName: "mappin.circle.fill")
                                            .font(.title3)
                                            .foregroundColor(.gray)
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(location.title)
                                                .font(.custom("MuseoSansRounded-500", size: 16))
                                                .foregroundColor(.black)
                                            Text(location.subtitle)
                                                .font(.custom("MuseoSansRounded-300", size: 14))
                                                .foregroundColor(.gray)
                                        }
                                        Spacer()
                                    }
                                    .padding(.vertical, 12)
                                    .padding(.horizontal, 16)
                                }
                                
                                if location != mapSearch.locationResults.prefix(autoCompleteNumber).last {
                                    Divider()
                                        .padding(.horizontal)
                                }
                            }
                        }
                        .background(Color.white)
                    }
                }
                
                Spacer()
            }
            .background(Color(UIColor.systemGray6))
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        dismissKeyboard()
                    }
                }
            }
            .onAppear {
                isFocused = true
            }
        }
    }
    
    private func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    private func reverseGeo(location: MKLocalSearchCompletion) {
        let searchRequest = MKLocalSearch.Request(completion: location)
        let search = MKLocalSearch(request: searchRequest)
        var coordinateK: CLLocationCoordinate2D?
        
        search.start { (response, error) in
            if error == nil, let coordinate = response?.mapItems.first?.placemark.coordinate {
                coordinateK = coordinate
            }
            
            if let c = coordinateK {
                let location = CLLocation(latitude: c.latitude, longitude: c.longitude)
                CLGeocoder().reverseGeocodeLocation(location) { placemarks, error in
                    guard let placemark = placemarks?.first else {
                        let errorString = error?.localizedDescription ?? "Unexpected Error"
                        print("Unable to reverse geocode the given location. Error: \(errorString)")
                        return
                    }
                    
                    let reversedGeoLocation = ReversedGeoLocation(with: placemark)
                    mapSearch.searchTerm = ""
                    mapSearch.locationResults = []
                    let defaultSpan = MKCoordinateSpan(latitudeDelta: 0.07, longitudeDelta: 0.07)
                    let selectedRegion = MKCoordinateRegion(center: c, span: defaultSpan)
                    cameraPosition = .region(selectedRegion)
                    isFocused = false
                    dismiss()
                }
            }
        }
    }
}

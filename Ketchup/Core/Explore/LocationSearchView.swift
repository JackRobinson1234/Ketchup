//
//  LocationSearchView.swift
//  Ketchup
//
//  Created by Jack Robinson on 9/10/24.
//

import SwiftUI
import MapKit

struct LocationSearchView: View {
    @Binding var city: String?
    @Binding var state: String?
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
                .padding(.horizontal)
                .background(Color.white)
                .cornerRadius(8)
                
                List {
                    ForEach(mapSearch.locationResults, id: \.self) { location in
                        Button(action: {
                            selectLocation(location)
                        }) {
                            VStack(alignment: .leading) {
                                Text(location.title)
                                    .foregroundColor(.black)
                                Text(location.subtitle)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    
                }
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
                onLocationSelected()
                dismiss()
            }
        }
    }
    
    private func resetToOriginalLocation() {
        city = originalCity
        state = originalState
        onLocationSelected()
        dismiss()
    }
}

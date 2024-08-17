//
//  LocationSelectorView.swift
//  Ketchup
//
//  Created by Jack Robinson on 8/13/24.
//

import SwiftUI
import MapKit
import FirebaseFirestoreInternal

struct LocationSelectionView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var mapSearch = MapSearch()
    @State private var localSelectedLocation: Location?
    @Binding var selectedLocation: Location?
    @State private var showSearchBar = true
    @FocusState private var isFocused: Bool
    @ObservedObject var registrationViewModel: UserRegistrationViewModel
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Image("KetchupTextRed")
                .resizable()
                .scaledToFit()
                .frame(width: 200)
            
            Text("Select Your Location")
                .font(.custom("MuseoSansRounded-700", size: 26))
                .foregroundColor(.black)
          
            if showSearchBar {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    TextField("Search for your city", text: $mapSearch.searchTerm)
                        .font(.custom("MuseoSansRounded-300", size: 16))
                        .focused($isFocused)
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
            
                if !mapSearch.searchTerm.isEmpty {
                    List(mapSearch.locationResults.prefix(5), id: \.self) { location in
                        Button(action: {
                            reverseGeo(location: location)
                        }) {
                            VStack(alignment: .leading) {
                                Text(location.title)
                                    .foregroundColor(.black)
                                    .font(.custom("MuseoSansRounded-500", size: 16))
                                Text(location.subtitle)
                                    .font(.custom("MuseoSansRounded-300", size: 14))
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .listStyle(PlainListStyle())
                    .frame(height: 200)
                }
            }
            
            if let location = localSelectedLocation {
                HStack {
                    Image(systemName: "mappin.circle.fill")
                        .foregroundColor(Color("Colors/AccentColor"))
                    Text("\(location.city ?? ""), \(location.state ?? "")")
                        .font(.custom("MuseoSansRounded-500", size: 16))
                    Spacer()
                    Button(action: {
                        localSelectedLocation = nil
                        showSearchBar = true
                        mapSearch.searchTerm = ""
                        isFocused = true
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.red)
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
            }
            
            Spacer()
            
            Button(action: {
                selectedLocation = localSelectedLocation
                registrationViewModel.location = localSelectedLocation
               
                Task{
                    try await registrationViewModel.updateUser()
                }
            }) {
                if let userSession = AuthService.shared.userSession, userSession.birthday == nil {
                        Text("Save Location + Update Profile")
                            .font(.custom("MuseoSansRounded-500", size: 20))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(localSelectedLocation != nil ? Color("Colors/AccentColor") : Color.gray)
                            .cornerRadius(25)
                    } else {
                        Text("Save Location + Create Profile")
                            .font(.custom("MuseoSansRounded-500", size: 20))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(localSelectedLocation != nil ? Color("Colors/AccentColor") : Color.gray)
                            .cornerRadius(25)
                    
                }
                
                        
            }
            .disabled(localSelectedLocation == nil)
        }
        .padding()
        .navigationBarBackButtonHidden(true)
        .navigationBarItems(leading: Button(action: { dismiss() }) {
            Image(systemName: "chevron.left")
                .foregroundColor(.black)
        })
    }
    
    private func reverseGeo(location: MKLocalSearchCompletion) {
        let searchRequest = MKLocalSearch.Request(completion: location)
        let search = MKLocalSearch(request: searchRequest)
        search.start { (response, error) in
            guard let coordinate = response?.mapItems.first?.placemark.coordinate else { return }
            let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
            
            CLGeocoder().reverseGeocodeLocation(location) { placemarks, error in
                guard let placemark = placemarks?.first else {
                    print("Reverse geocoding failed: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }
                
                let city = placemark.locality ?? ""
                let state = placemark.administrativeArea ?? ""
                
                DispatchQueue.main.async {
                    self.localSelectedLocation = Location(
                        city: city,
                        state: state,
                        geoPoint: GeoPoint(latitude: coordinate.latitude, longitude: coordinate.longitude)
                    )
                    self.showSearchBar = false
                    self.mapSearch.searchTerm = ""
                    self.isFocused = false
                }
            }
        }
    }
}

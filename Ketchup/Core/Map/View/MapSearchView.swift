//
//  MapSearchView.swift
//  Foodi
//
//  Created by Jack Robinson on 2/23/24.
//

import SwiftUI
import MapKit

@available(iOS 17.0, *)
struct MapSearchView: View {
    @Binding var cameraPosition: MapCameraPosition
    @Binding var inSearchView: Bool
    @StateObject private var mapSearch = MapSearch()
    @FocusState private var isFocused: Bool
    var autoCompleteNumber: Int = 4
    var body: some View {
        // MARK: Title
        VStack{
            HStack{
                //MARK: Search
                HStack{
                    Image(systemName: "magnifyingglass")
                        .imageScale(.small)
                    TextField("Search destinations", text:  $mapSearch.searchTerm)
                        .font(.custom("MuseoSansRounded-300", size: 16))
                                        
                }
                .frame(height: 44)
                .padding(.horizontal)
                
                Button{
                    inSearchView = false
                } label: {
                    Text("Cancel")
                        .foregroundStyle(Color("Colors/AccentColor"))
                        .font(.custom("MuseoSansRounded-500", size: 14))
                        .padding(.horizontal)
                       
                }
            }
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        dismissKeyboard()
                    }
                }
            }
            .background(Color.white)
            .cornerRadius(8)
            // MARK: Auto-complete results
            if isFocused == false {
                VStack{
                    ForEach(mapSearch.locationResults.prefix(autoCompleteNumber), id: \.self) { location in
                        Button {
                            reverseGeo(location: location)
                     
                        } label: {
                            VStack{
                                HStack{
                                    VStack(alignment: .leading) {
                                        Text(location.title)
                                            .foregroundColor(Color.black)
                                        Text(location.subtitle)
                                            .font(.system(.caption))
                                            .foregroundColor(Color.black)
                                    }
                                    .padding(.horizontal)
                                    Spacer()
                                }
                            }
                        }
                        Divider()
                    }
                }
                .padding(.top)
                .background(.white)
                .cornerRadius(8)
                

            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    dismissKeyboard()
                }
            }
        }
    }
    //MARK: ReverseGeo
    
    /// Takes in the selected MKLocalSearchCompletion value and makes it into a coordinate, the reverses that coordinate into a geocode to get the address information.
    /// - Parameter location: Selected MKocalSearchCompletion from the autocomplete suggestions
    private func reverseGeo(location: MKLocalSearchCompletion) {
        let searchRequest = MKLocalSearch.Request(completion: location)
        let search = MKLocalSearch(request: searchRequest)
        var coordinateK : CLLocationCoordinate2D?
        search.start { (response, error) in
            if error == nil, let coordinate = response?.mapItems.first?.placemark.coordinate {
                coordinateK = coordinate
            }
            
            if let c = coordinateK {
                let location = CLLocation(latitude: c.latitude, longitude: c.longitude)
                CLGeocoder().reverseGeocodeLocation(location) { placemarks, error in
                    
                    guard let placemark = placemarks?.first else {
                        let errorString = error?.localizedDescription ?? "Unexpected Error"
                        //print("Unable to reverse geocode the given location. Error: \(errorString)")
                        return
                    }
                    
                    let reversedGeoLocation = ReversedGeoLocation(with: placemark)
                    mapSearch.searchTerm = ""
                    mapSearch.locationResults = []
                    let defaultSpan = MKCoordinateSpan(latitudeDelta: 0.07, longitudeDelta: 0.07)
                    let selectedRegion = MKCoordinateRegion(center: c, span: defaultSpan)
                    cameraPosition = .region(selectedRegion)
                    inSearchView = false
                    isFocused = false
                    
                }
            }
        }
    }
}

//#Preview{
//    //MapSearchView(cameraPosition: //.constant(MapCameraPosition(CLLocationCoordinate2D())))
//}

@available(iOS 16.0, *)
struct Ios16MapSearchView: View {
    @Binding var selectedLocation: CLLocationCoordinate2D?
    @Binding var inSearchView: Bool
    @StateObject private var mapSearch = MapSearch()
    @FocusState private var isFocused: Bool
    var autoCompleteNumber: Int = 4
    var body: some View {
        // MARK: Title
        VStack{
            HStack{
                //MARK: Search
                HStack{
                    Image(systemName: "magnifyingglass")
                        .imageScale(.small)
                    TextField("Search destinations", text:  $mapSearch.searchTerm)
                        .font(.custom("MuseoSansRounded-300", size: 16))
                                        
                }
                .frame(height: 44)
                .padding(.horizontal)
                
                Button{
                    inSearchView = false
                } label: {
                    Text("Cancel")
                        .foregroundStyle(Color("Colors/AccentColor"))
                        .font(.custom("MuseoSansRounded-500", size: 14))
                        .padding(.horizontal)
                       
                }
            }
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        dismissKeyboard()
                    }
                }
            }
            .background(Color.white)
            .cornerRadius(8)
            // MARK: Auto-complete results
            if isFocused == false {
                VStack{
                    ForEach(mapSearch.locationResults.prefix(autoCompleteNumber), id: \.self) { location in
                        Button {
                            reverseGeo(location: location)
                     
                        } label: {
                            HStack{
                                VStack(alignment: .leading) {
                                    Text(location.title)
                                        .foregroundColor(Color.black)
                                    Text(location.subtitle)
                                        .font(.system(.caption))
                                        .foregroundColor(Color.black)
                                }
                                .padding(.horizontal)
                                Spacer()
                            }
                        }
                        Divider()
                    }
                }
                .padding(.top)
                .background(.white)
                .cornerRadius(8)
                

            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    dismissKeyboard()
                }
            }
        }
    }
    //MARK: ReverseGeo
    
    /// Takes in the selected MKLocalSearchCompletion value and makes it into a coordinate, the reverses that coordinate into a geocode to get the address information.
    /// - Parameter location: Selected MKocalSearchCompletion from the autocomplete suggestions
    private func reverseGeo(location: MKLocalSearchCompletion) {
        let searchRequest = MKLocalSearch.Request(completion: location)
        let search = MKLocalSearch(request: searchRequest)
        search.start { (response, error) in
            if let coordinate = response?.mapItems.first?.placemark.coordinate {
                DispatchQueue.main.async {
                    selectedLocation = coordinate
                    inSearchView = false
                    isFocused = false
                }
            }
        }
    }
}

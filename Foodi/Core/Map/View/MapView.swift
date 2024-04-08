//
//  MapView.swift
//  Foodi
//
//  Created by Jack Robinson on 2/1/24.
//

import SwiftUI
import MapKit

struct MapView: View {
    @StateObject var viewModel: MapViewModel
    @State var position: MapCameraPosition /// Camera view of the map
    @State private var selectedRestaurant: Restaurant? /// Restaurant that the user clicks on
    @State private var showRestaurantPreview = false /// Restaurant Preview at bottom of screen
    @State private var inSearchView: Bool = false /// Changes the camera to be fixed on the selected restaurant(s)
    @State private var isSearchPresented: Bool = false /// Search View sheet
    @State private var isFiltersPresented: Bool = false /// Filters View Sheet
    @ObservedObject var locationManager = LocationManager.shared /// Asks for user map permission
    @State var isLoading = true /// Waiting for the viewModel to fetchRestaurants
    @Namespace var mapScope /// Sets a range for how big the map is so that the user button gets set in the right spot
    @State var cameraZoomedEnough = true /// Whether or not the longitude delta is zoomed in enough to view spots
    
    
    
    init() {
        self._viewModel = StateObject(wrappedValue: MapViewModel())
        self._position = State(initialValue: .userLocation(fallback: .automatic))
    }
    
    
    var body: some View {
        
        //MARK: Loading Screen
        if isLoading {
            // Loading screen
            ProgressView("Loading...")
                .onAppear {
                    Task {
                        //try await viewModel.fetchRestaurants()
                        isLoading = false
                    }
                }
        } else {
            //MARK: Restaurant Annotations
            NavigationStack{
                ZStack(alignment: .bottom) {
                    Map(position: $position, selection: $selectedRestaurant, scope: mapScope) {
                        /// No specific Restaurant has been selected from the search view
                        if !inSearchView{
                            if cameraZoomedEnough {
                                ForEach(viewModel.restaurants, id: \.self) { restaurant in
                                    if let coordinates = restaurant.coordinates {
                                        Annotation(restaurant.name, coordinate: coordinates) {
                                            RestaurantCircularProfileImageView(imageUrl: restaurant.profileImageUrl, color: .blue, size: .medium)
                                        }
                                    }
                                }
                            }
                        } else {
                            /// Restaurants have been selected from the search bar
                            ForEach(viewModel.searchPreview, id: \.self) { restaurant in
                                if let coordinates = restaurant.coordinates {
                                    Annotation(restaurant.name, coordinate: coordinates) {
                                        RestaurantCircularProfileImageView(imageUrl: restaurant.profileImageUrl, color: .blue, size: .small)
                                    }
                                }
                            }
                        }
                        /// User Icon
                        UserAnnotation()
                    }
                    
                    //MARK: Fetching Restaurants
                    ///Based on zoom level and the center of the camera
                    .onMapCameraChange { mapCameraUpdateContext in
                        isZoomedInEnough(span: mapCameraUpdateContext.region.span)
                        if cameraZoomedEnough {
                            let center = mapCameraUpdateContext.region.center
                            let location = CLLocation(latitude: center.latitude, longitude: center.longitude)
                            viewModel.selectedLocation = [location]
                            Task{
                                await viewModel.fetchFilteredRestaurants()
                            }
                        }
                    }
                    
                    //MARK: Initial Map Camera
                    /// Sets the camera position to either the users location or Los Angeles if the users location is unavailable
                    .onAppear{
                        let losAngeles = CLLocationCoordinate2D(latitude: 34.0549, longitude: -118.2426)
                        let losAngelesSpan = MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)
                        let losAngelesRegion = MKCoordinateRegion(center: losAngeles, span: losAngelesSpan)
                        position = .userLocation(fallback: .region(losAngelesRegion))
                    }
                    // MARK: User Location button
                    .overlay(alignment: .bottomTrailing) {
                        VStack {
                            MapUserLocationButton(scope: mapScope)
                        }
                        .padding([.bottom, .trailing], 20)
                        .buttonBorderShape(.circle)
                    }
                    .mapScope(mapScope)
                    
                    VStack {
                        if !inSearchView{
                            HStack {
                                // MARK: Search Button
                                Button(action: {
                                    inSearchView.toggle()
                                    isSearchPresented.toggle()
                                    position = .automatic
                                }) {
                                    Image(systemName: "magnifyingglass")
                                        .foregroundStyle(.white)
                                        .font(.system(size: 27))
                                        .shadow(color: .gray, radius: 10)
                                }
                                
                                
                                Spacer()
                                    .padding(.top)
                                
                                
                                //MARK: Filter Button
                                Button {
                                    isFiltersPresented.toggle()
                                } label: {
                                    Image(systemName: "slider.horizontal.3")
                                        .imageScale(.large)
                                        .shadow(radius: 10)
                                        .font(.system(size: 23))
                                    
                                }
                            }
                            .padding(32)
                            .padding(.top, 20)
                            .foregroundStyle(.white)
                            Spacer()
                        }
                        
                        else {
                            VStack{
                                HStack{
                                    //MARK: Cancel Search
                                    Button{
                                        inSearchView = false
                                        position = .userLocation(fallback: .automatic)
                                    } label: {
                                        Text("Cancel")
                                            .foregroundStyle(.blue)
                                            .bold()
                                    }
                                    Spacer()
                                }
                                .padding(32)
                                .padding(.top, 20)
                                Spacer()
                            }
                        }
                    }
                    /// triggers restaurant preview if the user clicks on empty space
                    .onChange(of: selectedRestaurant, { oldValue, newValue in
                        if newValue != nil {
                            showRestaurantPreview = true
                        } else {
                            showRestaurantPreview = false
                        }
                    })
                    
                    //MARK: MapSearchView
                    .sheet(isPresented: $isSearchPresented) {
                        NavigationStack {
                            MapSearchView(restaurantService: RestaurantService(), mapViewModel: viewModel, inSearchView: $inSearchView)
                        }
                    }
                    //MARK: Filters Button
                    .sheet(isPresented: $isFiltersPresented) {
                        NavigationStack {
                            //TODO: FiltersView(feedViewModel:)
                        }
                    }
                    .mapStyle(.standard(elevation: .realistic))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .ignoresSafeArea()
                    
                    //MARK: Restaurant Preview
                    if showRestaurantPreview, let restaurant = selectedRestaurant {
                        withAnimation(.snappy) {
                            MapRestaurantView(restaurant: restaurant)
                                .onTapGesture {
                                    showRestaurantPreview.toggle()
                                }
                            
                        }
                    }
                }
                /// Asks for location permission
                .onAppear{LocationManager.shared.requestLocation()}
            }
            
        }
    }
    //MARK: clears the selected restaurant
    func clearSelectedListing() {
        selectedRestaurant = nil
    }
    
    private func isZoomedInEnough(span: MKCoordinateSpan) {
        let update = span.longitudeDelta < 0.15
        cameraZoomedEnough = update
    }
}




//#Preview {
//    MapView()
//}

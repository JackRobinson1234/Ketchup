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
    @State var cameraZoomedEnough = false /// Whether or not the longitude delta is zoomed in enough to view spots
    @State var lastFetchedLocation: CLLocation = CLLocation(latitude: 0, longitude: 0)
    private var isZoomedEnoughLongitudeSpan: Double = 0.1
    private var photosLongitudeSpan: Double = 0.015
    @State var isZoomedEnoughForPhotos: Bool = false
    private var kmChangeToUpdateFetch: Double = 2.0 //EDIT THIS TO CHANGE HOW FAR UNTIL THE RESTAURANTS ARE UPDATED, to update the radius fetched go to restaurantViewModel and update on restaurantService fetchRestaurantsWithLocation radiusinM
    
    
    
    init() {
        self._viewModel = StateObject(wrappedValue: MapViewModel())
        self._position = State(initialValue: .userLocation(fallback: .automatic))
    }
    
    
    var body: some View {
        //MARK: Map
        NavigationStack{
            ZStack(alignment: .bottom) {
                Map(position: $position, selection: $selectedRestaurant, scope: mapScope) {
                    /// No specific Restaurant has been selected from the search view
                    
                        if cameraZoomedEnough {
                            //MARK: Restaurant Annotations
                            ForEach(viewModel.restaurants, id: \.self) { restaurant in
                                if let coordinates = restaurant.coordinates {
                                    Annotation(restaurant.name, coordinate: coordinates) {
                                        if isZoomedEnoughForPhotos{
                                            RestaurantCircularProfileImageView(imageUrl: restaurant.profileImageUrl, color: .blue, size: .medium)
                                        } else {
                                            Circle()
                                                .foregroundStyle(.blue)
                                                .frame(width: 10, height: 10)
                                        }
                                }
                            }
                        }
                    }
                    /// User Icon
                    UserAnnotation()
                }
                //MARK: Zoom Message
                .overlay{if !cameraZoomedEnough {
                    Spacer()
                    Text("Zoom Map to Show Restaurants")
                        .font(.subheadline)
                        .foregroundColor(.black)
                        .padding(10)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .foregroundColor(Color.white)
                                .opacity(0.5)
                        )
                    //MARK: No Restaurants Notice
                } else if viewModel.restaurants.isEmpty {
                    Spacer()
                    VStack{
                        Text("No Restaurants Nearby")
                            .font(.subheadline)
                            .foregroundColor(.black)
                            .padding(10)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .foregroundColor(Color.white)
                                    .opacity(0.5)
                            )
                        Button{
                        } label: {
                            Text("Find Nearest Restaurant")
                                .font(.subheadline)
                                .foregroundColor(.black)
                                .padding(10)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .foregroundColor(Color.white)
                                        .opacity(0.5)
                                )
                        }
                    }
                }
                }
                //MARK: Fetching Restaurants
                ///Based on zoom level and the center of the camera
                .onMapCameraChange { mapCameraUpdateContext in
                    isZoomedInEnough(span: mapCameraUpdateContext.region.span)
                    if cameraZoomedEnough {
                        let center = mapCameraUpdateContext.region.center
                        Task {
                            await fetchRestaurantsInView(center: center)
                        }
                    }
                    else {
                        showRestaurantPreview = false
                    }
                }
                
                //MARK: Initial Camera
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
                            //MARK: Zoom Notice
                            
                            Spacer()
                            
                            
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
                            MapSearchView(cameraPosition: $position, inSearchView: $inSearchView)
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
                
                //MARK: Filters
                .fullScreenCover(isPresented: $isFiltersPresented) {
                    MapFiltersView(mapViewModel: viewModel)
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
    //MARK: clearSelectedListing
    func clearSelectedListing() {
        selectedRestaurant = nil
    }
    //MARK: isZoomedEnough
    private func isZoomedInEnough(span: MKCoordinateSpan) {
        let anyUpdate = span.longitudeDelta < isZoomedEnoughLongitudeSpan
        cameraZoomedEnough = anyUpdate
        let photosUpdate = span.longitudeDelta < photosLongitudeSpan
        isZoomedEnoughForPhotos = photosUpdate
    }
    
    //MARK: fetchRestaurantsInView
    /// fetches another batch of restaurants if the new location is outside the radius of the last batch
    /// - Parameter center: CLLocation of the center of the camera view
    private func fetchRestaurantsInView(center: CLLocationCoordinate2D) async {
        if cameraZoomedEnough {
            /// Makes sure that there was a last location fetched from, and that it is far enough away from the new query
            if let lastLocation = viewModel.selectedLocation.first {
                if calculateDistanceInKilometers(from: lastLocation, to: center, minDistanceKm: kmChangeToUpdateFetch) {
                    viewModel.selectedLocation = [center]
                    print("fetching new restaurants")
                    Task{
                        await viewModel.fetchFilteredRestaurants()
                    }
                }
            }
            else {
                print("fetching new restaurants")
                viewModel.selectedLocation = [center]
                Task{
                    await viewModel.fetchFilteredRestaurants()
                }
            }
        }
    }
    //MARK: calculateDistanceInKilometers
    ///  Provides a boolean of if 2 CLLocationCoordinate2Ds are outside the minimum range of eachother
    /// - Parameters:
    ///   - coordinate1: CLLocationCoordinate2D
    ///   - coordinate2: CLLocationCoordinate2D
    ///   - minDistanceKm: checks to see if the coordiates
    /// - Returns: Boolean of whether the distance is greater than the mindistance
    private func calculateDistanceInKilometers(from coordinate1: CLLocationCoordinate2D, to coordinate2: CLLocationCoordinate2D, minDistanceKm: Double) -> Bool {
        let location1 = CLLocation(latitude: coordinate1.latitude, longitude: coordinate1.longitude)
        let location2 = CLLocation(latitude: coordinate2.latitude, longitude: coordinate2.longitude)
        let distanceInMeters = location1.distance(from: location2)
        let distanceInKilometers = distanceInMeters / 1000
        return distanceInKilometers > minDistanceKm
    }

}

#Preview {
    MapView()
}

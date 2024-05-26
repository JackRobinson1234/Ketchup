//
//  MapView.swift
//  Foodi
//
//  Created by Jack Robinson on 2/1/24.
//

import SwiftUI
import MapKit
import ClusterMap
import ClusterMapSwiftUI

struct MapView: View {
    @StateObject var viewModel: MapViewModel
    @State var position: MapCameraPosition /// Camera view of the map
    @State private var selectedRestaurant: RestaurantMapAnnotation? /// Restaurant that the user clicks on
    @State private var showRestaurantPreview = false /// Restaurant Preview at bottom of screen
    @State private var inSearchView: Bool = false /// Changes the camera to be fixed on the selected restaurant(s)
    @State private var isSearchPresented: Bool = false /// Search View sheet
    @State private var isFiltersPresented: Bool = false /// Filters View Sheet
    @ObservedObject var locationManager = LocationManager.shared /// Asks for user map permission
    @State var isLoading = true /// Waiting for the viewModel to fetchRestaurants
    @Namespace var mapScope
    @State var cameraZoomedEnough = false
    @State var isZoomedEnoughForPhotos: Bool = false/// Is  zoomed in enough to view dots
    @State var lastFetchedLocation: CLLocation = CLLocation(latitude: 0, longitude: 0)
    private var isZoomedEnoughLongitudeSpan: Double = 0.02
    private var photosLongitudeSpan: Double = 0.005
    private var kmChangeToUpdateFetch: Double = 1.0
    private var kmToShowPhoto: Double = 0.3//EDIT THIS TO CHANGE HOW FAR UNTIL THE RESTAURANTS ARE UPDATED, to update the radius fetched go to restaurantViewModel and update on restaurantService fetchRestaurantsWithLocation radiusinM
    @State var center: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 0, longitude: 0)
    @State private var mapSize: CGSize = .zero

    
    
    init() {
        self._viewModel = StateObject(wrappedValue: MapViewModel())
        self._position = State(initialValue: .userLocation(fallback: .automatic))
    }
    
    
    var body: some View {
        //MARK: Map
        NavigationStack{
            ZStack(alignment: .bottom) {
                GeometryReader(content: { geometryProxy in
                    Map(position: $position, selection: $selectedRestaurant, scope: mapScope) {
                        /// No specific Restaurant has been selected from the search view
                        
                        if cameraZoomedEnough {
                            //MARK: Restaurant Annotations
                            /// If the restaurants are within showable distance (cameraZoomedEnough), then use blue dots. If they are inside of  minDistanceKm, then show the photos.
                            ForEach(viewModel.annotations, id: \.self) { item in
                                Annotation(item.restaurant.name, coordinate: item.coordinate){
                                    RestaurantCircularProfileImageView(imageUrl: item.restaurant.profileImageUrl, color: Color("Colors/AccentColor"), size: .medium)
                                        .animation(.easeInOut(duration: 0.3), value: viewModel.annotations)
                                }
                                //.annotationTitles(.hidden)
                            }
                            ForEach(viewModel.clusters) { cluster in
                                Annotation("", coordinate: cluster.coordinate){
                                    ClusterCell(cluster: cluster)
                                        .animation(.easeInOut(duration: 0.3), value: viewModel.annotations)
                                }
                            }
                        }
//                        ForEach(viewModel.restaurants, id: \.self) { restaurant in
//                            if let coordinates = restaurant.coordinates {
//                                Annotation(restaurant.name, coordinate: coordinates) {
//                                    let distanceFromCenter = calculateDistanceInKilometers(from: center, to: coordinates, minDistanceKm: kmToShowPhoto)
//                                    if isZoomedEnoughForPhotos,  distanceFromCenter{
//                                        RestaurantCircularProfileImageView(imageUrl: restaurant.profileImageUrl, color: .blue, size: .medium)
//                                    } else {
//                                        Circle()
//                                            .foregroundStyle(.blue)
//                                            .frame(width: 10, height: 10)
//                                    }
//                                }
//                            }
//                        }
                        /// User Icon
                        UserAnnotation()
                    }
                    .readSize(onChange: { newValue in
                        viewModel.mapSize = newValue
                        print("mapsize", viewModel.mapSize)
                    })
                    .onMapCameraChange { context in
                        viewModel.currentRegion = context.region
                    }
                    .onMapCameraChange(frequency: .onEnd) { context in
                        Task.detached { await viewModel.reloadAnnotations() }
                    }
                    //MARK: Zoom Message
                    .overlay{if !cameraZoomedEnough {
                        Spacer()
                        Text("Zoom In to Show Restaurants")
                            .modifier(OverlayModifier())
                        //MARK: No Restaurants Notice
                    } else if viewModel.restaurants.isEmpty {
                        Spacer()
                        VStack{
                            Spacer()
                            Text("No Restaurants Nearby")
                                .modifier(OverlayModifier())
                            Spacer()
                            /// MARK: Fetch Nearby Restaurants
                            Button{
                                Task{
                                    await viewModel.checkForNearbyRestaurants()
                                    /// Resets the camera position to the closest restaurant
                                    if let restaurant = viewModel.restaurants.first, let coordinates = restaurant.coordinates {
                                        let region = MKCoordinateRegion(center: coordinates, latitudinalMeters: 1000, longitudinalMeters: 1000)
                                        position = .region(region)
                                    }
                                }
                            } label: {
                                Text("Find Nearest Restaurant")
                                    .modifier(OverlayModifier())
                            }
                        }
                    }
                    }
                    //MARK: Fetching Restaurants
                    ///Based on zoom level and the center of the camera
                    .onMapCameraChange { mapCameraUpdateContext in
                        isZoomedInEnough(span: mapCameraUpdateContext.region.span)
                        if cameraZoomedEnough {
                            center = mapCameraUpdateContext.region.center
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
                        let losAngelesRegion = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 34.0549, longitude: -118.2426), span: MKCoordinateSpan(latitudeDelta: 0.04, longitudeDelta: 0.04))
                        position = .userLocation(fallback: .region(losAngelesRegion))
                        mapSize = geometryProxy.size
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
                    .mapStyle(.standard(pointsOfInterest: .excludingAll))
                    
                }
                )
                
                
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
                    //MARK: SearchView
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
                if showRestaurantPreview, let annotation = selectedRestaurant {
                    withAnimation(.snappy) {
                        MapRestaurantView(restaurant: annotation.restaurant)
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
                if !calculateDistanceInKilometers(from: lastLocation, to: center, minDistanceKm: kmChangeToUpdateFetch) {
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
    ///  Provides a boolean of if 2 CLLocationCoordinate2Ds are inside he minimum range of eachother
    /// - Parameters:
    ///   - coordinate1: CLLocationCoordinate2D
    ///   - coordinate2: CLLocationCoordinate2D
    ///   - minDistanceKm: checks to see if the coordiates
    /// - Returns: Boolean of whether the distance is inside the mindistance
    private func calculateDistanceInKilometers(from coordinate1: CLLocationCoordinate2D, to coordinate2: CLLocationCoordinate2D, minDistanceKm: Double) -> Bool {
        let location1 = CLLocation(latitude: coordinate1.latitude, longitude: coordinate1.longitude)
        let location2 = CLLocation(latitude: coordinate2.latitude, longitude: coordinate2.longitude)
        let distanceInMeters = location1.distance(from: location2)
        let distanceInKilometers = distanceInMeters / 1000
        return distanceInKilometers < minDistanceKm
    }
}

#Preview {
    MapView()
}



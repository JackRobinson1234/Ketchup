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
    @State var position: MapCameraPosition
    @State private var selectedRestaurant: RestaurantMapAnnotation?
    @State private var showRestaurantPreview = false
    @State private var inSearchView: Bool = false
    @State private var isSearchPresented: Bool = false
    @State private var isFiltersPresented: Bool = false
    @State var isLoading = true
    @Namespace var mapScope
    @State var lastFetchedLocation: CLLocation = CLLocation(latitude: 0, longitude: 0)
    @State var center: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 0, longitude: 0)
    @State private var noNearbyRestaurants = false
    @State private var showAlert = false
    @State private var selectedCluster: ExampleClusterAnnotation?
    @State private var hasAppeared = false
    @State private var showMoveWarning = false
    
    init() {
        self._viewModel = StateObject(wrappedValue: MapViewModel())
        self._position = State(initialValue: .userLocation(fallback: .automatic))
    }
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                GeometryReader { geometryProxy in
                    Map(position: $position, scope: mapScope) {
                        ForEach(viewModel.annotations, id: \.self) { item in
                            Annotation(item.restaurant.name, coordinate: item.coordinate) {
                                NavigationLink(destination: RestaurantProfileView(restaurantId: item.restaurant.id)) {
                                    RestaurantCircularProfileImageView(imageUrl: item.restaurant.profileImageUrl, color: Color("Colors/AccentColor"), size: .medium)
                                }
                                .animation(.easeInOut(duration: 0.3), value: viewModel.annotations)
                            }
                        }
                        ForEach(viewModel.clusters) { cluster in
                            Annotation("", coordinate: cluster.coordinate) {
                                ClusterCell(cluster: cluster)
                                    .animation(.easeInOut(duration: 0.3), value: viewModel.annotations)
                                    .onTapGesture {
                                        selectedCluster = cluster
                                    }
                            }
                        }
                        ForEach(viewModel.largeClusters) { cluster in
                            Annotation("", coordinate: cluster.coordinate) {
                                NewClusterCell(cluster: cluster)
                                    .animation(.easeInOut(duration: 0.3), value: viewModel.annotations)
//                                    .onTapGesture {
//                                        selectedCluster = cluster
//                                    }
                            }
                        }
                        UserAnnotation()
                    }
                    .readSize(onChange: { newValue in
                        viewModel.mapSize = newValue
                    })
                    .onMapCameraChange { context in
                        showMoveWarning = false
                        viewModel.currentRegion = context.region
                        center = context.region.center
                        Task {
                            await viewModel.updateZoomLevelAndFetchIfNeeded()
                            if viewModel.currentZoomLevel != "max_zoom_out" {
                                await fetchRestaurantsInView(center: center)
                            }
                        }
                    }
                    .onMapCameraChange(frequency: .onEnd) { context in
                        if !viewModel.isZoomedEnoughForClusters {
                            Task.detached { await viewModel.reloadAnnotations() }
                        }
                    }
                    .onChange(of: isFiltersPresented) {
                        if !viewModel.isZoomedEnoughForClusters {
                            Task.detached { await viewModel.reloadAnnotations() }
                        }
                    }
                    .onAppear {
                        showMoveWarning = true
                        Debouncer(delay: 2.0).schedule {
                            showMoveWarning = false
                        }
                    }
                    .overlay {
                        if viewModel.currentZoomLevel == "max_zoom_out" {
                            Text("Zoom in to see restaurants")
                                .modifier(OverlayModifier())
                        } else if viewModel.restaurants.isEmpty && viewModel.clusters.isEmpty && !viewModel.isLoading {
                            noRestaurantsView
                        }
                    }
                    .overlay(alignment: .bottomTrailing) {
                        userLocationButton
                    }
                    .mapScope(mapScope)
                    .mapStyle(.standard(pointsOfInterest: .excludingAll))
                }
                if showMoveWarning {
                    Text("Move Map to see restaurants")
                        .modifier(OverlayModifier())
                    Spacer()
                }
                filtersButton
                if showRestaurantPreview, let annotation = selectedRestaurant {
                    restaurantPreviewView(annotation: annotation)
                }
            }
            .sheet(item: $selectedCluster) { cluster in
                ClusterRestaurantListView(restaurants: cluster.memberAnnotations.map { $0.restaurant })
            }
            .onAppear {
                if !hasAppeared {
                    Task {
                        LocationManager.shared.requestLocation()
                        if let userLocation = LocationManager.shared.userLocation {
                            center = userLocation.coordinate
                        } else {
                            center = CLLocationCoordinate2D(latitude: 34.0549, longitude: -118.2426)
                        }
                        await fetchRestaurantsInView(center: center)
                        hasAppeared = true
                    }
                }
            }
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("Location Permission Required"),
                    message: Text("Ketchup needs access to your location to show nearby restaurants. Please go to Settings and enable location permissions."),
                    primaryButton: .default(Text("Go to Settings")) {
                        if let url = URL(string: UIApplication.openSettingsURLString), UIApplication.shared.canOpenURL(url) {
                            UIApplication.shared.open(url, options: [:], completionHandler: nil)
                        }
                    },
                    secondaryButton: .cancel()
                )
            }
            .fullScreenCover(isPresented: $isFiltersPresented) {
                MapFiltersView(mapViewModel: viewModel)
            }
            .mapStyle(.standard(elevation: .realistic))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .ignoresSafeArea()
        }
    }
    
    private var noRestaurantsView: some View {
        VStack {
            Spacer()
            Text("No Restaurants Nearby")
                .modifier(OverlayModifier())
            Spacer()
            if !noNearbyRestaurants {
                Button {
                    Task {
                        await viewModel.checkForNearbyRestaurants()
                        if let restaurant = viewModel.restaurants.first, let coordinates = restaurant.coordinates {
                            let region = MKCoordinateRegion(center: coordinates, latitudinalMeters: 1000, longitudinalMeters: 1000)
                            position = .region(region)
                            Task.detached { await viewModel.reloadAnnotations() }
                        } else {
                            noNearbyRestaurants = true
                        }
                    }
                } label: {
                    Text("Find Nearest Restaurant")
                        .font(.custom("MuseoSansRounded-300", size: 16))
                        .modifier(StandardButtonModifier(width: 190))
                }
                .padding()
            } else {
                Text("No Restaurants found in a 1000 mile radius. Change filters to see results!")
                    .modifier(OverlayModifier())
                    .padding()
            }
        }
    }
    
    private var userLocationButton: some View {
        VStack {
            if LocationManager.shared.userLocation == nil {
                Button {
                    showAlert = true
                } label: {
                    MapUserLocationButton(scope: mapScope)
                        .buttonBorderShape(.circle)
                }
            } else {
                MapUserLocationButton(scope: mapScope)
                    .buttonBorderShape(.circle)
            }
        }
        .padding([.bottom, .trailing], 20)
        .buttonBorderShape(.circle)
    }
    
    private var filtersButton: some View {
        VStack {
            if !inSearchView {
                HStack {
                    Spacer()
                    Button {
                        isFiltersPresented.toggle()
                    } label: {
                        ZStack {
                            Image(systemName: "slider.horizontal.3")
                                .imageScale(.large)
                                .shadow(color: viewModel.filters.isEmpty ? Color.black : Color.black, radius: 4)
                                .font(.system(size: 23))
                            if viewModel.filters.count > 1 {
                                Circle()
                                    .fill(Color("Colors/AccentColor"))
                                    .frame(width: 12, height: 12)
                                    .offset(x: 12, y: 12)
                            }
                        }
                    }
                }
                .padding(32)
                .padding(.top, 20)
                .foregroundStyle(.white)
                Spacer()
            } else {
                VStack {
                    MapSearchView(cameraPosition: $position, inSearchView: $inSearchView)
                        .padding(32)
                        .padding(.top, 20)
                    Spacer()
                }
            }
        }
    }
    private func restaurantPreviewView(annotation: RestaurantMapAnnotation) -> some View {
        MapRestaurantView(restaurant: annotation.restaurant)
            .overlay(
                Button {
                    selectedRestaurant = nil
                    showRestaurantPreview.toggle()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.custom("MuseoSansRounded-300", size: 20))
                        .padding()
                        .foregroundColor(.white)
                        .shadow(radius: 3)
                        .padding(.top, 10)
                        .padding(.leading, 10)
                },
                alignment: .topLeading
            )
    }
    
    private func clearSelectedListing() {
        selectedRestaurant = nil
    }
    
    private func fetchRestaurantsInView(center: CLLocationCoordinate2D) async {
        if viewModel.currentZoomLevel == "max_zoom_out" {
            return // Don't fetch if zoomed out too far
        }
        
        let distanceThreshold = calculateDistanceThreshold(for: viewModel.currentRegion)
        
        if let lastLocation = viewModel.selectedLocation.first {
            let distance = calculateDistanceInKilometers(from: lastLocation, to: center)
            if distance >= distanceThreshold {
                viewModel.selectedLocation = [center]
                print("Fetching new restaurants. Distance moved: \(distance) km, Threshold: \(distanceThreshold) km")
                noNearbyRestaurants = false
                await viewModel.fetchFilteredClusters()
            } else {
                print("Skipping fetch. Distance moved: \(distance) km, Threshold: \(distanceThreshold) km")
            }
        } else {
            print("Fetching initial restaurants")
            viewModel.selectedLocation = [center]
            await viewModel.fetchFilteredClusters()
        }
    }
    
    private func calculateDistanceInKilometers(from coordinate1: CLLocationCoordinate2D, to coordinate2: CLLocationCoordinate2D) -> Double {
        let location1 = CLLocation(latitude: coordinate1.latitude, longitude: coordinate1.longitude)
        let location2 = CLLocation(latitude: coordinate2.latitude, longitude: coordinate2.longitude)
        let distanceInMeters = location1.distance(from: location2)
        return distanceInMeters / 1000
    }
}

extension MapView {
    func calculateDistanceThreshold(for region: MKCoordinateRegion) -> Double {
        // Calculate the diagonal distance of the visible region in kilometers
        let northEast = CLLocation(latitude: region.center.latitude + region.span.latitudeDelta/2,
                                   longitude: region.center.longitude + region.span.longitudeDelta/2)
        let southWest = CLLocation(latitude: region.center.latitude - region.span.latitudeDelta/2,
                                   longitude: region.center.longitude - region.span.longitudeDelta/2)
        let diagonalDistance = northEast.distance(from: southWest) / 1000 // Convert to km
        
        // Use a stepped approach based on the diagonal distance
        if diagonalDistance > 1000 {  // Very zoomed out (country level)
            return 500  // 500 km threshold
        } else if diagonalDistance > 500 {  // Zoomed out (large region level)
            return 200  // 200 km threshold
        } else if diagonalDistance > 100 {  // Medium zoom (state level)
            return 50   // 50 km threshold
        } else if diagonalDistance > 50 {   // Zoomed in (city level)
            return 10   // 10 km threshold
        } else {  // Very zoomed in (neighborhood level)
            return max(diagonalDistance * 0.2, 0.5)  // 20% of diagonal or at least 1 km
        }
    }
}


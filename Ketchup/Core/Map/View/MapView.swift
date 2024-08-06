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
    @State var isLoading = true /// Waiting for the viewModel to fetchRestaurants
    @Namespace var mapScope
    @State var cameraZoomedEnough = false
    @State var isZoomedEnoughForPhotos: Bool = false /// Is zoomed in enough to view dots
    @State var lastFetchedLocation: CLLocation = CLLocation(latitude: 0, longitude: 0)
    private var isZoomedEnoughLongitudeSpan: Double = 0.02
    private var photosLongitudeSpan: Double = 0.005
    private var kmChangeToUpdateFetch: Double = 1.0
    private var kmToShowPhoto: Double = 0.3
    @State var center: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 0, longitude: 0)
    @State private var mapSize: CGSize = .zero
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
                GeometryReader(content: { geometryProxy in
                    Map(position: $position, scope: mapScope) {
                        if cameraZoomedEnough {
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
                        }
                        UserAnnotation()
                    }
                    .readSize(onChange: { newValue in
                        viewModel.mapSize = newValue
                    })
                    .onMapCameraChange { context in
                        showMoveWarning = false
                        viewModel.currentRegion = context.region
                    }
                    .onMapCameraChange(frequency: .onEnd) { context in
                        Task.detached { await viewModel.reloadAnnotations() }
                    }
                    .onChange(of: isFiltersPresented) {
                        Task.detached { await viewModel.reloadAnnotations() }
                    }
                    .onAppear {
                        showMoveWarning = true
                        Debouncer(delay: 2.0).schedule {
                            showMoveWarning = false
                        }
                    }
                    .overlay {
//                        if !cameraZoomedEnough {
//                            Spacer()
//                            Text("Zoom In to Show Restaurants")
//                                .modifier(OverlayModifier())
//                        }
                       // else
                        if viewModel.restaurants.isEmpty && !viewModel.isLoading {
                            Spacer()
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
                    }
                    .onMapCameraChange { mapCameraUpdateContext in
                        isZoomedInEnough(span: mapCameraUpdateContext.region.span)
                        //if cameraZoomedEnough {
                            center = mapCameraUpdateContext.region.center
                            Task {
                                await fetchRestaurantsInView(center: center)
                            }
//                        } else {
//                            showRestaurantPreview = false
//                        }
                    }
                    .overlay(alignment: .bottomTrailing) {
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
                    .mapScope(mapScope)
                    .mapStyle(.standard(pointsOfInterest: .excludingAll))
                })
                if showMoveWarning {
                    Text("Move Map to see restaurants")
                        .modifier(OverlayModifier())
                    Spacer()
                }
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
                if showRestaurantPreview, let annotation = selectedRestaurant {
                    withAnimation(.snappy) {
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
        }
    }

    private func clearSelectedListing() {
        selectedRestaurant = nil
    }

    private func isZoomedInEnough(span: MKCoordinateSpan) {
        let anyUpdate = span.longitudeDelta < isZoomedEnoughLongitudeSpan
        cameraZoomedEnough = anyUpdate
        let photosUpdate = span.longitudeDelta < photosLongitudeSpan
        isZoomedEnoughForPhotos = photosUpdate
    }

    private func fetchRestaurantsInView(center: CLLocationCoordinate2D) async {
        //if cameraZoomedEnough {
            if let lastLocation = viewModel.selectedLocation.first {
                if !calculateDistanceInKilometers(from: lastLocation, to: center, minDistanceKm: kmChangeToUpdateFetch) {
                    viewModel.selectedLocation = [center]
                    print("fetching new restaurants")
                    noNearbyRestaurants = false
                    await viewModel.fetchFilteredClusters()
                }
            } else {
                print("fetching new restaurants")
                viewModel.selectedLocation = [center]
                await viewModel.fetchFilteredClusters()
            }
        //}
    }

    private func calculateDistanceInKilometers(from coordinate1: CLLocationCoordinate2D, to coordinate2: CLLocationCoordinate2D, minDistanceKm: Double) -> Bool {
        let location1 = CLLocation(latitude: coordinate1.latitude, longitude: coordinate1.longitude)
        let location2 = CLLocation(latitude: coordinate2.latitude, longitude: coordinate2.longitude)
        let distanceInMeters = location1.distance(from: location2)
        let distanceInKilometers = distanceInMeters / 1000
        return distanceInKilometers < minDistanceKm
    }
}

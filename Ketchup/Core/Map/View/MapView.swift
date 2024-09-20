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
import Combine
import SwiftUI
import MapKit
import Combine

// MARK: - MapView
struct MapView: View {
    @StateObject var viewModel: MapViewModel = MapViewModel()
    @StateObject var followingViewModel = FollowingPostsMapViewModel()
    @State private var selectedRestaurant: RestaurantMapAnnotation?
    @State private var selectedGroupedPost: GroupedPostMapAnnotation?
    @State private var showRestaurantPreview = false
    @State private var inSearchView: Bool = false
    @State private var isSearchPresented: Bool = false
    @State private var isFiltersPresented: Bool = false
    @State var isLoading = true
    @Namespace var mapScope
    @State var center: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 0, longitude: 0)
    @State private var showAlert = false
    @State private var selectedCluster: ExampleClusterAnnotation?
    @State private var selectedFollowingCluster: GroupedPostClusterAnnotation?
    @State private var hasAppeared = false
    @State private var showMoveWarning = false
    @State private var showFollowingPosts = false
    
    private var noNearbyRestaurants: Bool {
        if showFollowingPosts {
            return followingViewModel.annotations.isEmpty && followingViewModel.clusters.isEmpty && !followingViewModel.isLoading
        } else {
            return viewModel.annotations.isEmpty && viewModel.clusters.isEmpty && viewModel.largeClusters.isEmpty && !viewModel.isLoading
        }
    }
    private var isZoomedOutTooFar: Bool {
        if showFollowingPosts {
            return followingViewModel.currentZoomLevel == .maxZoomOut
        } else {
            return viewModel.currentZoomLevel == .maxZoomOut
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack(alignment: .bottom) {
                GeometryReader { geometryProxy in
                    UIKitMapView(
                        viewModel: viewModel,
                        followingViewModel: followingViewModel,
                        showFollowingPosts: $showFollowingPosts,
                        selectedRestaurant: $selectedRestaurant,
                        selectedCluster: $selectedCluster,
                        selectedFollowingCluster: $selectedFollowingCluster,
                        isLoading: $isLoading,
                        showAlert: $showAlert,
                        mapSize: geometryProxy.size
                    )
                    .edgesIgnoringSafeArea(.all)
                }
                topRow
                if (showFollowingPosts ? followingViewModel.isLoading : viewModel.isLoading) {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            LoadingIcon()
                                .padding([.bottom, .trailing], 20)
                                .padding(.bottom, 50)
                        }
                    }
                }
            }
            .sheet(item: $selectedCluster) { cluster in
                ClusterRestaurantListView(restaurants: cluster.memberAnnotations.map { $0.restaurant })
            }
            .sheet(item: $selectedFollowingCluster) { cluster in
                GroupedPostClusterListView(groupedPosts: cluster.memberAnnotations)
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
                MapFiltersView(mapViewModel: viewModel, followingPostsMapViewModel: followingViewModel, showFollowingPosts: $showFollowingPosts)
            }
        }
    }
    
    // MARK: - User Location Button
    private var userLocationButton: some View {
        VStack {
            if LocationManager.shared.userLocation == nil {
                Button {
                    showAlert = true
                } label: {
                    Image(systemName: "location.fill")
                        .padding()
                        .background(Color.white)
                        .clipShape(Circle())
                        .shadow(radius: 2)
                }
            } else {
                Button {
                    // Center on user location
                    if let userLocation = LocationManager.shared.userLocation {
                        center = userLocation.coordinate
                        viewModel.centerMapOnLocation(location: userLocation)
                    }
                } label: {
                    Image(systemName: "location.fill")
                        .padding()
                        .background(Color.white)
                        .clipShape(Circle())
                        .shadow(radius: 2)
                }
            }
        }
        .padding([.bottom, .trailing], 20)
    }
    
    // MARK: - Top Row
    private var topRow: some View {
        VStack {
            if !inSearchView {
                HStack(alignment: .bottom) {
                    Button {
                        inSearchView.toggle()
                    } label: {
                        VStack {
                            Image(systemName: "magnifyingglass")
                                .imageScale(.large)
                                .font(.title3)
                                .foregroundStyle(.black)
                            Text("Search")
                                .foregroundStyle(.gray)
                                .font(.custom("MuseoSansRounded-500", size: 10))
                                .lineLimit(1)
                                .minimumScaleFactor(0.5)
                        }
                        .frame(width: 50, height: 50)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white)
                                .shadow(color: Color.gray, radius: 1)
                        )
                    }
                    Spacer()
                    VerticalToggleView(showFollowingPosts: $showFollowingPosts) {
                        handleToggleChange()
                    }
                    Spacer()
                    Button {
                        isFiltersPresented.toggle()
                    } label: {
                        VStack {
                            ZStack {
                                Image(systemName: "slider.horizontal.3")
                                    .imageScale(.large)
                                    .font(.title3)
                                    .foregroundStyle(.black)
                                if viewModel.filters.count > 1 {
                                    Circle()
                                        .fill(Color("Colors/AccentColor"))
                                        .frame(width: 12, height: 12)
                                        .offset(x: 12, y: 12)
                                }
                            }
                            Text("Filters")
                                .foregroundStyle(.gray)
                                .font(.custom("MuseoSansRounded-500", size: 10))
                                .lineLimit(1)
                                .minimumScaleFactor(0.5)
                        }
                        .frame(width: 50, height: 50)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white)
                                .shadow(color: Color.gray, radius: 1)
                        )
                    }
                }
                .padding(.horizontal, 25)
                .padding(.top, 60)
                Spacer()
            } else {
                VStack {
//                    MapSearchView(cameraPosition: .constant(MKCoordinateRegion()), inSearchView: $inSearchView)
//                        .padding(32)
//                        .padding(.top, 20)
                    Spacer()
                }
            }
        }
        .animation(.spring(), value: inSearchView)
    }
    
    // MARK: - Handle Toggle Change
    private func handleToggleChange() {
        Task {
            await MainActor.run {
                if showFollowingPosts {
                    followingViewModel.updateMapState(newRegion: viewModel.currentRegion, shouldAutoFetch: true)
                } else {
                    viewModel.updateMapState(newRegion: followingViewModel.currentRegion, shouldAutoFetch: true)
                }
            }
        }
    }
    
    // MARK: - Fetch Restaurants In View
    private func fetchRestaurantsInView(center: CLLocationCoordinate2D) async {
        if showFollowingPosts {
            if followingViewModel.currentZoomLevel == .maxZoomOut {
                return
            }
            let distanceThreshold = MapUtils.calculateDistanceThreshold(for: followingViewModel.currentRegion)
            if let lastLocation = followingViewModel.selectedLocation.first {
                let distance = MapUtils.calculateDistance(from: lastLocation, to: center)
                if distance >= distanceThreshold {
                    followingViewModel.selectedLocation = [center]
                    await followingViewModel.fetchFollowingPosts()
                }
            } else {
                followingViewModel.selectedLocation = [center]
                await followingViewModel.fetchFollowingPosts()
            }
        } else {
            if viewModel.currentZoomLevel == .maxZoomOut {
                return
            }
            let distanceThreshold = MapUtils.calculateDistanceThreshold(for: viewModel.currentRegion)
            if let lastLocation = viewModel.selectedLocation.first {
                let distance = MapUtils.calculateDistance(from: lastLocation, to: center)
                if distance >= distanceThreshold {
                    viewModel.selectedLocation = [center]
                    await viewModel.fetchFilteredClusters()
                }
            } else {
                viewModel.selectedLocation = [center]
                await viewModel.fetchFilteredClusters()
            }
        }
    }
}

// MARK: - UIKitMapView
struct UIKitMapView: UIViewRepresentable {
    @ObservedObject var viewModel: MapViewModel
    @ObservedObject var followingViewModel: FollowingPostsMapViewModel
    @Binding var showFollowingPosts: Bool
    @Binding var selectedRestaurant: RestaurantMapAnnotation?
    @Binding var selectedCluster: ExampleClusterAnnotation?
    @Binding var selectedFollowingCluster: GroupedPostClusterAnnotation?
    @Binding var isLoading: Bool
    @Binding var showAlert: Bool
    var mapSize: CGSize
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self, viewModel: viewModel, followingViewModel: followingViewModel)
    }
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView(frame: .zero)
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        return mapView
    }
    
    func updateUIView(_ uiView: MKMapView, context: Context) {
        uiView.removeAnnotations(uiView.annotations)
        if showFollowingPosts {
            uiView.addAnnotations(followingViewModel.annotations)
            uiView.addAnnotations(followingViewModel.clusters)
        } else {
            uiView.addAnnotations(viewModel.annotations)
            uiView.addAnnotations(viewModel.clusters)
            uiView.addAnnotations(viewModel.largeClusters)
        }
        DispatchQueue.main.async {
            viewModel.mapSize = mapSize
            followingViewModel.mapSize = mapSize
        }
    }
    
    // MARK: - Coordinator
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: UIKitMapView
        var viewModel: MapViewModel
        var followingViewModel: FollowingPostsMapViewModel
        var cancellables = Set<AnyCancellable>()
        
        init(_ parent: UIKitMapView, viewModel: MapViewModel, followingViewModel: FollowingPostsMapViewModel) {
            self.parent = parent
            self.viewModel = viewModel
            self.followingViewModel = followingViewModel
        }
        
        func mapViewDidChangeVisibleRegion(_ mapView: MKMapView) {
            let newRegion = mapView.region
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                if !self.parent.showFollowingPosts {
                    self.viewModel.updateMapState(newRegion: newRegion)
                    Task { await self.viewModel.reloadAnnotations() }
                } else {
                    self.followingViewModel.updateMapState(newRegion: newRegion)
                    Task { await self.followingViewModel.reloadAnnotations() }
                }
            }
        }
        
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            if let restaurantAnnotation = annotation as? RestaurantMapAnnotation {
                let identifier = "RestaurantMapAnnotation"
                var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
                if annotationView == nil {
                    annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                    annotationView?.canShowCallout = true
                } else {
                    annotationView?.annotation = annotation
                }
                annotationView?.image = UIImage(systemName: "mappin.circle.fill")
                return annotationView
            } else if let clusterAnnotation = annotation as? ExampleClusterAnnotation {
                let identifier = "ExampleClusterAnnotation"
                var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
                if annotationView == nil {
                    annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                    annotationView?.canShowCallout = true
                } else {
                    annotationView?.annotation = annotation
                }
                annotationView?.image = UIImage(systemName: "circle.fill")
                return annotationView
            } else if let largeClusterAnnotation = annotation as? LargeClusterAnnotation {
                let identifier = "LargeClusterAnnotation"
                var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
                if annotationView == nil {
                    annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                    annotationView?.canShowCallout = true
                } else {
                    annotationView?.annotation = annotation
                }
                annotationView?.image = UIImage(systemName: "circle.fill")
                return annotationView
            } else if let groupedPostAnnotation = annotation as? GroupedPostMapAnnotation {
                let identifier = "GroupedPostMapAnnotation"
                var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
                if annotationView == nil {
                    annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                    annotationView?.canShowCallout = true
                } else {
                    annotationView?.annotation = annotation
                }
                annotationView?.image = UIImage(systemName: "person.crop.circle")
                return annotationView
            } else if let groupedPostClusterAnnotation = annotation as? GroupedPostClusterAnnotation {
                let identifier = "GroupedPostClusterAnnotation"
                var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
                if annotationView == nil {
                    annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                    annotationView?.canShowCallout = true
                } else {
                    annotationView?.annotation = annotation
                }
                annotationView?.image = UIImage(systemName: "person.3")
                return annotationView
            }
            return nil
        }
        
        func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
            if let clusterAnnotation = view.annotation as? ExampleClusterAnnotation {
                parent.selectedCluster = clusterAnnotation
            } else if let followingCluster = view.annotation as? GroupedPostClusterAnnotation {
                parent.selectedFollowingCluster = followingCluster
            } else if let restaurantAnnotation = view.annotation as? RestaurantMapAnnotation {
                parent.selectedRestaurant = restaurantAnnotation
            }
        }
    }
}

// MARK: - LoadingIcon
struct LoadingIcon: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.white)
                .frame(width: 50, height: 50)
                .shadow(color: .gray, radius: 2, x: 0, y: 2)
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .red))
                .scaleEffect(1.5)
        }
    }
}

// MARK: - VerticalToggleView
struct VerticalToggleView: View {
    @Binding var showFollowingPosts: Bool
    let cornerSize: CGFloat = 12
    var onToggle: () -> Void
    
    var body: some View {
        HStack(spacing: 1) {
            VStack {
                Button {
                    withAnimation {
                        showFollowingPosts = false
                        onToggle()
                    }
                } label: {
                    VStack(spacing: 0) {
                        Image(systemName: "building.2")
                            .font(.title3)
                            .foregroundColor(showFollowingPosts ? .black : .white)
                        Text("All")
                            .font(.custom("MuseoSansRounded-500", size: 10))
                            .foregroundColor(showFollowingPosts ? .gray : .white)
                            .minimumScaleFactor(0.5)
                            .lineLimit(1)
                    }
                    .frame(width: 50, height: 50)
                    .background(showFollowingPosts ? Color.clear : Color.red)
                    .clipShape(RoundedRectangle(cornerRadius: cornerSize))
                }
                .disabled(!showFollowingPosts)
            }
            .padding(.trailing, 4)
            VStack {
                Button {
                    withAnimation {
                        showFollowingPosts = true
                        onToggle()
                    }
                } label: {
                    VStack(spacing: 1) {
                        Image(systemName: "person.2")
                            .font(.title3)
                            .foregroundColor(showFollowingPosts ? .white : .black)
                        Text("Friends")
                            .font(.custom("MuseoSansRounded-500", size: 10))
                            .foregroundColor(showFollowingPosts ? .white : .gray)
                            .minimumScaleFactor(0.5)
                            .lineLimit(1)
                    }
                    .frame(width: 50, height: 50)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(showFollowingPosts ? Color.red : Color.clear)
                            .shadow(color: Color.gray, radius: 1)
                    )
                }
                .disabled(showFollowingPosts)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: cornerSize)
                .fill(Color.white)
                .shadow(color: Color.gray, radius: 1)
        )
    }
}
struct GroupedPostClusterListView: View {
    let groupedPosts: [GroupedPostMapAnnotation]
    
    var body: some View {
        NavigationView {
            List(groupedPosts) { groupedPost in
                NavigationLink(destination: RestaurantProfileView(restaurantId: groupedPost.restaurant.id)) {
                    HStack {
                        AsyncImage(url: URL(string: groupedPost.restaurant.profileImageUrl ?? "")) { image in
                            image.resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 50, height: 50)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        } placeholder: {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 50, height: 50)
                        }
                        
                        VStack(alignment: .leading) {
                            Text(groupedPost.restaurant.name)
                                .font(.headline)
                            Text("\(groupedPost.postCount) posts by \(groupedPost.userCount) users")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Restaurants")
        }
    }
}

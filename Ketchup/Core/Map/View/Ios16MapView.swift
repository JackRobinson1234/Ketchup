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
struct Ios16MapView: View {
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
    @State private var selectedClusterAnnotations: [RestaurantMapAnnotation] = []
    @State private var selectedLargeCluster: LargeClusterAnnotation?
    @State var selectedLocation: CLLocationCoordinate2D?
    
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
                        selectedGroupedPost: $selectedGroupedPost,
                        selectedLargeCluster: $selectedLargeCluster,
                        isLoading: $isLoading,
                        showAlert: $showAlert,
                        mapSize: geometryProxy.size,
                        selectedLocation: $selectedLocation
                        
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
                VStack {
                                  Spacer()
                                  HStack {
                                      Spacer()
                                      userLocationButton
                                  }

                              }
            }
            .sheet(item: $selectedCluster, onDismiss: {
                selectedCluster = nil
            }) { cluster in
                ClusterRestaurantListView(restaurants: cluster.memberAnnotations.map { $0.restaurant })
            }
            .sheet(item: $selectedFollowingCluster) { cluster in
                Ios16GroupedPostClusterListView(groupedPosts: cluster.memberAnnotations)
            }
            .sheet(item: $selectedLargeCluster, onDismiss: {
                selectedLargeCluster = nil
            }) { cluster in
                ClusterRestaurantListView(restaurants: cluster.memberAnnotations)
            }
            .sheet(item: $selectedGroupedPost, onDismiss: {
                selectedGroupedPost = nil
            }) { groupedPost in
                // Present the view for the grouped post
                NavigationView {
                    RestaurantProfileView(restaurantId: groupedPost.restaurant.id)
                }
            }
            .sheet(item: $selectedRestaurant, onDismiss: {
                selectedRestaurant = nil
            }) { annotation in
                NavigationView {
                    RestaurantProfileView(restaurantId: annotation.restaurant.id)
                }
            }
            .sheet(isPresented: .constant(!selectedClusterAnnotations.isEmpty)) {
                NavigationView {
                    ClusterRestaurantListView(restaurants: selectedClusterAnnotations.map { $0.restaurant })
                        .onDisappear {
                            selectedClusterAnnotations = []
                        }
                }
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
            .overlay(
                Group {
                    if showFollowingPosts {
                        if followingViewModel.currentZoomLevel == .maxZoomOut {
                            Text("Zoom in to see posts")
                                .modifier(OverlayModifier())
                        } else if noNearbyRestaurants {
                            Text("No posts found nearby")
                                .modifier(OverlayModifier())
                        }
                    } else {
                        if viewModel.currentZoomLevel == .maxZoomOut {
                            Text("Zoom in to see restaurants")
                                .modifier(OverlayModifier())
                        } else if noNearbyRestaurants {
                            Text("No restaurants found nearby")
                                .modifier(OverlayModifier())
                        }
                    }
                }
            )
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
                        .foregroundStyle(Color("Colors/AccentColor"))
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
                        self.selectedLocation = userLocation.coordinate
                        viewModel.centerMapOnLocation(location: userLocation)
                    }
                } label: {
                    Image(systemName: "location.fill")
                        .foregroundStyle(Color("Colors/AccentColor"))
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
                .padding(.top, 30)
                Spacer()
            } else {
                VStack {
                    Ios16MapSearchView(selectedLocation: $selectedLocation, inSearchView: $inSearchView)
                        .padding(32)
                        .padding(.top, 20)
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
    @Binding var selectedGroupedPost: GroupedPostMapAnnotation?
    @Binding var selectedLargeCluster: LargeClusterAnnotation?
    @Binding var isLoading: Bool
    @Binding var showAlert: Bool
    var mapSize: CGSize
    @Binding var selectedLocation: CLLocationCoordinate2D?
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self, viewModel: viewModel, followingViewModel: followingViewModel)
    }
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView(frame: .zero)
        mapView.pointOfInterestFilter = .excludingAll
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        // Set the mapSize here
        DispatchQueue.main.async {
            self.viewModel.mapSize = mapView.bounds.size
            self.followingViewModel.mapSize = mapView.bounds.size
        }
        
        // Register annotation views
        mapView.register(Ios16RestaurantAnnotationMapView.self, forAnnotationViewWithReuseIdentifier: Ios16RestaurantAnnotationMapView.identifier)
        mapView.register(Ios16ClusterAnnotationView.self, forAnnotationViewWithReuseIdentifier: Ios16ClusterAnnotationView.identifier)
        mapView.register(Ios16LargeClusterAnnotationView.self, forAnnotationViewWithReuseIdentifier: Ios16LargeClusterAnnotationView.identifier)
        mapView.register(Ios16GroupedPostAnnotationView.self, forAnnotationViewWithReuseIdentifier: Ios16GroupedPostAnnotationView.identifier)
        mapView.register(Ios16GroupedPostClusterAnnotationView.self, forAnnotationViewWithReuseIdentifier: Ios16GroupedPostClusterAnnotationView.identifier)
        
        return mapView
    }
    
    func updateUIView(_ uiView: MKMapView, context: Context) {
        uiView.removeAnnotations(uiView.annotations)
        if let selectedLocation = selectedLocation {
            let coordinateRegion = MKCoordinateRegion(center: selectedLocation, span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05))
            uiView.setRegion(coordinateRegion, animated: true)
            // After moving the map, set selectedLocation to nil so that we don't keep moving it
            DispatchQueue.main.async {
                self.selectedLocation = nil
            }
        }
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
    
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: UIKitMapView
        var viewModel: MapViewModel
        var followingViewModel: FollowingPostsMapViewModel
        
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
                let identifier = Ios16RestaurantAnnotationMapView.identifier
                var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? Ios16RestaurantAnnotationMapView
                if annotationView == nil {
                    annotationView = Ios16RestaurantAnnotationMapView(annotation: annotation, reuseIdentifier: identifier)
                } else {
                    annotationView?.annotation = annotation
                }
                return annotationView
            } else if let clusterAnnotation = annotation as? ExampleClusterAnnotation {
                let identifier = Ios16ClusterAnnotationView.identifier
                var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? Ios16ClusterAnnotationView
                if annotationView == nil {
                    annotationView = Ios16ClusterAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                } else {
                    annotationView?.annotation = annotation
                }
                return annotationView
            } else if let largeClusterAnnotation = annotation as? LargeClusterAnnotation {
                let identifier = Ios16LargeClusterAnnotationView.identifier
                var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? Ios16LargeClusterAnnotationView
                if annotationView == nil {
                    annotationView = Ios16LargeClusterAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                } else {
                    annotationView?.annotation = annotation
                }
                return annotationView
            } else if let groupedPostAnnotation = annotation as? GroupedPostMapAnnotation {
                let identifier = Ios16GroupedPostAnnotationView.identifier
                var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? Ios16GroupedPostAnnotationView
                if annotationView == nil {
                    annotationView = Ios16GroupedPostAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                } else {
                    annotationView?.annotation = annotation
                }
                return annotationView
            } else if let groupedClusterAnnotation = annotation as? GroupedPostClusterAnnotation {
                let identifier = Ios16GroupedPostClusterAnnotationView.identifier
                var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? Ios16GroupedPostClusterAnnotationView
                if annotationView == nil {
                    annotationView = Ios16GroupedPostClusterAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                } else {
                    annotationView?.annotation = annotation
                }
                return annotationView
            }
            return nil
        }
        
        func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
            if let restaurantAnnotation = view.annotation as? RestaurantMapAnnotation {
                mapView.deselectAnnotation(restaurantAnnotation, animated: false)
                DispatchQueue.main.async {
                    self.parent.selectedRestaurant = restaurantAnnotation
                }
            } else if let clusterAnnotation = view.annotation as? ExampleClusterAnnotation {
                mapView.deselectAnnotation(clusterAnnotation, animated: false)
                DispatchQueue.main.async {
                    self.parent.selectedCluster = clusterAnnotation
                }
            } else if let largeClusterAnnotation = view.annotation as? LargeClusterAnnotation {
                mapView.deselectAnnotation(largeClusterAnnotation, animated: false)
                DispatchQueue.main.async {
                    self.parent.selectedLargeCluster = largeClusterAnnotation
                }
            } else if let groupedPostAnnotation = view.annotation as? GroupedPostMapAnnotation {
                mapView.deselectAnnotation(groupedPostAnnotation, animated: false)
                DispatchQueue.main.async {
                    self.parent.selectedGroupedPost = groupedPostAnnotation
                }
            } else if let groupedClusterAnnotation = view.annotation as? GroupedPostClusterAnnotation {
                mapView.deselectAnnotation(groupedClusterAnnotation, animated: false)
                DispatchQueue.main.async {
                    self.parent.selectedFollowingCluster = groupedClusterAnnotation
                }
            }
        }
    }
}

// MARK: - LoadingIcon
//struct LoadingIcon: View {
//    var body: some View {
//        ZStack {
//            Circle()
//                .fill(Color.white)
//                .frame(width: 50, height: 50)
//                .shadow(color: .gray, radius: 2, x: 0, y: 2)
//            ProgressView()
//                .progressViewStyle(CircularProgressViewStyle(tint: .red))
//                .scaleEffect(1.5)
//        }
//    }
//}

// MARK: - VerticalToggleView
//struct VerticalToggleView: View {
//    @Binding var showFollowingPosts: Bool
//    let cornerSize: CGFloat = 12
//    var onToggle: () -> Void
//    
//    var body: some View {
//        HStack(spacing: 1) {
//            VStack {
//                Button {
//                    withAnimation {
//                        showFollowingPosts = false
//                        onToggle()
//                    }
//                } label: {
//                    VStack(spacing: 0) {
//                        Image(systemName: "building.2")
//                            .font(.title3)
//                            .foregroundColor(showFollowingPosts ? .black : .white)
//                        Text("All")
//                            .font(.custom("MuseoSansRounded-500", size: 10))
//                            .foregroundColor(showFollowingPosts ? .gray : .white)
//                            .minimumScaleFactor(0.5)
//                            .lineLimit(1)
//                    }
//                    .frame(width: 50, height: 50)
//                    .background(showFollowingPosts ? Color.clear : Color.red)
//                    .clipShape(RoundedRectangle(cornerRadius: cornerSize))
//                }
//                .disabled(!showFollowingPosts)
//            }
//            .padding(.trailing, 4)
//            VStack {
//                Button {
//                    withAnimation {
//                        showFollowingPosts = true
//                        onToggle()
//                    }
//                } label: {
//                    VStack(spacing: 1) {
//                        Image(systemName: "person.2")
//                            .font(.title3)
//                            .foregroundColor(showFollowingPosts ? .white : .black)
//                        Text("Friends")
//                            .font(.custom("MuseoSansRounded-500", size: 10))
//                            .foregroundColor(showFollowingPosts ? .white : .gray)
//                            .minimumScaleFactor(0.5)
//                            .lineLimit(1)
//                    }
//                    .frame(width: 50, height: 50)
//                    .background(
//                        RoundedRectangle(cornerRadius: 12)
//                            .fill(showFollowingPosts ? Color.red : Color.clear)
//                            .shadow(color: Color.gray, radius: 1)
//                    )
//                }
//                .disabled(showFollowingPosts)
//            }
//        }
//        .background(
//            RoundedRectangle(cornerRadius: cornerSize)
//                .fill(Color.white)
//                .shadow(color: Color.gray, radius: 1)
//        )
//    }
//}
struct Ios16GroupedPostClusterListView: View {
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
                                .font(.custom("MuseoSansRounded-500", size: 16))
                                .lineLimit(2)
                                .foregroundStyle(.black)
                            Text("\(groupedPost.postCount) posts by \(groupedPost.userCount) users")
                                .font(.custom("MuseoSansRounded-500", size: 16))
                                .foregroundStyle(.black)
                            
                        }
                    }
                }
            }
            .navigationTitle("Restaurants")
        }
    }
}
class Ios16RestaurantAnnotationMapView: MKAnnotationView {
    static let identifier = "Ios16RestaurantAnnotationMapView"
    
    private var hostingController: UIHostingController<Ios16RestaurantAnnotationContentMapView>?
    
    override var annotation: MKAnnotation? {
        willSet {
            guard let restaurantAnnotation = newValue as? RestaurantMapAnnotation else { return }
            configure(with: restaurantAnnotation)
        }
    }
    
    private func configure(with annotation: RestaurantMapAnnotation) {
        canShowCallout = false
        self.subviews.forEach { $0.removeFromSuperview() }
        
        let restaurantView = Ios16RestaurantAnnotationContentMapView(
            imageUrl: annotation.restaurant.profileImageUrl,
            color: Color("Colors/AccentColor"),
            size: .medium,
            name: annotation.restaurant.name,
            rating: annotation.restaurant.overallRating
        )
        
        let hostingController = UIHostingController(rootView: restaurantView)
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        hostingController.view.backgroundColor = .clear
        self.addSubview(hostingController.view)
        self.hostingController = hostingController
        
        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: self.topAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            
        ])
    }
}

struct Ios16ClusterCell: View {
    var count: Int
    
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.white)
                .frame(width: 24, height: 24)
                .overlay(
                    Circle()
                        .stroke(Color("Colors/AccentColor"), lineWidth: 2)
                )
            Text("\(count)")
                .foregroundColor(.black)
                .font(.custom("MuseoSansRounded-300", size: 12))
        }
    }
}
class Ios16ClusterAnnotationView: MKAnnotationView {
    static let identifier = "Ios16ClusterAnnotationView"
    
    private var hostingController: UIHostingController<Ios16ClusterCell>?
    
    override var annotation: MKAnnotation? {
        willSet {
            guard let clusterAnnotation = newValue as? ExampleClusterAnnotation else { return }
            configure(with: clusterAnnotation)
        }
    }
    
    private func configure(with cluster: ExampleClusterAnnotation) {
        //print("SHOULD BE CONFIGURING CLUSTER")
        canShowCallout = false
        self.subviews.forEach { $0.removeFromSuperview() }
        
        // Determine the count
        let count = cluster.memberAnnotations.count
        
        // Create the SwiftUI view
        let Ios16ClusterCell = Ios16ClusterCell(count: count)
        
        // Embed the SwiftUI view into the annotation view
        let hostingController = UIHostingController(rootView: Ios16ClusterCell)
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(hostingController.view)
        self.hostingController = hostingController
        
        // Constraints
        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: self.topAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            
        ])
    }
}
struct Ios16RestaurantAnnotationContentMapView: View {
    let imageUrl: String?
    let color: Color
    let size: RestaurantImageSize
    let name: String
    var rating: Double? = nil
    
    var body: some View {
        VStack(spacing: 4) {
            RestaurantCircularProfileImageView(imageUrl: imageUrl, color: color, size: size, ratingScore: rating)
            Text(name)
                .font(.headline) // Increased from .caption2 to .headline
                .foregroundColor(.black)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .frame(width: size.dimension * 1.5)
        }
    }
}
class Ios16LargeClusterAnnotationView: MKAnnotationView {
    static let identifier = "Ios16LargeClusterAnnotationView"
    
    private var hostingController: UIHostingController<Ios16ClusterCell>?
    
    override var annotation: MKAnnotation? {
        willSet {
            guard let largeClusterAnnotation = newValue as? LargeClusterAnnotation else { return }
            configure(with: largeClusterAnnotation)
        }
    }
    
    private func configure(with annotation: LargeClusterAnnotation) {
        canShowCallout = false
        self.subviews.forEach { $0.removeFromSuperview() }
        
        let Ios16ClusterCell = Ios16ClusterCell(count: annotation.count)
        
        let hostingController = UIHostingController(rootView: Ios16ClusterCell)
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(hostingController.view)
        self.hostingController = hostingController
        
        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: self.topAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            
        ])
    }
}
class Ios16GroupedPostAnnotationView: MKAnnotationView {
    static let identifier = "Ios16GroupedPostAnnotationView"
    
    private var hostingController: UIHostingController<Ios16GroupedPostAnnotationContentView>?
    
    override var annotation: MKAnnotation? {
        willSet {
            guard let groupedPostAnnotation = newValue as? GroupedPostMapAnnotation else { return }
            configure(with: groupedPostAnnotation)
        }
    }
    
    private func configure(with annotation: GroupedPostMapAnnotation) {
        canShowCallout = false
        self.subviews.forEach { $0.removeFromSuperview() }
        
        let groupedPostView = Ios16GroupedPostAnnotationContentView(groupedPost: annotation)
        
        let hostingController = UIHostingController(rootView: groupedPostView)
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(hostingController.view)
        self.hostingController = hostingController
        
        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: self.topAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            
        ])
    }
}
class Ios16GroupedPostClusterAnnotationView: MKAnnotationView {
    static let identifier = "Ios16GroupedPostClusterAnnotationView"
    
    private var hostingController: UIHostingController<Ios16GroupedPostClusterCell>?
    
    override var annotation: MKAnnotation? {
        willSet {
            guard let clusterAnnotation = newValue as? GroupedPostClusterAnnotation else { return }
            configure(with: clusterAnnotation)
        }
    }
    
    private func configure(with cluster: GroupedPostClusterAnnotation) {
        canShowCallout = false
        self.subviews.forEach { $0.removeFromSuperview() }
        
        let Ios16ClusterCell = Ios16GroupedPostClusterCell(cluster: cluster)
        
        let hostingController = UIHostingController(rootView: Ios16ClusterCell)
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(hostingController.view)
        self.hostingController = hostingController
        
        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: self.topAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            
        ])
    }
}
struct Ios16GroupedPostClusterCell: View {
    var cluster: GroupedPostClusterAnnotation
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.white)
                .frame(width: 20, height: 20)
                .overlay(
                    Circle()
                        .stroke(Color("Colors/AccentColor"), lineWidth: 2)
                )
            Text("\(cluster.count)")
                .foregroundColor(.black)
                .font(.custom("MuseoSansRounded-300", size: 10))
        }
    }
}
struct Ios16GroupedPostAnnotationContentView: View {
    let groupedPost: GroupedPostMapAnnotation
    
    private func calculateOverallRating(for post: SimplifiedPost) -> Double? {
        let ratings = [post.serviceRating, post.atmosphereRating, post.valueRating, post.foodRating]
        let validRatings = ratings.compactMap { $0 }
        guard !validRatings.isEmpty else { return nil }
        return validRatings.reduce(0, +) / Double(validRatings.count)
    }
    
    private var averageRating: String {
        let overallRatings = groupedPost.posts.compactMap { calculateOverallRating(for: $0) }
        guard !overallRatings.isEmpty else { return "N/A" }
        let average = overallRatings.reduce(0, +) / Double(overallRatings.count)
        return String(format: "%.1f", average)
    }
    
    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                RestaurantCircularProfileImageView(imageUrl: groupedPost.restaurant.profileImageUrl, color: Color("Colors/AccentColor"), size: .medium)
                    .frame(width: 50, height: 50)
                
                VStack {
                    HStack {
                        Spacer()
                        Text(averageRating)
                            .font(.custom("MuseoSansRounded-700", size: 11))
                            .foregroundColor(.black)
                            .padding(2)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(.white)
                                    .shadow(color: Color.gray, radius: 1)
                            )
                    }
                    Spacer()
                }
                
                VStack {
                    Spacer()
                    HStack(spacing: 1) {
                        Image(systemName: "person.2")
                            .font(.system(size: 10))
                            .foregroundColor(.white)
                        Text("\(groupedPost.posts.count)")
                            .font(.custom("MuseoSansRounded-500", size: 10))
                            .foregroundColor(.white)
                    }
                    .padding(3)
                    .background(Color("Colors/AccentColor"))
                    .clipShape(Capsule())
                    .padding(.bottom, -8) // Shift it slightly lower
                }
            }
            Text(groupedPost.restaurant.name)
                .font(.headline)
                .foregroundColor(.black)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .frame(width: 70)
        }
        .padding(.bottom,5)
    }
}

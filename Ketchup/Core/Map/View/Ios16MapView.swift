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
    @State private var selectedRestaurant: ClusterRestaurant?
    @State private var selectedRestaurantForProfile: ClusterRestaurant?
    @State private var selectedRestaurantIndex: Int = 0 // Declare selectedRestaurantIndex
    @State private var isUserSelectingRestaurant = false
    @State private var currentRegion: MKCoordinateRegion = MKCoordinateRegion()
    @State private var lastCameraCenter: CLLocationCoordinate2D?
    @State private var hasAppeared = false
    @State private var showFollowingPosts = false
    @State private var inSearchView: Bool = false
    @State private var isFiltersPresented: Bool = false
    @State private var isLoading = true
    @State private var showAlert = false
    @State private var selectedCluster: ExampleClusterAnnotation?
    @State private var selectedFollowingCluster: GroupedPostClusterAnnotation?
    @State private var selectedLargeCluster: LargeClusterAnnotation?
    @State var selectedLocation: CLLocationCoordinate2D?
    @Namespace var mapScope

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
            VStack(spacing:0) {
                GeometryReader { geometryProxy in
                    UIKitMapView(
                        viewModel: viewModel,
                        followingViewModel: followingViewModel,
                        showFollowingPosts: $showFollowingPosts,
                        selectedRestaurant: $selectedRestaurant,
                        selectedRestaurantIndex: $selectedRestaurantIndex, // Pass as binding
                        selectedRestaurantForProfile: $selectedRestaurantForProfile,
                        selectedCluster: $selectedCluster,
                        selectedFollowingCluster: $selectedFollowingCluster,
                        selectedGroupedPost: .constant(nil),
                        selectedLargeCluster: $selectedLargeCluster,
                        isLoading: $isLoading,
                        showAlert: $showAlert,
                        mapSize: geometryProxy.size,
                        selectedLocation: $selectedLocation,
                        currentRegion: $currentRegion,
                        isUserSelectingRestaurant: $isUserSelectingRestaurant,
                        lastCameraCenter: $lastCameraCenter
                    )
                    .edgesIgnoringSafeArea(.all)
                    // Place buttons over the map only
                    .overlay(alignment: .bottomTrailing) {
                        userLocationButton
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
                // Loading indicator
               
                // RestaurantSlideUpSheet
                RestaurantSlideUpSheet(
                    restaurants: $viewModel.flattenedRestaurants,
                    selectedIndex: $selectedRestaurantIndex,
                    onDismiss: {
                        selectedRestaurant = nil
                    },
                    onSelectRestaurant: { restaurant in
                        navigateToRestaurantProfile(restaurant)
                    },
                    onRestaurantSwipe: { newIndex in
                        selectedRestaurant = viewModel.flattenedRestaurants[newIndex]
                    }
                )

                // Overlay for alerts and messages
                
            }
            // Present search view as a sheet
            .sheet(isPresented: $inSearchView) {
                Ios16MapSearchView(selectedLocation: $selectedLocation, inSearchView: $inSearchView)
                    .presentationDetents([.height(UIScreen.main.bounds.height * 0.65)])
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
            .sheet(item: $selectedRestaurantForProfile, onDismiss: {
                selectedRestaurantForProfile = nil
            }) { restaurant in
                NavigationView {
                    RestaurantProfileView(restaurantId: restaurant.id)
                }
            }
            .navigationBarHidden(true)

            .onAppear {
                if !hasAppeared {
                    Task {
                        LocationManager.shared.requestLocation()
                        if let userLocation = LocationManager.shared.userLocation {
                            selectedLocation = userLocation.coordinate
                        } else {
                            selectedLocation = CLLocationCoordinate2D(latitude: 34.0549, longitude: -118.2426)
                        }
                        await fetchRestaurantsInView(center: selectedLocation ?? CLLocationCoordinate2D(latitude: 34.0549, longitude: -118.2426))
                        hasAppeared = true
                    }
                }
            }
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("Location Permission Required"),
                    message: Text("The app needs access to your location to show nearby restaurants. Please go to Settings and enable location permissions."),
                    primaryButton: .default(Text("Go to Settings")) {
                        if let url = URL(string: UIApplication.openSettingsURLString), UIApplication.shared.canOpenURL(url) {
                            UIApplication.shared.open(url, options: [:], completionHandler: nil)
                        }
                    },
                    secondaryButton: .cancel()
                )
            }
            .sheet(isPresented: $isFiltersPresented) {
                MapFiltersView(mapViewModel: viewModel, followingViewModel: followingViewModel, showFollowingPosts: $showFollowingPosts)
                    .presentationDetents([.height(UIScreen.main.bounds.height * 0.65)])
            }
            // OnChange modifiers for filters
            .onChange(of: viewModel.selectedCuisines) { _ in
                Task {
                    if showFollowingPosts {
                        await followingViewModel.fetchFollowingPosts()
                    } else {
                        await viewModel.fetchFilteredClusters()
                    }
                }
            }
            .onChange(of: viewModel.selectedPrice) { _ in
                Task {
                    if showFollowingPosts {
                        await followingViewModel.fetchFollowingPosts()
                    } else {
                        await viewModel.fetchFilteredClusters()
                    }
                }
            }
            .onChange(of: viewModel.selectedRating) { _ in
                Task {
                    if showFollowingPosts {
                        await followingViewModel.fetchFollowingPosts()
                    } else {
                        await viewModel.fetchFilteredClusters()
                    }
                }
            }
        }
    }

    // MARK: - User Location Button
    private var userLocationButton: some View {
        VStack {
            // Location Button
            Button(action: {
                inSearchView = true
            }) {
                VStack(spacing: 4) {
                    Image(systemName: "scope")
                        .foregroundColor(Color("Colors/AccentColor"))
                        .font(.system(size: 18))
                    Text("Location")
                        .font(.custom("MuseoSansRounded-500", size: 10))
                        .foregroundColor(.black)
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                }
                .frame(width: 34)
                .padding(4)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white)
                        .shadow(color: .gray, radius: 1)
                )
            }

            // Filters Button
            Button(action: {
                isFiltersPresented = true
            }) {
                VStack(spacing: 4) {
                    Image(systemName: "slider.horizontal.3")
                        .foregroundColor(.red)
                        .font(.system(size: 20))
                    Text("Filters")
                        .font(.custom("MuseoSansRounded-500", size: 10))
                        .foregroundColor(.black)
                        .minimumScaleFactor(0.5)
                }
                .frame(width: 34)
                .padding(4)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white)
                        .shadow(color: .gray, radius: 1)
                )
            }
        }
        .padding([.bottom, .trailing], 20)
    }

    // MARK: - Navigate to Restaurant Profile
    private func navigateToRestaurantProfile(_ restaurant: ClusterRestaurant) {
        selectedRestaurantForProfile = restaurant
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


struct UIKitMapView: UIViewRepresentable {
    @ObservedObject var viewModel: MapViewModel
    @ObservedObject var followingViewModel: FollowingPostsMapViewModel
    @Binding var showFollowingPosts: Bool
    @Binding var selectedRestaurant: ClusterRestaurant?
    @Binding var selectedRestaurantIndex: Int // Add binding for selectedRestaurantIndex
    @Binding var selectedRestaurantForProfile: ClusterRestaurant?
    @Binding var selectedCluster: ExampleClusterAnnotation?
    @Binding var selectedFollowingCluster: GroupedPostClusterAnnotation?
    @Binding var selectedGroupedPost: GroupedPostMapAnnotation?
    @Binding var selectedLargeCluster: LargeClusterAnnotation?
    @Binding var isLoading: Bool
    @Binding var showAlert: Bool
    var mapSize: CGSize
    @Binding var selectedLocation: CLLocationCoordinate2D?
    @Binding var currentRegion: MKCoordinateRegion
    @Binding var isUserSelectingRestaurant: Bool
    @Binding var lastCameraCenter: CLLocationCoordinate2D?

    func makeCoordinator() -> Coordinator {
        Coordinator(self, viewModel: viewModel, followingViewModel: followingViewModel)
    }

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView(frame: .zero)
        mapView.pointOfInterestFilter = .excludingAll
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        DispatchQueue.main.async {
            self.viewModel.mapSize = mapView.bounds.size
            self.followingViewModel.mapSize = mapView.bounds.size
        }

        // Register annotation views
        mapView.register(Ios16RestaurantAnnotationMapView.self, forAnnotationViewWithReuseIdentifier: Ios16RestaurantAnnotationMapView.identifier)
        // ... register other annotation views ...

        // Add gesture recognizer to detect user interaction
        let panGesture = UIPanGestureRecognizer(target: context.coordinator, action: #selector(context.coordinator.handlePanGesture(_:)))
        panGesture.delegate = context.coordinator
        mapView.addGestureRecognizer(panGesture)

        return mapView
    }

    func updateUIView(_ uiView: MKMapView, context: Context) {
        var newAnnotations: [MKAnnotation] = []
        if showFollowingPosts {
            newAnnotations = followingViewModel.annotations + followingViewModel.clusters
        } else {
            newAnnotations = viewModel.annotations + viewModel.clusters + viewModel.largeClusters
        }

        let currentAnnotations = uiView.annotations

        // Compute annotations to add and remove
        let annotationsToRemove = currentAnnotations.filter { currentAnnotation in
            guard let currentIdentifiable = currentAnnotation as? IdentifiableAnnotation else { return false }
            return !newAnnotations.contains(where: { newAnnotation in
                guard let newIdentifiable = newAnnotation as? IdentifiableAnnotation else { return false }
                return newIdentifiable.id == currentIdentifiable.id
            })
        }

        let annotationsToAdd = newAnnotations.filter { newAnnotation in
            guard let newIdentifiable = newAnnotation as? IdentifiableAnnotation else { return false }
            return !currentAnnotations.contains(where: { currentAnnotation in
                guard let currentIdentifiable = currentAnnotation as? IdentifiableAnnotation else { return false }
                return currentIdentifiable.id == newIdentifiable.id
            })
        }

        uiView.removeAnnotations(annotationsToRemove)
        uiView.addAnnotations(annotationsToAdd)

        if let selectedLocation = selectedLocation {
            let coordinateRegion = MKCoordinateRegion(center: selectedLocation, span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05))
            uiView.setRegion(coordinateRegion, animated: true)
            DispatchQueue.main.async {
                self.selectedLocation = nil
            }
        }

        DispatchQueue.main.async {
            viewModel.mapSize = mapSize
            followingViewModel.mapSize = mapSize
        }
    }

    class Coordinator: NSObject, MKMapViewDelegate, UIGestureRecognizerDelegate {
        var parent: UIKitMapView
        var viewModel: MapViewModel
        var followingViewModel: FollowingPostsMapViewModel

        init(_ parent: UIKitMapView, viewModel: MapViewModel, followingViewModel: FollowingPostsMapViewModel) {
            self.parent = parent
            self.viewModel = viewModel
            self.followingViewModel = followingViewModel
        }

        func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
            parent.isUserSelectingRestaurant = true
        }

        func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
            let newRegion = mapView.region
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.parent.currentRegion = newRegion
                if !self.parent.showFollowingPosts {
                    self.viewModel.updateMapState(newRegion: newRegion)
                    Task { await self.viewModel.reloadAnnotations() }
                } else {
                    self.followingViewModel.updateMapState(newRegion: newRegion)
                    Task { await self.followingViewModel.reloadAnnotations() }
                }
                if !self.parent.isUserSelectingRestaurant && !self.viewModel.isLoading && !self.viewModel.flattenedRestaurants.isEmpty {
                    self.parent.updateSelectedRestaurant(for: newRegion)
                }
                self.parent.isUserSelectingRestaurant = false
            }
        }

        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            // Your existing code to return the appropriate annotation view
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
                    self.parent.selectedRestaurantForProfile = restaurantAnnotation.restaurant
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


        @objc func handlePanGesture(_ gesture: UIPanGestureRecognizer) {
            switch gesture.state {
            case .began:
                parent.isUserSelectingRestaurant = true
            case .ended, .cancelled, .failed:
                parent.isUserSelectingRestaurant = false
            default:
                break
            }
        }

        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
            return true
        }
    }

    // Update selectedRestaurant and selectedRestaurantIndex
    func updateSelectedRestaurant(for region: MKCoordinateRegion) {
        if isUserSelectingRestaurant {
            return
        }

        let centerCoordinate = region.center

        var closestRestaurant: ClusterRestaurant?
        var closestDistance: CLLocationDistance = Double.greatestFiniteMagnitude
        var closestIndex: Int = 0

        for (index, restaurant) in viewModel.flattenedRestaurants.enumerated() {
            let distance = calculateDistance(from: centerCoordinate, to: restaurant.coordinate)
            if distance < closestDistance {
                closestDistance = distance
                closestRestaurant = restaurant
                closestIndex = index
            }
        }

        if let closestRestaurant = closestRestaurant {
            selectedRestaurant = closestRestaurant
            selectedRestaurantIndex = closestIndex // Update selectedRestaurantIndex
        }
    }

    private func calculateDistance(from coordinate1: CLLocationCoordinate2D, to coordinate2: CLLocationCoordinate2D) -> Double {
        let location1 = CLLocation(latitude: coordinate1.latitude, longitude: coordinate1.longitude)
        let location2 = CLLocation(latitude: coordinate2.latitude, longitude: coordinate2.longitude)
        return location1.distance(from: location2)
    }
}




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

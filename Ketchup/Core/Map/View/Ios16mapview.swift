//
//  Ios16mapview.swift
//  Ketchup
//
//  Created by Jack Robinson on 9/20/24.
//

import SwiftUI
import MapKit

//struct Ios16MapView: View {
//    @StateObject var viewModel: MapViewModel = MapViewModel()
//    @StateObject var followingViewModel = FollowingPostsMapViewModel()
//    @State private var region = MKCoordinateRegion()
//    @State private var selectedRestaurant: RestaurantMapAnnotation?
//    @State private var selectedGroupedPost: GroupedPostMapAnnotation?
//    @State private var showRestaurantPreview = false
//    @State private var inSearchView: Bool = false
//    @State private var isSearchPresented: Bool = false
//    @State private var isFiltersPresented: Bool = false
//    @State var isLoading = true
//    @State var center: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 0, longitude: 0)
//    @State private var showAlert = false
//    @State private var selectedCluster: ExampleClusterAnnotation?
//    @State private var selectedFollowingCluster: GroupedPostClusterAnnotation?
//    @State private var hasAppeared = false
//    @State private var showMoveWarning = false
//    @State private var showFollowingPosts = false
//
//    private var noNearbyRestaurants: Bool {
//        if showFollowingPosts {
//            return followingViewModel.annotations.isEmpty && followingViewModel.clusters.isEmpty && !followingViewModel.isLoading
//        } else {
//            return viewModel.annotations.isEmpty && viewModel.clusters.isEmpty && viewModel.largeClusters.isEmpty && !viewModel.isLoading
//        }
//    }
//
//    private var isZoomedOutTooFar: Bool {
//        if showFollowingPosts {
//            return followingViewModel.currentZoomLevel == .maxZoomOut
//        } else {
//            return viewModel.currentZoomLevel == .maxZoomOut
//        }
//    }
//
//    var body: some View {
//        NavigationView {
//            ZStack(alignment: .bottom) {
//                MapViewRepresentable(
//                    region: $region,
//                    annotations:  viewModel.annotations,
//                    clusters:  viewModel.clusters,
//                    largeClusters: viewModel.largeClusters,
//                    onRegionChange: { newRegion in
//                        if !self.region.isEqual(to: newRegion, withTolerance: 0.001) {
//                            self.region = newRegion
//                            updateMapSize()
//                            if showFollowingPosts {
//                                followingViewModel.updateMapState(newRegion: newRegion)
//                            } else {
//                                viewModel.updateMapState(newRegion: newRegion)
//                            }
//                            
//                        }
//                        print("DEBUG: Region changed to \(newRegion.center), span: \(newRegion.span)")
//
//                    },
//                    onAnnotationSelected: { annotation in
//                        if showFollowingPosts {
//                            if let groupedPost = annotation as? GroupedPostMapAnnotation {
//                                selectedGroupedPost = groupedPost
//                            }
//                        } else {
//                            if let restaurant = annotation as? RestaurantMapAnnotation {
//                                selectedRestaurant = restaurant
//                                showRestaurantPreview = true
//                            }
//                        }
//                        print("DEBUG: Annotation selected: \(annotation)")
//
//                    },
//                    onClusterSelected: { cluster in
//                        if showFollowingPosts {
//                            selectedFollowingCluster = cluster as? GroupedPostClusterAnnotation
//                        } else {
//                            selectedCluster = cluster as? ExampleClusterAnnotation
//                        }
//                        print("DEBUG: Cluster selected: \(cluster)")
//
//                    }
//                )
//                .edgesIgnoringSafeArea(.all)
//                .overlay {
//                    if showFollowingPosts {
//                        if followingViewModel.currentZoomLevel == .maxZoomOut {
//                            Text("Zoom in to see posts")
//                                .modifier(OverlayModifier())
//                                .font(.custom("MuseoSansRounded-300", size: 14))
//                        } else if noNearbyRestaurants {
//                            Text("No posts found nearby")
//                                .modifier(OverlayModifier())
//                                .font(.custom("MuseoSansRounded-300", size: 14))
//                        }
//                    } else {
//                        if viewModel.currentZoomLevel == .maxZoomOut {
//                            Text("Zoom in to see restaurants")
//                                .modifier(OverlayModifier())
//                                .font(.custom("MuseoSansRounded-300", size: 14))
//                        } else if noNearbyRestaurants {
//                            Text("No restaurants found nearby")
//                                .modifier(OverlayModifier())
//                                .font(.custom("MuseoSansRounded-300", size: 14))
//                        }
//                    }
//                }
//                .overlay(alignment: .bottomTrailing) {
//                    userLocationButton
//                }
//
//                topRow
//
//                if (showFollowingPosts ? followingViewModel.isLoading : viewModel.isLoading) {
//                    VStack {
//                        Spacer()
//                        HStack {
//                            Spacer()
//                            FastCrossfadeFoodImageView()
//                                .padding([.bottom, .trailing], 20)
//                                .padding(.bottom, 50)
//                        }
//                    }
//                }
//            }
//            .sheet(item: $selectedCluster) { cluster in
//                ClusterRestaurantListView(restaurants: cluster.memberAnnotations.map { $0.restaurant })
//            }
//            .sheet(item: $selectedFollowingCluster) { cluster in
//                GroupedPostClusterListView(groupedPosts: cluster.memberAnnotations)
//            }
//            .onAppear {
//                updateMapSize()
//                if !hasAppeared {
//                    Task {
//                        LocationManager.shared.requestLocation()
//                        if let userLocation = LocationManager.shared.userLocation {
//                            center = userLocation.coordinate
//                            region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1))
//                        } else {
//                            center = CLLocationCoordinate2D(latitude: 34.0549, longitude: -118.2426)
//                            region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1))
//                        }
//                        print("DEBUG: Initial center set to \(center)")
//
//                        await fetchRestaurantsInView(center: center)
//                        hasAppeared = true
//                    }
//                }
//                
//            }
//            .alert(isPresented: $showAlert) {
//                Alert(
//                    title: Text("Location Permission Required"),
//                    message: Text("Ketchup needs access to your location to show nearby restaurants. Please go to Settings and enable location permissions."),
//                    primaryButton: .default(Text("Go to Settings")) {
//                        if let url = URL(string: UIApplication.openSettingsURLString), UIApplication.shared.canOpenURL(url) {
//                            UIApplication.shared.open(url, options: [:], completionHandler: nil)
//                        }
//                    },
//                    secondaryButton: .cancel()
//                )
//            }
//            .fullScreenCover(isPresented: $isFiltersPresented) {
//                MapFiltersView(mapViewModel: viewModel, followingPostsMapViewModel: followingViewModel, showFollowingPosts: $showFollowingPosts)
//            }
//        }
//    }
//
//    private var userLocationButton: some View {
//        Button(action: {
//            if LocationManager.shared.userLocation == nil {
//                showAlert = true
//            } else {
//                withAnimation {
//                    region.center = LocationManager.shared.userLocation!.coordinate
//                }
//            }
//        }) {
//            Image(systemName: "location.fill")
//                .foregroundColor(.blue)
//                .padding()
//                .background(Color.white)
//                .clipShape(Circle())
//                .shadow(radius: 2)
//        }
//        .padding([.bottom, .trailing], 20)
//    }
//
//    private var topRow: some View {
//        VStack {
//            if !inSearchView {
//                HStack(alignment: .bottom) {
//                    Button {
//                        inSearchView.toggle()
//                    } label: {
//                        VStack {
//                            Image(systemName: "magnifyingglass")
//                                .imageScale(.large)
//                                .font(.title3)
//                                .foregroundStyle(.black)
//                            
//                            Text("Search")
//                                .foregroundStyle(.gray)
//                                .font(.custom("MuseoSansRounded-500", size: 10))
//                                .lineLimit(1)
//                                .minimumScaleFactor(0.5)
//                        }
//                        .frame(width: 50, height: 50)
//                        .background(
//                            RoundedRectangle(cornerRadius: 12)
//                                .fill(.white)
//                                .shadow(color: Color.gray, radius: 1)
//                        )
//                    }
//                    Spacer()
//                    VerticalToggleView(showFollowingPosts: $showFollowingPosts) {
//                        handleToggleChange()
//                    }
//                    Spacer()
//                    
//                    Button {
//                        isFiltersPresented.toggle()
//                    } label: {
//                        VStack {
//                            ZStack {
//                                Image(systemName: "slider.horizontal.3")
//                                    .imageScale(.large)
//                                    .font(.title3)
//                                    .foregroundStyle(.black)
//                                if viewModel.filters.count > 1 {
//                                    Circle()
//                                        .fill(Color("Colors/AccentColor"))
//                                        .frame(width: 12, height: 12)
//                                        .offset(x: 12, y: 12)
//                                }
//                            }
//                            Text("Filters")
//                                .foregroundStyle(.gray)
//                                .font(.custom("MuseoSansRounded-500", size: 10))
//                                .lineLimit(1)
//                                .minimumScaleFactor(0.5)
//                        }
//                        .frame(width: 50, height: 50)
//                        .background(
//                            RoundedRectangle(cornerRadius: 12)
//                                .fill(.white)
//                                .shadow(color: Color.gray, radius: 1)
//                        )
//                    }
//                }
//                .padding(.horizontal, 25)
//                .padding(.top, 60)
//                Spacer()
//            } else {
//                VStack {
////                    MapSearchView(region: $region, inSearchView: $inSearchView)
////                        .padding(32)
////                        .padding(.top, 20)
//                    Spacer()
//                }
//            }
//        }
//        .animation(.spring(), value: inSearchView)
//    }
//
//    private func handleToggleChange() {
//        Task {
//            await MainActor.run {
//                if showFollowingPosts {
//                    followingViewModel.updateMapState(newRegion: region, shouldAutoFetch: true)
//                } else {
//                    viewModel.updateMapState(newRegion: region, shouldAutoFetch: true)
//                }
//            }
//        }
//    }
//
//    private func fetchRestaurantsInView(center: CLLocationCoordinate2D) async {
//        print("DEBUG: Fetching restaurants for center: \(center)")
//               if showFollowingPosts {
//                   if followingViewModel.currentZoomLevel == .maxZoomOut {
//                       print("DEBUG: Following view is zoomed out too far")
//                       return
//                   }
//            
//            let distanceThreshold = MapUtils.calculateDistanceThreshold(for: region)
//            if let lastLocation = followingViewModel.selectedLocation.first {
//                let distance = MapUtils.calculateDistance(from: lastLocation, to: center)
//                if distance >= distanceThreshold {
//                    followingViewModel.selectedLocation = [center]
//                    await followingViewModel.fetchFollowingPosts()
//                }
//            } else {
//                followingViewModel.selectedLocation = [center]
//                await followingViewModel.fetchFollowingPosts()
//            }
//        } else {
//            if viewModel.currentZoomLevel == .maxZoomOut {
//                print("DEBUG: Map is zoomed out too far")
//
//                return
//            }
//            let distanceThreshold = MapUtils.calculateDistanceThreshold(for: region)
//                       print("DEBUG: Distance threshold: \(distanceThreshold)")
//                       if let lastLocation = viewModel.selectedLocation.first {
//                           let distance = MapUtils.calculateDistance(from: lastLocation, to: center)
//                           print("DEBUG: Distance from last fetch: \(distance)")
//                           if distance >= distanceThreshold {
//                               viewModel.selectedLocation = [center]
//                               print("DEBUG: Fetching new clusters")
//                               await viewModel.fetchFilteredClusters()
//                           } else {
//                               print("DEBUG: Not fetching new clusters, distance too small")
//                           }
//            } else {
//                viewModel.selectedLocation = [center]
//                                print("DEBUG: First time fetching clusters")
//                                await viewModel.fetchFilteredClusters()
//            }
//        }
//    }
//}
//struct MapViewRepresentable: UIViewRepresentable {
//    @Binding var region: MKCoordinateRegion
//    var annotations: [RestaurantMapAnnotation]
//    var clusters: [ExampleClusterAnnotation]
//    var largeClusters: [LargeClusterAnnotation]
//    var onRegionChange: (MKCoordinateRegion) -> Void
//    var onAnnotationSelected: (MKAnnotation) -> Void
//    var onClusterSelected: (MKAnnotation) -> Void
//    func makeUIView(context: Context) -> MKMapView {
//            let mapView = MKMapView()
//            mapView.delegate = context.coordinator
//            mapView.showsUserLocation = true
//            mapView.setRegion(region, animated: false)
//            print("DEBUG: MapView created with initial region: \(region)")
//            return mapView
//        }
//        
//        func updateUIView(_ uiView: MKMapView, context: Context) {
//            if !uiView.region.isEqual(to: region, withTolerance: 0.001) {
//                uiView.setRegion(region, animated: true)
//                print("DEBUG: MapView region updated to: \(region)")
//            }
//            updateAnnotations(uiView)
//        }
//    
//    func makeCoordinator() -> Coordinator {
//        Coordinator(self)
//    }
//    
//    private func updateAnnotations(_ mapView: MKMapView) {
//           mapView.removeAnnotations(mapView.annotations)
//           
//           let allAnnotations = annotations + clusters.map { $0 as MKAnnotation } + largeClusters.map { $0 as MKAnnotation }
//           mapView.addAnnotations(allAnnotations)
//           print("DEBUG: Updated annotations - Restaurants: \(annotations.count), Clusters: \(clusters.count), Large Clusters: \(largeClusters.count)")
//       }
//    class Coordinator: NSObject, MKMapViewDelegate {
//        var parent: MapViewRepresentable
//        
//        init(_ parent: MapViewRepresentable) {
//            self.parent = parent
//        }
//        
//        func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
//            parent.onRegionChange(mapView.region)
//        }
//        
//        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
//            if let cluster = annotation as? ExampleClusterAnnotation {
//                let identifier = "cluster"
//                var view: MKMarkerAnnotationView
//                
//                if let dequeuedView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView {
//                    dequeuedView.annotation = annotation
//                    view = dequeuedView
//                } else {
//                    view = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
//                }
//                
//                view.markerTintColor = .blue
//                view.glyphText = "\(cluster.count)"
//                return view
//            } else if let restaurant = annotation as? RestaurantMapAnnotation {
//                let identifier = "restaurant"
//                var view: MKAnnotationView
//                
//                if let dequeuedView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) {
//                    dequeuedView.annotation = annotation
//                    view = dequeuedView
//                } else {
//                    view = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
//                    view.canShowCallout = true
//                }
//                
//                // Customize the view for the restaurant annotation
//                // You might want to use a custom image or view here
//                view.image = UIImage(systemName: "mappin")
//                return view
//            } else if let largeCluster = annotation as? LargeClusterAnnotation {
//                let identifier = "largeCluster"
//                var view: MKMarkerAnnotationView
//                
//                if let dequeuedView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView {
//                    dequeuedView.annotation = annotation
//                    view = dequeuedView
//                } else {
//                    view = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
//                }
//                
//                view.markerTintColor = .red
//                view.glyphText = "\(largeCluster.count)"
//                return view
//            }
//            print("DEBUG: Creating view for annotation: \(type(of: annotation))")
//
//            return nil
//        }
//        
//        func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
//            if let cluster = view.annotation as? ExampleClusterAnnotation {
//                parent.onClusterSelected(cluster)
//                print("DEBUG: Selected cluster with \(cluster.count) items")
//            } else if let restaurant = view.annotation as? RestaurantMapAnnotation {
//                parent.onAnnotationSelected(restaurant)
//                print("DEBUG: Selected restaurant: \(restaurant.restaurant.name)")
//            } else if let largeCluster = view.annotation as? LargeClusterAnnotation {
//                parent.onClusterSelected(largeCluster)
//                print("DEBUG: Selected large cluster with \(largeCluster.count) items")
//            }
//        }
//    }
//}
//
//
////struct GroupedPostClusterListView: View {
////    let groupedPosts: [GroupedPostMapAnnotation]
////    
////    var body: some View {
////        List(groupedPosts, id: \.id) { groupedPost in
////            NavigationLink(destination: RestaurantProfileView(restaurantId: groupedPost.restaurant.id)) {
////                Text(groupedPost.restaurant.name)
////            }
////        }
////    }
////}
//
////struct VerticalToggleView: View {
////    @Binding var showFollowingPosts: Bool
////    var action: () -> Void
////    
////    var body: some View {
////        VStack(spacing: 0) {
////            Button(action: {
////                showFollowingPosts = false
////                action()
////            }) {
////                Text("All")
////                    .padding(8)
////                    .frame(width: 90)
////                    .background(showFollowingPosts ? Color.white : Color.blue)
////                    .foregroundColor(showFollowingPosts ? .black : .white)
////            }
////            
////            Button(action: {
////                showFollowingPosts = true
////                action()
////            }) {
////                Text("Following")
////                    .padding(8)
////                    .frame(width: 90)
////                    .background(showFollowingPosts ? Color.blue : Color.white)
////                    .foregroundColor(showFollowingPosts ? .white : .black)
////            }
////        }
////        .background(Color.white)
////        .cornerRadius(8)
////        .shadow(radius: 2)
////    }
////}
//    extension MKCoordinateRegion {
//        func isEqual(to other: MKCoordinateRegion, withTolerance tolerance: CLLocationDegrees) -> Bool {
//            return abs(center.latitude - other.center.latitude) < tolerance &&
//                   abs(center.longitude - other.center.longitude) < tolerance &&
//                   abs(span.latitudeDelta - other.span.latitudeDelta) < tolerance &&
//                   abs(span.longitudeDelta - other.span.longitudeDelta) < tolerance
//        }
//    }
//extension Ios16MapView {
//    func calculateMapDistance() -> (width: CLLocationDistance, height: CLLocationDistance) {
//        let center = region.center
//        let span = region.span
//        
//        let topLeft = CLLocation(latitude: center.latitude + (span.latitudeDelta/2),
//                                 longitude: center.longitude - (span.longitudeDelta/2))
//        let topRight = CLLocation(latitude: center.latitude + (span.latitudeDelta/2),
//                                  longitude: center.longitude + (span.longitudeDelta/2))
//        let bottomLeft = CLLocation(latitude: center.latitude - (span.latitudeDelta/2),
//                                    longitude: center.longitude - (span.longitudeDelta/2))
//        
//        let width = topLeft.distance(from: topRight)
//        let height = topLeft.distance(from: bottomLeft)
//        
//        return (width, height)
//    }
//    
//    func updateMapSize() {
//        let (width, height) = calculateMapDistance()
//        let mapSize = CGSize(width: width, height: height)
//        viewModel.mapSize = mapSize
//        followingViewModel.mapSize = mapSize
//    }
//}

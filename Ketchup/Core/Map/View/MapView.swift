//
//  Ios16mapview.swift
//  Ketchup
//
//  Created by Jack Robinson on 9/20/24.
//

import SwiftUI
import MapKit

import SwiftUI
import MapKit
import ClusterMap
import ClusterMapSwiftUI
@available(iOS 17.0, *)
struct MapView: View {
    @StateObject var viewModel: MapViewModel = MapViewModel()
    @StateObject var followingViewModel = FollowingPostsMapViewModel()
    @State var position: MapCameraPosition
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
    init() {
        self._viewModel = StateObject(wrappedValue: MapViewModel())
        self._position = State(initialValue: .userLocation(fallback: .automatic))
    }
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                GeometryReader { geometryProxy in
                    Map(position: $position, scope: mapScope) {
                        if showFollowingPosts {
                            ForEach(followingViewModel.annotations, id: \.self) { item in
                                Annotation(item.restaurant.name, coordinate: item.coordinate) {
                                    NavigationLink(destination: RestaurantProfileView(restaurantId: item.restaurant.id)) {
                                        GroupedPostAnnotationView(groupedPost: item)
                                    }
                                }
                            }
                            ForEach(followingViewModel.clusters) { cluster in
                                Annotation("", coordinate: cluster.coordinate) {
                                    GroupedPostClusterCell(cluster: cluster)
                                        .onTapGesture {
                                            selectedFollowingCluster = cluster
                                        }
                                }
                            }
                        } else {
                            ForEach(viewModel.annotations, id: \.self) { item in
                                Annotation(item.restaurant.name, coordinate: item.coordinate) {
                                    NavigationLink(destination: RestaurantProfileView(restaurantId: item.restaurant.id)) {
                                        RestaurantCircularProfileImageView(imageUrl: item.restaurant.profileImageUrl, color: Color("Colors/AccentColor"), size: .medium)
                                    }
                                }
                            }
                            ForEach(viewModel.clusters) { cluster in
                                Annotation("", coordinate: cluster.coordinate) {
                                    ClusterCell(cluster: cluster)
                                        .onTapGesture {
                                            selectedCluster = cluster
                                        }
                                }
                            }
                            ForEach(viewModel.largeClusters) { cluster in
                                Annotation("", coordinate: cluster.coordinate) {
                                    NewClusterCell(cluster: cluster)
                                        .onTapGesture {
                                            // Handle large cluster tap
                                        }
                                }
                            }
                        }
                        UserAnnotation()
                    }
                    .readSize(onChange: { newValue in
                        viewModel.mapSize = newValue
                        followingViewModel.mapSize = newValue
                    })
                   
                    .onMapCameraChange(frequency: .onEnd) { context in
                        let newRegion = context.region
                        if !showFollowingPosts{
                            viewModel.updateMapState(newRegion: newRegion)
                            Task.detached { await viewModel.reloadAnnotations() }
                        } else {
                            followingViewModel.updateMapState(newRegion: newRegion)
                            Task.detached { await followingViewModel.reloadAnnotations() }
                        }
                    }
                    
                    .onChange(of: isFiltersPresented) {
                        
                        Task.detached { await viewModel.reloadAnnotations() }
                        
                    }
                    .overlay {
                        if showFollowingPosts {
                            if followingViewModel.currentZoomLevel == .maxZoomOut {
                                Text("Zoom in to see posts")
                                    .modifier(OverlayModifier())
                                    .font(.custom("MuseoSansRounded-300", size: 14))
                            } else if noNearbyRestaurants {
                                Text("No posts found nearby")
                                    .modifier(OverlayModifier())
                                    .font(.custom("MuseoSansRounded-300", size: 14))
                            }
                        } else {
                            if viewModel.currentZoomLevel == .maxZoomOut {
                                Text("Zoom in to see restaurants")
                                    .modifier(OverlayModifier())
                                    .font(.custom("MuseoSansRounded-300", size: 14))
                            } else if noNearbyRestaurants {
                                Text("No restaurants found nearby")
                                    .modifier(OverlayModifier())
                                    .font(.custom("MuseoSansRounded-300", size: 14))
                            }
                        }
                    }
                    .overlay(alignment: .bottomTrailing) {
                        userLocationButton
                    }
                    .mapScope(mapScope)
                    
                    .mapStyle(.standard(pointsOfInterest: .excludingAll))
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
            .mapStyle(.standard(elevation: .realistic))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .edgesIgnoringSafeArea(.top)
            
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
    }
    
    private var topRow: some View {
        
        VStack{
            if !inSearchView {
                HStack(alignment: .bottom){
                    Button {
                        inSearchView.toggle()
                    } label: {
                        VStack{
                            
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
                                .fill(.white)
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
                        VStack{
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
                                .fill(.white)
                                .shadow(color: Color.gray, radius: 1)
                        )
                        
                        
                    }
                }
                .padding(.horizontal, 25)
                .padding(.top, 60)
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
        .animation(.spring(), value: inSearchView)
    }
    
    private func handleToggleChange() {
           Task {
//               if showFollowingPosts {
//                   // Switching to Following Posts view
//                   await followingViewModel.fetchFollowingPosts()
//               } else {
//                   // Switching to All Restaurants view
//                   await viewModel.fetchFilteredClusters()
//               }
               // Ensure the map is updated with the new data
               await MainActor.run {
                   if showFollowingPosts {
                       followingViewModel.updateMapState(newRegion: viewModel.currentRegion, shouldAutoFetch: true)
                   } else {
                       viewModel.updateMapState(newRegion: followingViewModel.currentRegion, shouldAutoFetch: true)
                   }
               }
           }
       }
    private func clearSelectedListing() {
        selectedRestaurant = nil
    }
    
    private func fetchRestaurantsInView(center: CLLocationCoordinate2D) async {
        if showFollowingPosts {
            // Use the same logic for fetching posts
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
            // Use the existing fetchRestaurantsInView logic for the regular view
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
    private func calculateDistanceInKilometers(from coordinate1: CLLocationCoordinate2D, to coordinate2: CLLocationCoordinate2D) -> Double {
        let location1 = CLLocation(latitude: coordinate1.latitude, longitude: coordinate1.longitude)
        let location2 = CLLocation(latitude: coordinate2.latitude, longitude: coordinate2.longitude)
        let distanceInMeters = location1.distance(from: location2)
        return distanceInMeters / 1000
    }
}
@available(iOS 17.0, *)
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
            return max(diagonalDistance * 0.15, 0.5)  // 20% of diagonal or at least 1 km
        }
    }
}

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


struct SimplifiedPostClusterListView: View {
    let posts: [SimplifiedPost]
    
    var body: some View {
        NavigationView {
            List(posts) { post in
                NavigationLink(destination: RestaurantProfileView(restaurantId: post.restaurant.id)) {
                    HStack {
                        AsyncImage(url: URL(string: post.thumbnailUrl)) { image in
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
                            Text(post.restaurant.name)
                                .font(.headline)
                            Text(post.user.fullname)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Posts")
        }
    }
}
struct GroupedPostAnnotationView: View {
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
        VStack(spacing: 2) {
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
        }
        .padding(.bottom,5)
    }
}




struct GroupedPostClusterCell: View {
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
                            .font(.custom("MuseoSansRounded-500", size: 10))                        .foregroundColor(showFollowingPosts ? .white : .gray)
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
                .fill(.white)
                .shadow(color: Color.gray, radius: 1)
        )
       

    }
}
struct ClusterCell: View {
    var cluster: ExampleClusterAnnotation
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



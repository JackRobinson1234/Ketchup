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
import Kingfisher
import FirebaseAuth
@available(iOS 17.0, *)
struct MapView: View {
    @ObservedObject var viewModel: MapViewModel = MapViewModel()
    @ObservedObject var followingViewModel = FollowingPostsMapViewModel()
    @State var position: MapCameraPosition
    @State private var inSearchView: Bool = false
    @State private var isFiltersPresented: Bool = false
    @Namespace var mapScope
    @State var center: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 0, longitude: 0)
    @State private var showAlert = false
    @State private var selectedCluster: ExampleClusterAnnotation?
    @State private var selectedLargeCluster: LargeClusterAnnotation?
    @State private var selectedFollowingCluster: GroupedPostClusterAnnotation?
    @State private var hasAppeared = false
    @State private var showFollowingPosts = false
    @State private var isCuisineMenuOpen = false
    @State private var isPriceMenuOpen = false
    @State private var isRatingMenuOpen = false
    @State private var selectedRestaurant: ClusterRestaurant?
    //@State private var previewRestaurants: [ClusterRestaurant] = []
    @State private var selectedRestaurantIndex: Int = 0
    @State private var selectedRestaurantForProfile: ClusterRestaurant?
    @State private var navigateToProfile = false
    //@State private var isMapCenteredOnRestaurant = false
    @State private var currentMapCamera: MapCamera?
//    private var flattenedRestaurants: [ClusterRestaurant] {
//        viewModel.allClusters.flatMap { $0.restaurants }
//    }
    @State private var isUserSelectingRestaurant = false
    @State private var currentRegion: MKCoordinateRegion = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 34.0549, longitude: -118.2426), span: MKCoordinateSpan(latitudeDelta: 0.03, longitudeDelta: 0.03))

    private var noNearbyRestaurants: Bool {
        if showFollowingPosts {
            return followingViewModel.annotations.isEmpty && followingViewModel.clusters.isEmpty && !followingViewModel.isLoading
        } else {
            return viewModel.annotations.isEmpty && viewModel.clusters.isEmpty && viewModel.largeClusters.isEmpty && !viewModel.isLoading
        }
    }
    init() {
        self._position = State(initialValue: .userLocation(fallback: .automatic))
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                VStack(spacing:0){
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
                                    MapRestaurantAnnotationView(
                                        restaurant: item.restaurant,
                                        isSelected: item.restaurant.id == selectedRestaurant?.id
                                    )
                                    .onTapGesture {
                                        isUserSelectingRestaurant = true
                                        selectedRestaurant = item.restaurant
                                        if let index = viewModel.flattenedRestaurants.firstIndex(where: { $0.id == item.restaurant.id }) {
                                            selectedRestaurantIndex = index
                                        }
                                        
                                        // Reset isUserSelectingRestaurant after 2 seconds
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                            isUserSelectingRestaurant = false
                                        }
                                    }
                                    
                                }
                            }
                            ForEach(viewModel.clusters) { cluster in
                                Annotation("", coordinate: cluster.coordinate) {
                                    ClusterCell(cluster: cluster, selectedRestaurantId: selectedRestaurant?.id)
                                        .onTapGesture {
                                            selectedCluster = cluster
                                        }
                                }
                            }
                            
                            ForEach(viewModel.largeClusters) { cluster in
                                Annotation("", coordinate: cluster.coordinate) {
                                    LargeClusterCell(cluster: cluster, selectedRestaurantId: selectedRestaurant?.id)
                                        .onTapGesture {
                                            selectedLargeCluster = cluster
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
                    .onReceive(viewModel.$allClusters) { _ in
                        if !isUserSelectingRestaurant && !viewModel.isLoading && !viewModel.flattenedRestaurants.isEmpty {
                            updateSelectedRestaurant(for: currentRegion)
                        }
                    }
                    .overlay(
                        Group {
                            if isCuisineMenuOpen || isPriceMenuOpen {
                                Color.black.opacity(0.001)
                                    .onTapGesture {
                                        withAnimation {
                                            isCuisineMenuOpen = false
                                            isPriceMenuOpen = false
                                        }
                                    }
                                    .edgesIgnoringSafeArea(.all)
                            }
                        }
                    )
                    .onChange(of: viewModel.selectedCuisines) { _ in
                        Task {
                            await viewModel.fetchFilteredClusters()
                        }
                    }
                    .onChange(of: viewModel.selectedPrice) { _ in
                        Task {
                            await viewModel.fetchFilteredClusters()
                        }
                    }
                    .onChange(of: viewModel.selectedRating) { _ in
                        Task {
                            await viewModel.fetchFilteredClusters()
                        }
                    }
                    .onMapCameraChange(frequency: .onEnd) { context in
                        let newRegion = context.region
                        currentRegion = newRegion
                        currentMapCamera = context.camera
                        
                        if !showFollowingPosts{
                            viewModel.updateMapState(newRegion: newRegion)
                            Task.detached { await viewModel.reloadAnnotations() }
                        } else {
                            followingViewModel.updateMapState(newRegion: newRegion)
                            Task.detached { await followingViewModel.reloadAnnotations() }
                        }
                        
                        // Update selected restaurant if data is ready and user is not interacting
                        if !isUserSelectingRestaurant && !viewModel.isLoading && !viewModel.flattenedRestaurants.isEmpty {
                            updateSelectedRestaurant(for: newRegion)
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
            }
                .frame(maxHeight: .infinity)
                VStack{
                    if !inSearchView{
                        MapTopRow(
                            inSearchView: $inSearchView,
                            showFollowingPosts: $showFollowingPosts,
                            selectedRating: $viewModel.selectedRating,
                            selectedCuisines: $viewModel.selectedCuisines,
                            selectedPrices: $viewModel.selectedPrice,
                            onToggle: handleToggleChange
                        )
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
            NavigationLink(
                destination: RestaurantProfileView(restaurantId: selectedRestaurantForProfile?.id ?? ""),
                isActive: $navigateToProfile
            ) {
                EmptyView()
            }
            .sheet(item: $selectedCluster) { cluster in
                ClusterRestaurantListView(restaurants: cluster.memberAnnotations.map { $0.restaurant })
            }
            .sheet(item: $selectedLargeCluster) { cluster in
                ClusterRestaurantListView(restaurants: cluster.memberAnnotations)
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
            //.clipShape(RoundedRectangle(cornerRadius: 12))
            .edgesIgnoringSafeArea(.top)
            
        }
    }
    

    private func updateSelectedRestaurant(for region: MKCoordinateRegion) {
        if isUserSelectingRestaurant {
            return
        }

        let centerCoordinate = region.center

        // Find the restaurant closest to centerCoordinate
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
            selectedRestaurantIndex = closestIndex
        }
    }
    private func calculateDistance(from coordinate1: CLLocationCoordinate2D, to coordinate2: CLLocationCoordinate2D) -> Double {
            let location1 = CLLocation(latitude: coordinate1.latitude, longitude: coordinate1.longitude)
            let location2 = CLLocation(latitude: coordinate2.latitude, longitude: coordinate2.longitude)
            return location1.distance(from: location2)
        }
    private func navigateToRestaurantProfile(_ restaurant: ClusterRestaurant) {
           selectedRestaurantForProfile = restaurant
           navigateToProfile = true
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
extension MKCoordinateRegion {
    func contains(coordinate: CLLocationCoordinate2D) -> Bool {
        let deltaLat = abs(center.latitude - coordinate.latitude)
        let deltaLon = abs(center.longitude - coordinate.longitude)
        return deltaLat <= span.latitudeDelta / 2 && deltaLon <= span.longitudeDelta / 2
    }
}
enum SheetPosition: CGFloat {
    case half = 0.4   // 40% of the screen height
    case tip = 0.1    // 10% of the screen height (minimized)
}
struct RestaurantSlideUpSheet: View {
    @Binding var restaurants: [ClusterRestaurant]
    @Binding var selectedIndex: Int
    var onDismiss: () -> Void
    var onSelectRestaurant: (ClusterRestaurant) -> Void
    var onRestaurantSwipe: (Int) -> Void

    @State private var currentHeight: CGFloat = 0.0
    @State private var previewOpacity = 0.0

    private var tipHeight: CGFloat {
        60 // Display a minimal part of the sheet in `tip` mode
    }
    private var halfHeight: CGFloat {
        UIScreen.main.bounds.height * 0.3
    }

    @GestureState private var dragOffset = CGFloat.zero
    @State private var currentPosition: SheetPosition = .half

    var body: some View {
        VStack {
            //Spacer()

            VStack(spacing: 0) {
                // Always visible hook
                Capsule()
                    .fill(Color.gray.opacity(0.5))
                    .frame(width: 40, height: 5)
                    .padding(.top, 8)
                    .onTapGesture {
                        togglePosition()
                    }

                if currentPosition == .tip {
                    if restaurants.indices.contains(selectedIndex) {
                        // Minimal content in low mode
                        Text(restaurants[selectedIndex].name)
                            .font(.headline)
                            .padding()
                            .onTapGesture {
                                togglePosition()
                            }
                    } else {
                        // Fallback for invalid index
                        Text("No Restaurant Selected")
                            .font(.headline)
                            .padding()
                            .onTapGesture {
                                togglePosition()
                            }
                    }
                } else {
                    if restaurants.isEmpty {
                        // Handle empty restaurants array
                        Text("No Restaurants Available")
                            .font(.headline)
                            .padding()
                    } else {
                        // Using PagingCollectionView in half mode
                        PagingCollectionView(
                            itemWidth: 240, // Adjusted item width
                            itemSpacing: 10, // Adjusted item spacing
                            itemCount: restaurants.count,
                            currentIndex: $selectedIndex.clamped(to: 0...(restaurants.count > 0 ? restaurants.count - 1 : 0))
                        ) { index in
                            if restaurants.indices.contains(index) {
                                RestaurantPreviewView(userLocation: nil, restaurant: restaurants[index])
                                    .onTapGesture {
                                        onSelectRestaurant(restaurants[index])
                                    }
                            } else {
                                // Fallback for invalid index
                                Text("Invalid Restaurant")
                                    .padding()
                            }
                        }
                        .onChange(of: selectedIndex) { newIndex in
                            if restaurants.indices.contains(newIndex) {
                                onRestaurantSwipe(newIndex)
                            }
                        }
                        .opacity(previewOpacity)
                        .animation(.easeInOut(duration: 0.3), value: previewOpacity)
                    }
                }
            }
            .frame(height: currentHeight)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white)
                    .shadow(radius: 4)
                    .clipShape(
                        RoundedCornerShape(corners: [.topLeft, .topRight], radius: 12)
                    )
            )
            .gesture(
                DragGesture()
                    .onChanged { value in
                        let newHeight = currentHeight - value.translation.height
                        if newHeight >= tipHeight && newHeight <= halfHeight {
                            self.currentHeight = newHeight
                        }
                    }
                    .onEnded { value in
                        let newHeight = currentHeight - value.translation.height
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) {
                            if newHeight > halfHeight * 0.5 {
                                currentPosition = .half
                                currentHeight = halfHeight
                                previewOpacity = 1.0
                            } else {
                                currentPosition = .tip
                                currentHeight = tipHeight
                                previewOpacity = 0.0
                            }
                        }
                    }
            )
            .onAppear {
                // Ensure selectedIndex is valid on appear
                if !restaurants.indices.contains(selectedIndex) {
                    selectedIndex = restaurants.isEmpty ? 0 : 0
                }
                currentHeight = currentPosition == .half ? halfHeight : tipHeight
                previewOpacity = currentPosition != .tip ? 1.0 : 0.0
            }
            .onChange(of: restaurants) { newRestaurants in
                // Adjust selectedIndex if restaurants array changes
                if !newRestaurants.indices.contains(selectedIndex) {
                    selectedIndex = newRestaurants.isEmpty ? 0 : min(selectedIndex, newRestaurants.count - 1)
                }
            }
        }
    }

    private func togglePosition() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) {
            switch currentPosition {
            case .tip:
                if !restaurants.isEmpty {
                    currentPosition = .half
                    currentHeight = halfHeight
                    previewOpacity = 1.0
                }
            case .half:
                currentPosition = .tip
                currentHeight = tipHeight
                previewOpacity = 0.0
            }
        }
    }

    // MARK: - SheetPosition Enum

    enum SheetPosition {
        case tip
        case half
    }
}

struct RoundedCornerShape: Shape {
    var corners: UIRectCorner
    var radius: CGFloat

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

struct MapRestaurantAnnotationView: View {
    let restaurant: ClusterRestaurant
    let isSelected: Bool

    @State private var scale: CGFloat = 1.0

    var body: some View {
        RestaurantCircularProfileImageView(
            imageUrl: restaurant.profileImageUrl,
            color: Color("Colors/AccentColor"),
            size: .medium,
            ratingScore: restaurant.overallRating
        )
        .scaleEffect(scale)
        .onAppear {
            if isSelected {
                bounce()
            }
        }
        .onChange(of: isSelected) { newValue in
            if newValue {
                bounce()
            } else {
                withAnimation {
                    scale = 1.0
                }
            }
        }
    }

    func bounce() {
        scale = 1.0
        withAnimation(Animation.interpolatingSpring(stiffness: 300, damping: 5)) {
            scale = 1.5
        }
        withAnimation(Animation.spring().delay(0.2)) {
            scale = 1.2
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

struct RestaurantPreviewView: View {
    let userLocation: CLLocation?
    let restaurant: ClusterRestaurant

    var body: some View {
        let cardWidth: CGFloat = 240

        VStack(alignment: .leading) {
            ZStack(alignment: .bottomLeading) {
                if let imageUrl = restaurant.profileImageUrl {
                    KFImage(URL(string: imageUrl))
                        .resizable()
                        .scaledToFill()
                        .frame(width: cardWidth, height: 140)
                        .clipped()
                } else {
                    Image("Placeholder")
                        .resizable()
                        .scaledToFill()
                        .frame(width: cardWidth, height: 140)
                        .cornerRadius(8)
                        .clipped()
                }
            }
            HStack(alignment: .top) {
                VStack(alignment: .leading) {
                    Text(restaurant.name)
                        .font(.headline)
                        .foregroundColor(.black)
                        .lineLimit(2)
                    if let city = restaurant.city {
                        Text(city)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .lineLimit(1)
                    }
                    if let cuisine = restaurant.macrocategory, let price = restaurant.price {
                        Text("\(cuisine), \(price)")
                            .font(.footnote)
                            .foregroundColor(.gray)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                    if let distance = distanceString {
                        Text(distance)
                            .font(.caption)
                            .foregroundColor(.gray)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                }
                Spacer()
                if let overallRating = restaurant.overallRating, overallRating != 0 {
                    ScrollFeedOverallRatingView(rating: overallRating, font: .black, size: 30)
                        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 6)
        }
        .frame(width: cardWidth)
        .background(Color.white)
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }

    private var distanceString: String? {
        guard let userLocation = userLocation else {
            return nil
        }
        let restaurantLat = restaurant.geoPoint.latitude
        let restaurantLon = restaurant.geoPoint.longitude
        let restaurantLocation = CLLocation(latitude: restaurantLat, longitude: restaurantLon)
        let distanceInMeters = userLocation.distance(from: restaurantLocation)
        let distanceInMiles = distanceInMeters / 1609.34 // Convert meters to miles

        return String(format: "%.1f mi", distanceInMiles)
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



struct RatingDropDownMenu: View {
    @Binding var selectedRating: Double
    
    let ratingOptions: [Double] = [10.0, 9.0, 8.0, 7.0, 6.0, 5.0]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(ratingOptions, id: \.self) { rating in
                Button(action: {
                    if selectedRating == rating {
                        // Deselect if already selected
                        selectedRating = 0.0
                    } else {
                        // Select new rating
                        selectedRating = rating
                    }
                }) {
                    HStack {
                        Text("Rating \(String(format: "%.1f", rating)) +")
                            .foregroundColor(.black)
                        Spacer()
                        if selectedRating == rating {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(8)
        .shadow(radius: 4)
        .frame(maxHeight: 200)
    }
}
struct MapTopRow: View {
    @Binding var inSearchView: Bool
    @Binding var showFollowingPosts: Bool
    @Binding var selectedRating: Double
    @Binding var selectedCuisines: [String]
    @Binding var selectedPrices: [String]
    var onToggle: () -> Void
    
    @State private var activeDropdown: DropdownMenu?
    
    private enum DropdownMenu {
        case rating
        case cuisine
        case price
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Main button row
            ScrollView(.horizontal, showsIndicators: false){
                HStack(spacing: 12) {
                    // Select Location Button with updated UI
                    FilterButton(
                        title: "Select Location",
                        isActive: false,
                        hasSelection: false,
                        showChevron: false // Hide chevron for this button
                    ) {
                        withAnimation {
                            inSearchView = true
                            activeDropdown = nil
                        }
                    }
                    
                    // Single Toggle Button for Any/Following
                    FollowToggleButton(showFollowingPosts: $showFollowingPosts, onToggle: onToggle)
                    
                    // Filter Buttons Group
                    HStack(spacing: 8) {
                        // Rating Filter
                        FilterButton(
                            title: "Rating",
                            isActive: activeDropdown == .rating,
                            hasSelection: selectedRating > 0,
                            showChevron: true
                        ) {
                            withAnimation {
                                activeDropdown = activeDropdown == .rating ? nil : .rating
                            }
                        }
                        
                        // Cuisine Filter
                        FilterButton(
                            title: "Cuisine",
                            isActive: activeDropdown == .cuisine,
                            hasSelection: !selectedCuisines.isEmpty,
                            showChevron: true
                        ) {
                            withAnimation {
                                activeDropdown = activeDropdown == .cuisine ? nil : .cuisine
                            }
                        }
                        
                        // Price Filter
                        FilterButton(
                            title: "Price",
                            isActive: activeDropdown == .price,
                            hasSelection: !selectedPrices.isEmpty,
                            showChevron: true
                        ) {
                            withAnimation {
                                activeDropdown = activeDropdown == .price ? nil : .price
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 60)
                .zIndex(1)
            }
            
            // Dropdown Menus
            if let activeMenu = activeDropdown {
                VStack {
                    switch activeMenu {
                    case .rating:
                        RatingDropdownContent(selectedRating: $selectedRating)
                    case .cuisine:
                        CuisineDropdownContent(selectedCategories: $selectedCuisines)
                    case .price:
                        PriceDropdownContent(selectedPrices: $selectedPrices)
                    }
                }
                .transition(.move(edge: .top).combined(with: .opacity))
                .zIndex(0)
            }
        }
    }
}

// Supporting Views
struct TopRowButton: View {
    let title: String
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .imageScale(.medium)
                    .foregroundColor(.black)
                
                Text(title)
                    .foregroundColor(.gray)
                    .font(.custom("MuseoSansRounded-500", size: 10))
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }
            .frame(width: 70, height: 50)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.white)
                    .shadow(color: .gray, radius: 1)
            )
        }
    }
}

struct FilterButton: View {
    let title: String
    let isActive: Bool
    let hasSelection: Bool
    let showChevron: Bool // New parameter to control chevron visibility
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Text(title)
                    .foregroundColor(hasSelection ? .black : .gray)
                    .font(.custom("MuseoSansRounded-500", size: 10))
                    .lineLimit(1)
                if showChevron {
                    Image(systemName: isActive ? "chevron.up" : "chevron.down")
                        .foregroundColor(.gray)
                        .font(.caption)
                }
            }
            .frame(width: 70, height: 30)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.white)
                    .shadow(color: .gray, radius: 1)
            )
            .overlay(
                Group {
                    if hasSelection {
                        Circle()
                            .fill(Color("Colors/AccentColor"))
                            .frame(width: 8, height: 8)
                            .offset(x: 30, y: -12)
                    }
                }
            )
        }
    }
}

struct FollowToggleButton: View {
    @Binding var showFollowingPosts: Bool
    var onToggle: () -> Void
    
    var body: some View {
        Button(action: {
            showFollowingPosts.toggle()
            onToggle()
        }) {
            HStack(spacing: 4) {
                
                Text(showFollowingPosts ? "Following" : "Friends have been")
                    .font(.custom("MuseoSansRounded-500", size: 10))
                    .foregroundColor(.black)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
            }
            .padding(.horizontal, 8) // Added padding to accommodate longer text
            .frame(height: 30)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(showFollowingPosts ? Color("Colors/AccentColor") : Color.clear, lineWidth: 2)
                    )
            )
        }
    }
}
struct CustomToggle: View {
    @Binding var showFollowingPosts: Bool
    var onToggle: () -> Void
    
    var body: some View {
        HStack(spacing: 1) {
            ToggleButton(
                icon: "building.2",
                title: "All",
                isSelected: !showFollowingPosts
            ) {
                if showFollowingPosts {
                    showFollowingPosts = false
                    onToggle()
                }
            }
            
            ToggleButton(
                icon: "person.2",
                title: "Friends",
                isSelected: showFollowingPosts
            ) {
                if !showFollowingPosts {
                    showFollowingPosts = true
                    onToggle()
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.white)
                .shadow(color: .gray, radius: 1)
        )
    }
}

struct ToggleButton: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(isSelected ? .white : .black)
                
                Text(title)
                    .font(.custom("MuseoSansRounded-500", size: 10))
                    .foregroundColor(isSelected ? .white : .gray)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
            }
            .frame(width: 50, height: 50)
            .background(isSelected ? Color("Colors/AccentColor") : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .disabled(isSelected)
    }
}

// Dropdown Content Views
struct RatingDropdownContent: View {
    @Binding var selectedRating: Double
    let ratings: [Double] = [10.0, 9.0, 8.0, 7.0, 6.0, 5.0]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(ratings, id: \.self) { rating in
                DropdownRow(
                    title: "Rating \(String(format: "%.1f", rating)) +",
                    isSelected: selectedRating == rating
                ) {
                    selectedRating = selectedRating == rating ? 0 : rating
                }
            }
        }
        .dropdownStyle()
    }
}

struct CuisineDropdownContent: View {
    @Binding var selectedCategories: [String]
    let maxSelection = 5
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 4) {
                ForEach(Cuisines.all, id: \.self) { cuisine in
                    DropdownRow(
                        title: cuisine,
                        isSelected: selectedCategories.contains(cuisine)
                    ) {
                        if selectedCategories.contains(cuisine) {
                            selectedCategories.removeAll { $0 == cuisine }
                        } else if selectedCategories.count < maxSelection {
                            selectedCategories.append(cuisine)
                        }
                    }
                }
            }
        }
        .frame(maxHeight: 200)
        .dropdownStyle()
    }
}

struct PriceDropdownContent: View {
    @Binding var selectedPrices: [String]
    let prices = ["$", "$$", "$$$", "$$$$"]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(prices, id: \.self) { price in
                DropdownRow(
                    title: price,
                    isSelected: selectedPrices.contains(price)
                ) {
                    if selectedPrices.contains(price) {
                        selectedPrices.removeAll { $0 == price }
                    } else {
                        selectedPrices.append(price)
                    }
                }
            }
        }
        .dropdownStyle()
    }
}

struct DropdownRow: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .foregroundColor(.black)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    }
}

// Styling
struct DropdownStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(.vertical)
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: .gray.opacity(0.2), radius: 4)
            .padding(.horizontal)
    }
}

extension View {
    func dropdownStyle() -> some View {
        modifier(DropdownStyle())
    }
}

// Constants
enum Cuisines {
    static let all = [
        "Italian", "Chinese", "Japanese", "Korean", "Other Asian",
        "Mexican", "American", "French", "Spanish", "Greek",
        "Middle Eastern", "German", "Caribbean", "African",
        "South American", "Central American", "Eastern European",
        "Seafood", "Vegetarian and Vegan", "Fusion and International",
        "Fast Food and Casual", "Breakfast and Brunch",
        "Barbecue and Grill", "Noodles", "Specialty and Dietary",
        "Cafes and Bakeries", "Bars and Pubs", "Desserts and Sweets",
        "Street Food and Food Trucks", "Buffet and All-You-Can-Eat",
        "Markets and Specialty Shops", "European", "Vietnamese", "Indian"
    ]
}

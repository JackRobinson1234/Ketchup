//
//  ActivityView.swift
//  Foodi
//
//  Created by Jack Robinson on 4/19/24.
//

import SwiftUI
import FirebaseAuth
import GeoFire
import Firebase
enum LetsKetchupOptions {
    case friends, trending
}
struct ActivityView: View {
    @StateObject private var viewModel = ActivityViewModel()
    @StateObject private var leaderboardViewModel = LeaderboardViewModel()
    @State private var isLoading = true
    @State private var showContacts = false
    @State private var shouldShowExistingUsersOnContacts = false
    @State private var showLocationSearch = false
    @State private var city: String?
    @State private var surroundingGeohash: String?
    @State private var state: String?
    @State private var surroundingCounty: String = "Nearby"
    @State private var selectedTab: Tab = .discover
    @State private var leaderboardData: [LeaderboardCategory: [LocationType: Any]] = [:]
    @State private var selectedLeaderboard: (category: LeaderboardCategory?, location: LocationType?)?
    @State private var showPollUploadView = false
    
    enum Tab {
        case discover
        case leaderboards
    }
    
    enum LeaderboardCategory: String, CaseIterable, Identifiable {
        case mostPosts = "Most Posted"
        case mostLikes = "Posts - Most Likes"
        case highestOverallRated = "Best Overall"
        case highestFoodRated = "Best Food"
        case highestAtmosphereRated = "Best Atmosphere"
        case highestValueRated = "Best Value"
        case highestServiceRated = "Best Service"
        
        var id: String { self.rawValue }
    }
    
    enum LocationType: String, CaseIterable, Identifiable {
        case city = "City"
        case surrounding = "Surrounding"
        case usa = "USA"
        
        var id: String { self.rawValue }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    tabButtons
                    
                    
                    if let userId = AuthService.shared.userSession?.id,
                       ["uydfmAuFmCWOvSuLaGYuSKQO8Qn2", "cQlKGlOWTOSeZcsqObd4Iuy6jr93", "4lwAIMZ8zqgoIljiNQmqANMpjrk2"].contains(userId) {
                        Button{
                            showPollUploadView = true
                        } label:{
                            HStack{
                                Spacer()
                                Text("Poll Manager")
                                    .font(.custom("MuseoSansRounded-300", size: 12))
                                    .modifier(StandardButtonModifier(width: 80))
                                Spacer()
                            }
                        }
                        
                    }
                    PollView()
                    if isLoading {
                        FastCrossfadeFoodImageView()
                    } else {
                        if selectedTab == .discover {
                            discoverContent
                        } else {
                            leaderboardsContent
                        }
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack {
                        toolbarLogoView
                        Spacer()
                        locationButton
                    }
                }
            }
            .refreshable { await refreshData() }
            .fullScreenCover(item: Binding(
                get: { selectedLeaderboard?.category },
                set: { newValue in
                    if let newValue = newValue {
                        selectedLeaderboard?.category = newValue
                    } else {
                        selectedLeaderboard = nil
                    }
                }
            )) { category in
                leaderboardView(for: category)
            }
            .sheet(isPresented: $showLocationSearch) {
                LocationSearchView(
                    city: $city,
                    state: $state,
                    surroundingGeohash: $surroundingGeohash,
                    surroundingCounty: $surroundingCounty,
                    onLocationSelected: {
                        Task {
                            await refreshLocationData()
                        }
                    }
                )
                .presentationDetents([.height(UIScreen.main.bounds.height * 0.5)])
            }
            .sheet(isPresented: $showContacts) {
                ContactsView(shouldFetchExistingUsers: shouldShowExistingUsersOnContacts)
            }
            .sheet(isPresented: $showPollUploadView){
                PollUploadView()
            }
        }
        .onAppear {
            loadInitialLocation()
            Task {
                await loadInitialData()
            }
        }
    }
    
    private var tabButtons: some View {
        HStack {
            actionButton(title: "Discover", icon: "globe", isSelected: selectedTab == .discover) {
                selectedTab = .discover
            }
            actionButton(title: "Top Rated Restaurants", icon: "trophy", isSelected: selectedTab == .leaderboards) {
                selectedTab = .leaderboards
            }
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }
    
    private func actionButton(title: String, icon: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                Text(title)
                    .font(.custom("MuseoSansRounded-500", size: 12))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .foregroundColor(isSelected ? Color("Colors/AccentColor") : .black)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isSelected ? Color("Colors/AccentColor") : Color.gray.opacity(0.5), lineWidth: 1)
            )
            .cornerRadius(20)
        }
    }
    
    private var discoverContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            if let user = viewModel.user, user.contactsSynced, viewModel.isContactPermissionGranted {
                contactsSection
            }
            
            inviteContactsButton
            RestaurantLeaderboardsView(
                viewModel: leaderboardViewModel,
                leaderboardData: $leaderboardData,
                selectedLeaderboard: $selectedLeaderboard,
                
                city: city,
                state: state,
                surroundingGeohash: surroundingGeohash,
                surroundingCounty: surroundingCounty
            )
            mostLikedPostsSection
            
        }
    }
    
    private var leaderboardsContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            RestaurantLeaderboardsView(
                viewModel: leaderboardViewModel,
                leaderboardData: $leaderboardData,
                selectedLeaderboard: $selectedLeaderboard,
                
                city: city,
                state: state,
                surroundingGeohash: surroundingGeohash,
                surroundingCounty: surroundingCounty
            )
            mostLikedPostsSection
        }
    }
    
    private var toolbarLogoView: some View {
        Image("KetchupTextRed")
            .resizable()
            .scaledToFit()
            .frame(width: 100)
    }
    
    private var locationButton: some View {
        Button(action: {
            showLocationSearch = true
        }) {
            HStack(spacing: 1) {
                Image(systemName: "location")
                    .foregroundStyle(.gray)
                    .font(.caption)
                Text(city != nil && state != nil ? "\(city!), \(state!)" : "Set Location")
                    .font(.custom("MuseoSansRounded-500", size: 16))
                    .foregroundStyle(.gray)
                Image(systemName: "chevron.down")
                    .foregroundStyle(.gray)
                    .font(.caption)
            }
            .lineLimit(2)
            .minimumScaleFactor(0.5)
        }
    }
    
    private var mostLikedPostsSection: some View {
        VStack(alignment: .leading) {
            Text("Most Liked Posts")
                .font(.custom("MuseoSansRounded-700", size: 25))
                .foregroundColor(.black)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(LocationType.allCases) { locationType in
                        if let data = leaderboardData[.mostLikes]?[locationType] {
                            leaderboardButton(for: .mostLikes, locationType: locationType, data: data)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    private var contactsSection: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("Friends on Ketchup")
                    .font(.custom("MuseoSansRounded-700", size: 25))
                    .foregroundColor(.black)
                Spacer()
                Button("See All") {
                    shouldShowExistingUsersOnContacts = true
                    showContacts = true
                }
                .font(.custom("MuseoSansRounded-300", size: 12))
                .foregroundStyle(.gray)
            }
            .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 16) {
                    ForEach(viewModel.topContacts) { contact in
                        ActivityContactRow(viewModel: viewModel, contact: contact)
                            .onAppear {
                                if contact == viewModel.topContacts.last {
                                    viewModel.loadMoreContacts()
                                }
                            }
                    }
                    if viewModel.isLoadingMore {
                        FastCrossfadeFoodImageView()
                            .frame(width: 50, height: 50)
                    }
                    if viewModel.hasMoreContacts {
                        Color.clear
                            .frame(width: 1, height: 1)
                            .onAppear { viewModel.loadMoreContacts() }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    private var inviteContactsButton: some View {
        Button {
            shouldShowExistingUsersOnContacts = false
            showContacts = true
        } label: {
            VStack{
                Divider()
                HStack {
                    Image(systemName: "envelope")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 30)
                        .foregroundStyle(.black)
                    Text("Invite your friends to Ketchup!")
                        .font(.custom("MuseoSansRounded-700", size: 16))
                        .foregroundStyle(.black)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundStyle(.gray)
                }
                .padding()
                Divider()
            }
        }
    }
    
    private func leaderboardButton(for category: LeaderboardCategory, locationType: LocationType, data: Any) -> some View {
        Button {
            selectedLeaderboard = (category: category, location: locationType)
        } label: {
            LeaderboardCover(
                imageUrl: (data as? [Post])?.first?.thumbnailUrl,
                title: "Most Liked Posts",
                subtitle: subtitleForLeaderboard(locationType: locationType)
            )
        }
    }
    
    private func subtitleForLeaderboard(locationType: LocationType) -> String {
        switch locationType {
        case .city:
            return city ?? "City"
        case .surrounding:
            return surroundingCounty
        case .usa:
            return "USA"
        }
    }
    
    private func leaderboardView(for category: LeaderboardCategory) -> some View {
        Group {
            if category == .mostLikes {
                PostLeaderboard(
                    viewModel: leaderboardViewModel,
                    topImage: (leaderboardData[category]?[.usa] as? [Post])?.first?.thumbnailUrl,
                    title: category.rawValue,
                    state: state,
                    city: city,
                    surrounding: surroundingGeohash
                )
            } else {
                if let location = selectedLeaderboard?.location{
                    RestaurantLeaderboard(
                        viewModel: leaderboardViewModel,
                        topImage: (leaderboardData[category]?[location] as? [Restaurant])?.first?.profileImageUrl,
                        title: subtitleForLeaderboard(locationType: location),
                        state: state,
                        city: city,
                        surrounding: surroundingGeohash,
                        leaderboardType: leaderboardTypeFor(category),
                        selectedLocation: location
                        
                    )
                }
            }
        }
    }
    
    private func leaderboardTypeFor(_ category: LeaderboardCategory) -> RestaurantLeaderboard.RestaurantLeaderboardType {
        switch category {
        case .mostPosts:
            return .mostPosts
        case .highestOverallRated:
            return .highestRated(.overall)
        case .highestFoodRated:
            return .highestRated(.food)
        case .highestAtmosphereRated:
            return .highestRated(.atmosphere)
        case .highestValueRated:
            return .highestRated(.value)
        case .highestServiceRated:
            return .highestRated(.service)
        case .mostLikes:
            fatalError("Unexpected category for RestaurantLeaderboard")
        }
    }
    
    private func loadInitialLocation() {
        city = AuthService.shared.userSession?.location?.city
        if let geoPoint = AuthService.shared.userSession?.location?.geoPoint {
            surroundingGeohash = GFUtils.geoHash(forLocation: CLLocationCoordinate2D(latitude: geoPoint.latitude, longitude: geoPoint.longitude))
            reverseGeocodeLocation(latitude: geoPoint.latitude, longitude: geoPoint.longitude)
        }
        state = AuthService.shared.userSession?.location?.state
    }
    
    private func loadInitialData() async {
        viewModel.user = AuthService.shared.userSession
        viewModel.checkContactPermission()
        
        for category in LeaderboardCategory.allCases {
            for locationType in LocationType.allCases {
                await fetchLeaderboardData(for: category, locationType: locationType)
            }
        }
        
        do {
            try await viewModel.fetchTopContacts()
        } catch {
            print("Error fetching top contacts: \(error)")
        }
        
        isLoading = false
    }
    
    private func refreshData() async {
        for category in LeaderboardCategory.allCases {
            for locationType in LocationType.allCases {
                await fetchLeaderboardData(for: category, locationType: locationType)
            }
        }
        
        do {
            try await viewModel.fetchTopContacts()
        } catch {
            print("Error refreshing top contacts: \(error)")
        }
    }
    
    private func refreshLocationData() async {
        await refreshData()
    }
    
    private func fetchLeaderboardData(for category: LeaderboardCategory, locationType: LocationType) async {
        do {
            let locationFilter: LeaderboardViewModel.LocationFilter
            switch locationType {
            case .usa:
                locationFilter = .anywhere
            case .city:
                locationFilter = .city(city ?? "")
            case .surrounding:
                locationFilter = .geohash(surroundingGeohash ?? "")
            }
            
            let data: Any
            switch category {
            case .mostPosts:
                data = try await leaderboardViewModel.fetchTopRestaurants(count: 1, locationFilter: locationFilter)
            case .mostLikes:
                data = try await leaderboardViewModel.fetchTopPosts(count: 1)
            case .highestOverallRated:
                data = try await leaderboardViewModel.fetchHighestRatedRestaurants(category: .overall, count: 1, locationFilter: locationFilter)
            case .highestFoodRated:
                data = try await leaderboardViewModel.fetchHighestRatedRestaurants(category: .food, count: 1, locationFilter: locationFilter)
            case .highestAtmosphereRated:
                data = try await leaderboardViewModel.fetchHighestRatedRestaurants(category: .atmosphere, count: 1, locationFilter: locationFilter)
            case .highestValueRated:
                data = try await leaderboardViewModel.fetchHighestRatedRestaurants(category: .value, count: 1, locationFilter: locationFilter)
            case .highestServiceRated:
                data = try await leaderboardViewModel.fetchHighestRatedRestaurants(category: .service, count: 1, locationFilter: locationFilter)
            }
            
            if (data as? [Any])?.isEmpty == false {
                if leaderboardData[category] == nil {
                    leaderboardData[category] = [:]
                }
                leaderboardData[category]?[locationType] = data
            }
        } catch {
            print("Error fetching data for \(category) - \(locationType): \(error.localizedDescription)")
        }
    }
    
    private func reverseGeocodeLocation(latitude: Double, longitude: Double) {
        let location = CLLocation(latitude: latitude, longitude: longitude)
        let geocoder = CLGeocoder()
        
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            if let error = error {
                print("Reverse geocoding error: \(error.localizedDescription)")
                return
            }
            
            if let placemark = placemarks?.first, let county = placemark.subAdministrativeArea {
                DispatchQueue.main.async {
                    self.surroundingCounty = county
                }
            } else {
                print("County information not available")
            }
        }
    }
}

enum LeaderboardType: Identifiable {
    case usa
    case state(String)
    case city(String)
    case surrounding(String)
    
    var id: String {
        switch self {
        case .usa: return "usa"
        case .state(let state): return "state_\(state)"
        case .city(let city): return "city_\(city)"
        case .surrounding(let surrounding): return "surrounding"
        }
    }
}

enum RestaurantLeaderboardType: Identifiable {
    case usa
    case state
    case city
    case surrounding
    
    var id: String {
        switch self {
        case .usa: return "usa"
        case .state: return "state"
        case .city: return "city"
        case .surrounding: return "surrounding"
        }
    }
}


struct InviteContactsButton: View {
    var body: some View {
        VStack {
            Divider()
            HStack {
                Image(systemName: "envelope")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 30)
                    .foregroundStyle(.black)
                Text("Invite your friends to Beta!")
                    .font(.custom("MuseoSansRounded-700", size: 16))
                    .foregroundStyle(.black)
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(.gray)
                    .padding(.horizontal)
            }
            .padding(.horizontal)
            .padding(.vertical)
            Divider()
        }
    }
}

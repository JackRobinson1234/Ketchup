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
import Kingfisher

struct ActivityView: View {
    @StateObject private var viewModel = ActivityViewModel()
    @State private var isLoading = true
    @State private var showContacts = false
    @State private var shouldShowExistingUsersOnContacts = false
    @State private var showLocationSearch = false
    @State private var city: String?
    @State private var surroundingGeohash: String?
    @State private var state: String?
    @State private var surroundingCounty: String = "Nearby"
    @State private var selectedTab: Tab = .discover
    @State private var showPollUploadView = false
    @StateObject private var pollViewModel = PollViewModel()
    @State private var currentTabHeight: CGFloat = 650
    @State private var selectedPollIndex: Int = 0
    @StateObject var feedViewModel = FeedViewModel()
    @State private var greetingType: GreetingType = .morning
    @State private var greeting: String = ""
    @StateObject private var locationManager = LocationManager()
    @State private var selectedCuisine: String?
    @State private var mealTime: MealTime = .breakfast

    enum Tab {
        case dailyPoll
        case discover
        case friends
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        Color.clear
                            .frame(height: 100) // Adjust this value based on the combined height of your header and tab buttons
                        contentBasedOnSelectedTab
                    }
                }
                
                VStack(spacing: 0) {
                    customHeader
                        .background(Color.white)
                        .zIndex(2)
                    
                    tabButtons
                        .padding(.bottom, 6)
                        .background(Color.white)
                        .zIndex(1)
                        .padding(.bottom, 10)
                }
            }
            .navigationBarHidden(true)
            .refreshable { await refreshData() }
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
            .sheet(isPresented: $showPollUploadView) {
                PollUploadView()
            }
        }
        .onAppear {
                       loadInitialLocation()
                       computeGreeting()
                       if let location = locationManager.userLocation?.coordinate {
                           Task {
                               do {
                                   try await viewModel.fetchMealRestaurants(mealTime: greetingType.mealTime, location: location)
                                   if let cuisine = selectedCuisine {
                                       try await viewModel.fetchCuisineRestaurants(cuisine: cuisine, location: location)
                                   }
                               } catch {
                                   print("Error fetching meal or cuisine restaurants: \(error)")
                               }
                           }
                       } else {
                           // Request location if not available
                           locationManager.requestLocation { success in
                               if success, let location = locationManager.userLocation?.coordinate {
                                   Task {
                                       do {
                                           try await viewModel.fetchMealRestaurants(mealTime: greetingType.mealTime, location: location)
                                           if let cuisine = selectedCuisine {
                                               try await viewModel.fetchCuisineRestaurants(cuisine: cuisine, location: location)
                                           }
                                       } catch {
                                           print("Error fetching meal or cuisine restaurants: \(error)")
                                       }
                                   }
                               } else {
                                   print("User location not available.")
                               }
                           }
                       }
                   }
                

    }

    private var contentBasedOnSelectedTab: some View {
        Group {
            if selectedTab == .dailyPoll {
                dailyPollContent
            } else if selectedTab == .discover {
                discoverContent
            } else if selectedTab == .friends {
                friendsContent
            }
        }
    }

    private var tabButtons: some View {
        VStack {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    actionButton(title: "Discover", icon: "globe", isSelected: selectedTab == .discover) {
                        selectedTab = .discover
                    }
                    actionButton(title: "Daily Poll", icon: "list.bullet.clipboard", isSelected: selectedTab == .dailyPoll) {
                        selectedTab = .dailyPoll
                    }
                    actionButton(title: "Find Friends", icon: "person.2", isSelected: selectedTab == .friends) {
                        selectedTab = .friends
                    }
                }
                .padding(.horizontal)
            }
        }
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
            NavigationStack {
                VStack(alignment: .leading, spacing: 25) {
                    inviteContactsButton
                    if let user = AuthService.shared.userSession {
                        Text("\(greeting), \(user.fullname)!")
                            .font(.custom("MuseoSansRounded-700", size: 25))
                            .padding(.horizontal)
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
                    }
                    if !viewModel.mealRestaurants.isEmpty {
                        Text("Popular \(greetingType.mealTime.capitalized) Near You")
                            .font(.custom("MuseoSansRounded-700", size: 25))
                            .padding(.horizontal)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                ForEach(viewModel.mealRestaurants.indices, id: \.self) { index in
                                    let restaurant = viewModel.mealRestaurants[index]
                                    NavigationLink(destination: RestaurantProfileView(restaurantId: restaurant.id)) {
                                        RestaurantCardView(userLocation: locationManager.userLocation, restaurant: restaurant)
                                    }
                                    .onAppear {
                                        if index == viewModel.mealRestaurants.count - 1 && viewModel.hasMoreMealRestaurants {
                                            Task {
                                                await viewModel.fetchMoreMealRestaurants()
                                            }
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                        
                    }

                    // New Section for Random Cuisine
                    if let cuisine = selectedCuisine, !viewModel.cuisineRestaurants.isEmpty {
                        Text("Best \(cuisine) Near You")
                            .font(.custom("MuseoSansRounded-700", size: 25))
                            .padding(.horizontal)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                ForEach(viewModel.cuisineRestaurants.indices, id: \.self) { index in
                                    let restaurant = viewModel.cuisineRestaurants[index]
                                    NavigationLink(destination: RestaurantProfileView(restaurantId: restaurant.id)) {
                                        RestaurantCardView(userLocation: locationManager.userLocation, restaurant: restaurant)
                                    }
                                    .onAppear {
                                        if index == viewModel.cuisineRestaurants.count - 1 && viewModel.hasMoreCuisineRestaurants {
                                            Task {
                                                await viewModel.fetchMoreCuisineRestaurants()
                                            }
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
              
                dailyPollContent
                Divider()
                contactsSection
                Divider()
            }
        }

    struct RestaurantCardView: View {
        
           let userLocation: CLLocation?
        let restaurant: Restaurant

        var body: some View {
            VStack(alignment: .leading) {
                if let imageUrl = restaurant.profileImageUrl {
                    KFImage(URL(string: imageUrl))
                        .resizable()
                        .scaledToFill()
                        .frame(width: 150, height: 120)
                        .cornerRadius(8)
                        .clipped()
                } else {
                    Image("placeholderImage")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 120, height: 100)
                        .cornerRadius(8)
                        .clipped()
                }
                Text(restaurant.name)
                    .font(.custom("MuseoSansRounded-700", size: 14))
                    .foregroundColor(.black)
                    .lineLimit(1)
                    .frame(width: 120, alignment: .leading)
                if let city = restaurant.city {
                    Text(city)
                        .font(.custom("MuseoSansRounded-300", size: 12))
                        .foregroundColor(.gray)
                        .lineLimit(1)
                }
                if let cuisine = restaurant.categoryName, let price = restaurant.price {
                    Text("\(cuisine), \(price)")
                        .font(.custom("MuseoSansRounded-300", size: 10))
                        .foregroundColor(.gray)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                } else if let cuisine = restaurant.categoryName {
                    Text(cuisine)
                        .font(.custom("MuseoSansRounded-300", size: 10))
                        .foregroundColor(.gray)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                } else if let price = restaurant.price {
                    Text(price)
                        .font(.custom("MuseoSansRounded-300", size: 10))
                        .foregroundColor(.gray)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                if let count = restaurant.stats?.postCount {
                    Text("\(count) posts")
                        .font(.custom("MuseoSansRounded-300", size: 10))
                        .foregroundColor(.gray)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                if let distance = distanceString {
                                Text(distance)
                                    .font(.custom("MuseoSansRounded-300", size: 10))
                                    .foregroundColor(.gray)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.7)
                            }
                
            }
            .frame(width: 150)
        }
        private var distanceString: String? {
                guard let userLocation = userLocation,
                      let restaurantLat = restaurant.geoPoint?.latitude,
                      let restaurantLon = restaurant.geoPoint?.longitude else {
                    return nil
                }
                let restaurantLocation = CLLocation(latitude: restaurantLat, longitude: restaurantLon)
                let distanceInMeters = userLocation.distance(from: restaurantLocation)
                let distanceInMiles = distanceInMeters / 1609.34 // Convert meters to miles

                return String(format: "%.1f mi", distanceInMiles)
            }
    }

    private var customHeader: some View {
        HStack {
            toolbarLogoView
            Spacer()
            locationButton
        }
        .padding()
    }

    private var friendsContent: some View {
        VStack {
            inviteContactsButton
            contactsSection
        }
    }

    private var toolbarLogoView: some View {
        Image("KetchupTextRed")
            .resizable()
            .scaledToFit()
            .frame(width: 100)
    }

    private func computeGreeting() {
            let hour = Calendar.current.component(.hour, from: Date())
            let greetingType: GreetingType
            let greeting: String
            switch hour {
            case 5..<12:
                greetingType = .morning
                greeting = "Good morning"
                mealTime = .breakfast
            case 12..<17:
                greetingType = .afternoon
                greeting = "Good afternoon"
                mealTime = .lunch
            default:
                greetingType = .evening
                greeting = "Good evening"
                mealTime = .dinner
            }
            self.greetingType = greetingType
            self.greeting = greeting

            // Select a random cuisine based on the current meal time
            if let cuisines = mealTimeCuisineMap[mealTime], !cuisines.isEmpty {
                selectedCuisine = cuisines.randomElement()
            } else {
                selectedCuisine = nil
            }
        }

    private var locationButton: some View {
        Button(action: {
            showLocationSearch = true
        }) {
            HStack(spacing: 1) {
                Image(systemName: "location")
                    .foregroundColor(.gray)
                    .font(.caption)
                Text(city != nil && state != nil ? "\(city!), \(state!)" : "Set Location")
                    .font(.custom("MuseoSansRounded-500", size: 16))
                    .foregroundColor(.gray)
                Image(systemName: "chevron.down")
                    .foregroundColor(.gray)
                    .font(.caption)
            }
            .lineLimit(2)
            .minimumScaleFactor(0.5)
        }
    }

    private var dailyPollContent: some View {
        VStack(alignment: .leading) {
            HStack {
                VStack(alignment: .leading) {
                    HStack {
                        Text("Daily Poll")
                            .font(.custom("MuseoSansRounded-700", size: 25))
                            .foregroundColor(.black)
                        
                        if !hasUserVotedToday() {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 8, height: 8)
                        }
                    }
                    .padding(.horizontal)
                    
                    HStack(spacing: 2) {
                        Text("🔥\(AuthService.shared.userSession?.pollStreak ?? 0) day streak")
                            .font(.custom("MuseoSansRounded-500", size: 14))
                            .foregroundColor(.black)
                    }
                    .padding(.horizontal)
                }
                Spacer()
                if let userId = AuthService.shared.userSession?.id,
                   ["uydfmAuFmCWOvSuLaGYuSKQO8Qn2", "cQlKGlOWTOSeZcsqObd4Iuy6jr93", "4lwAIMZ8zqgoIljiNQmqANMpjrk2"].contains(userId) {
                    Button {
                        showPollUploadView = true
                    } label: {
                        Text("Poll Manager")
                            .font(.custom("MuseoSansRounded-300", size: 12))
                            .modifier(StandardButtonModifier(width: 80))
                            .padding(.trailing)
                    }
                }
            }
            
            if !pollViewModel.polls.isEmpty {
                VStack(spacing: 10) {
                    TabView(selection: $selectedPollIndex) {
                        ForEach(pollViewModel.polls.indices, id: \.self) { index in
                            PollView(poll: $pollViewModel.polls[index], pollViewModel: pollViewModel, feedViewModel: feedViewModel)
                                .background(
                                    GeometryReader { geometry in
                                        Color.clear
                                            .onAppear {
                                                if index == selectedPollIndex {
                                                    withAnimation(.easeInOut(duration: 0.3)) {
                                                        currentTabHeight = geometry.size.height + 15
                                                    }
                                                }
                                            }
                                            .onChange(of: selectedPollIndex) { _ in
                                                if index == selectedPollIndex {
                                                    withAnimation(.easeInOut(duration: 0.3)) {
                                                        currentTabHeight = geometry.size.height + 15
                                                    }
                                                }
                                            }
                                    }
                                )
                                .tag(index)
                        }
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                    .frame(height: currentTabHeight)
                    Text("Swipe to see previous polls")
                        .font(.custom("MuseoSansRounded-300", size: 10))
                        .foregroundColor(.gray.opacity(0.8))
                        .padding(.bottom, 5)
                }
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
                .foregroundColor(.gray)
            }
            .padding(.horizontal)
            if let user = viewModel.user, user.contactsSynced, viewModel.isContactPermissionGranted {
                if !viewModel.topContacts.isEmpty {
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
                } else {
                    Button {
                        shouldShowExistingUsersOnContacts = false
                        showContacts = true
                    } label: {
                        Text("We couldn't find any friends in your contacts, invite them!")
                            .foregroundColor(.black)
                            .font(.custom("MuseoSansRounded-700", size: 14))
                    }
                }
            } else {
                Button {
                    openSettings()
                } label: {
                    HStack {
                        Spacer()
                        VStack {
                            Text("Allow Ketchup to access your contacts to make finding friends easier!")
                                .foregroundColor(.black)
                                .font(.custom("MuseoSansRounded-500", size: 14))
                                .padding(.vertical)
                            Text("Go to settings")
                                .foregroundColor(Color("Colors/AccentColor"))
                                .font(.custom("MuseoSansRounded-700", size: 14))
                        }
                        Spacer()
                    }
                    .padding(.horizontal)
                }
            }
        }
    }

    private var inviteContactsButton: some View {
        VStack(spacing: 0) {
            Button {
                shouldShowExistingUsersOnContacts = false
                showContacts = true
            } label: {
                VStack {
                    Divider()
                    HStack {
                        Image(systemName: "envelope")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 30)
                            .foregroundColor(.black)
                        VStack(alignment: .leading) {
                            Text("Invite your friends to Ketchup!")
                                .font(.custom("MuseoSansRounded-700", size: 16))
                            VStack(alignment: .leading, spacing: 3) {
                                GeometryReader { geometry in
                                    ZStack(alignment: .leading) {
                                        Rectangle()
                                            .fill(Color.gray.opacity(0.3))
                                            .frame(height: 4)
                                            .cornerRadius(4)
                                        Rectangle()
                                            .fill(Color("Colors/AccentColor"))
                                            .frame(width: min(CGFloat(min(AuthService.shared.userSession?.totalReferrals ?? 0, 10)) / 10.0 * geometry.size.width, geometry.size.width), height: 4)
                                            .cornerRadius(4)
                                    }
                                }
                                .frame(height: 8)
                                HStack(spacing: 1) {
                                    Text("You have \(min(AuthService.shared.userSession?.totalReferrals ?? 0, 10))/10 referrals to earn the launch badge")
                                        .font(.custom("MuseoSansRounded-500", size: 10))
                                        .foregroundColor(.gray)
                                    if let totalReferrals = AuthService.shared.userSession?.totalReferrals, totalReferrals >= 10 {
                                        Image("LAUNCH")
                                    } else {
                                        Image("LAUNCHBLACK")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(height: 12)
                                            .opacity(0.5)
                                    }
                                }
                            }
                        }
                        .foregroundColor(.black)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.gray)
                    }
                    .padding()
                    Divider()
                }
            }
        }
    }

    private func hasUserVotedToday() -> Bool {
        guard let lastVotedDate = AuthService.shared.userSession?.lastVotedPoll else {
            return false // User has never voted
        }
        
        let calendar = Calendar.current
        let losAngelesTimeZone = TimeZone(identifier: "America/Los_Angeles")!
        
        let lastVotedDateLA = calendar.date(byAdding: .hour, value: losAngelesTimeZone.secondsFromGMT() / 3600, to: lastVotedDate)!
        let nowLA = calendar.date(byAdding: .hour, value: losAngelesTimeZone.secondsFromGMT() / 3600, to: Date())!
        
        let lastVotedDay = calendar.startOfDay(for: lastVotedDateLA)
        let todayLA = calendar.startOfDay(for: nowLA)
        
        return calendar.isDate(lastVotedDay, inSameDayAs: todayLA)
    }

    private func openSettings() {
        if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsURL, options: [:], completionHandler: nil)
        }
    }

    private func loadInitialLocation() {
        if let userLocation = locationManager.userLocation {
            // Use the current location
            let latitude = userLocation.coordinate.latitude
            let longitude = userLocation.coordinate.longitude
            surroundingGeohash = GFUtils.geoHash(forLocation: CLLocationCoordinate2D(latitude: latitude, longitude: longitude))
            reverseGeocodeLocation(latitude: latitude, longitude: longitude)
        } else if let geoPoint = AuthService.shared.userSession?.location?.geoPoint {
            // Use the user's selected location
            let latitude = geoPoint.latitude
            let longitude = geoPoint.longitude
            surroundingGeohash = GFUtils.geoHash(forLocation: CLLocationCoordinate2D(latitude: latitude, longitude: longitude))
            reverseGeocodeLocation(latitude: latitude, longitude: longitude)
            city = AuthService.shared.userSession?.location?.city
            state = AuthService.shared.userSession?.location?.state
        } else {
            // No location available
            city = nil
            state = nil
            surroundingGeohash = nil
            // Optionally request location
            locationManager.requestLocation { success in
                if success, let userLocation = locationManager.userLocation {
                    let latitude = userLocation.coordinate.latitude
                    let longitude = userLocation.coordinate.longitude
                    surroundingGeohash = GFUtils.geoHash(forLocation: CLLocationCoordinate2D(latitude: latitude, longitude: longitude))
                    reverseGeocodeLocation(latitude: latitude, longitude: longitude)
                } else {
                    print("User location not available.")
                }
            }
        }
    }

    private func refreshData() async {
        pollViewModel.fetchPolls()
        do {
            try await viewModel.fetchTopContacts()
        } catch {
            // Handle error
        }
    }

    private func refreshLocationData() async {
        await refreshData()
    }

    private func reverseGeocodeLocation(latitude: Double, longitude: Double) {
        let location = CLLocation(latitude: latitude, longitude: longitude)
        let geocoder = CLGeocoder()
        
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            if let error = error {
                // Handle error
                return
            }
            if let placemark = placemarks?.first, let county = placemark.subAdministrativeArea {
                DispatchQueue.main.async {
                    self.surroundingCounty = county
                }
            } else {
                // County information not available
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



enum GreetingType {
    case morning, afternoon, evening
    
    var mealTime: String {
        switch self {
        case .morning: return "Breakfast"
        case .afternoon: return "Lunch"
        case .evening: return "Dinner"
        }
    }
}

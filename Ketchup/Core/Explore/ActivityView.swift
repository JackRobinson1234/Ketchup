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
import FirebaseFirestoreInternal

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
    @State private var selectedCuisines: [String] = []
    @State private var mealTime: MealTime = .breakfast
    @State private var showCuisineSheet: Bool = false
    @State private var selectedCuisineForSheet: String? = nil
    @State private var selectedLocationCoordinate: CLLocationCoordinate2D?

    enum Tab {
        case dailyPoll
        case discover
        case friends
    }
    var body: some View {
        NavigationStack {
            VStack{
                if !isLoading{
                    ZStack(alignment: .top) {
                        ScrollView {
                            LazyVStack(alignment: .leading, spacing: 20) {
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
                } else {
                    FastCrossfadeFoodImageView()
                }
                
            }
            .navigationBarHidden(true)
            .refreshable {
                Task{
                    isLoading = true
                    await refreshData()
                    isLoading = false
                }
            }
            .sheet(isPresented: $showLocationSearch) {
                LocationSearchView(
                    city: $city,
                    state: $state,
                    surroundingGeohash: $surroundingGeohash,
                    surroundingCounty: $surroundingCounty,
                    onLocationSelected: {
                        viewModel.resetData()
                        Task {
                            isLoading = true
                            await refreshLocationData()
                            isLoading = false
                        }
                    },
                    selectedLocationCoordinate: $selectedLocationCoordinate
                    
                )
                .presentationDetents([.height(UIScreen.main.bounds.height * 0.5)])
            }
            .sheet(isPresented: $showContacts) {
                ContactsView(shouldFetchExistingUsers: shouldShowExistingUsersOnContacts)
            }
            .sheet(isPresented: $showPollUploadView) {
                PollUploadView()
            }
            .onAppear {

                computeGreeting()
                    // Handle location not available
                    locationManager.requestLocation { success in
                        if success, let coordinate = locationManager.userLocation?.coordinate {
                            selectedLocationCoordinate = coordinate
                            reverseGeocodeLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
                            if !viewModel.hasFetchedMealRestaurants {
                                Task {
                                    isLoading = true
                                    await loadAllRestaurants(location: coordinate)
                                    isLoading = false
                                }
                            }
                        } else if let geoPoint = AuthService.shared.userSession?.location?.geoPoint {
                            // Use the user's selected location
                            let latitude = geoPoint.latitude
                            let longitude = geoPoint.longitude
                            selectedLocationCoordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                            surroundingGeohash = GFUtils.geoHash(forLocation: selectedLocationCoordinate!)
                            reverseGeocodeLocation(latitude: latitude, longitude: longitude)
                            // Now that we have the location, we can call loadAllRestaurants
                            Task {
                                isLoading = true
                                await loadAllRestaurants(location: selectedLocationCoordinate!)
                                isLoading = false
                            }
                        }
                    }
               
            }
        }
    }
    private func loadAllRestaurants(location: CLLocationCoordinate2D) async {
        // Load meal restaurants only if not already fetched
        if !viewModel.hasFetchedMealRestaurants {
            do {
                try await viewModel.fetchMealRestaurants(mealTime: greetingType.mealTime, location: location)
            } catch {
                print("Error fetching meal restaurants: \(error)")
            }
        }

        // Fetch restaurants once and store them
        do {
            try await viewModel.fetchRestaurants(location: location, limit: 30)
        } catch {
            print("Error fetching restaurants: \(error)")
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
        VStack(alignment: .leading, spacing: 25) {
            inviteContactsButton
            dailyPollContent
            if let user = AuthService.shared.userSession {
                Text("\(greeting), \(user.fullname)!")
                    .font(.custom("MuseoSansRounded-700", size: 25))
                    .padding(.horizontal)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }
            
            if !viewModel.mealRestaurants.isEmpty {
                VStack{
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
                                
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }

            // Group restaurants by macrocategory (cuisine)
            let groupedRestaurants = Dictionary(grouping: viewModel.fetchedRestaurants) { $0.macrocategory ?? "" }

            // Iterate over each cuisine
            if !groupedRestaurants.isEmpty {
                ForEach(groupedRestaurants.keys.sorted(), id: \.self) { cuisine in
                    if let restaurants = groupedRestaurants[cuisine], !restaurants.isEmpty {
                        VStack{
                            HStack {
                                Text("Popular \(cuisine)")
                                    .font(.custom("MuseoSansRounded-700", size: 25))
                                Spacer()
                                Button(action: {
                                    selectedCuisineForSheet = cuisine
                                }) {
                                    Text("See more >")
                                        .font(.custom("MuseoSansRounded-500", size: 14))
                                        .foregroundColor(.gray)
                                }
                            }
                            .padding(.horizontal)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 16) {
                                    ForEach(restaurants.prefix(10), id: \.id) { restaurant in
                                        NavigationLink(destination: RestaurantProfileView(restaurantId: restaurant.id)) {
                                            RestaurantCardView(userLocation: locationManager.userLocation, restaurant: restaurant)
                                            
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                }
            } else {
                // Existing code for no restaurants
                VStack {
                    Image("Skip")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 100)
                    Text("Welcome!")
                        .font(.custom("MuseoSansRounded-700", size: 16))
                    Text("It looks like we don't have any restaurants in your area just yet. However, you can be the first to discover and review local spots anywhere by tapping the '+' button.")
                        .font(.custom("MuseoSansRounded-500", size: 14))
                        .multilineTextAlignment(.center)
                        .padding()
                }
                .background(RoundedRectangle(cornerRadius: 10)
                .fill(Color.gray.opacity(0.1)))
                .padding(.horizontal)
            }
        }
        // Present the sheet for the selected cuisine
        .sheet(item: $selectedCuisineForSheet) { cuisine in
            CuisineRestaurantsView(cuisine: cuisine, location: locationManager.userLocation?.coordinate)
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
            greeting = "🍳 Good morning"
            mealTime = .breakfast
        case 12..<17:
            greetingType = .afternoon
            greeting = "☀️ Good afternoon"
            mealTime = .lunch
        default:
            greetingType = .evening
            greeting = "🌟 Good evening"
            mealTime = .dinner
        }
        self.greetingType = greetingType
        self.greeting = greeting
        
        // Assign all cuisines for the current meal time
        if let cuisines = mealTimeCuisineMap[mealTime], !cuisines.isEmpty {
            selectedCuisines = cuisines
        } else {
            selectedCuisines = []
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
        // Request the user's location
        locationManager.requestLocation { success in
            if success, let userLocation = locationManager.userLocation {
                // Use the current location
                print("SHOULD BE UPDATING INITIAL LOCATION")
                let latitude = userLocation.coordinate.latitude
                let longitude = userLocation.coordinate.longitude
                selectedLocationCoordinate = userLocation.coordinate
                surroundingGeohash = GFUtils.geoHash(forLocation: userLocation.coordinate)
                reverseGeocodeLocation(latitude: latitude, longitude: longitude)
                // Now that we have the location, we can call loadAllRestaurants
                Task {
                    await loadAllRestaurants(location: selectedLocationCoordinate!)
                }
            } else if let geoPoint = AuthService.shared.userSession?.location?.geoPoint {
                // Use the user's selected location
                let latitude = geoPoint.latitude
                let longitude = geoPoint.longitude
                selectedLocationCoordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                surroundingGeohash = GFUtils.geoHash(forLocation: selectedLocationCoordinate!)
                reverseGeocodeLocation(latitude: latitude, longitude: longitude)
                // Now that we have the location, we can call loadAllRestaurants
                Task {
                    await loadAllRestaurants(location: selectedLocationCoordinate!)
                }
            } else {
                // No location available
                city = nil
                state = nil
                surroundingGeohash = nil
                // Handle no location
                print("User location not available.")
            }
        }
    }
    
    private func refreshData() async {
        pollViewModel.fetchPolls()
    }
    
    private func refreshLocationData() async {
        viewModel.resetData()
        if let coordinate = selectedLocationCoordinate {
            reverseGeocodeLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
            await loadAllRestaurants(location: coordinate)
        } else if let location = locationManager.userLocation?.coordinate {
            selectedLocationCoordinate = location
            reverseGeocodeLocation(latitude: location.latitude, longitude: location.longitude)
            await loadAllRestaurants(location: location)
        } else if let geoPoint = AuthService.shared.userSession?.location?.geoPoint {
            let coordinate = CLLocationCoordinate2D(latitude: geoPoint.latitude, longitude: geoPoint.longitude)
            selectedLocationCoordinate = coordinate
            reverseGeocodeLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
            await loadAllRestaurants(location: coordinate)
        } else {
            // No location available
        }
    }
    
    private func reverseGeocodeLocation(latitude: Double, longitude: Double) {
        let location = CLLocation(latitude: latitude, longitude: longitude)
        let geocoder = CLGeocoder()
        
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            if let error = error {
                // Handle error
                print("Reverse geocoding error: \(error.localizedDescription)")
                return
            }
            
            if let placemark = placemarks?.first {
                DispatchQueue.main.async {
                    self.city = placemark.locality
                    self.state = placemark.administrativeArea
                    self.surroundingCounty = placemark.subAdministrativeArea ?? "Nearby"
                    print("Setting city", city)
                }
            } else {
                // Placemark not available
                print("Placemark not available.")
            }
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

extension String: Identifiable {
    public var id: String { self }
}

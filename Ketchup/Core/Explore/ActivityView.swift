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
    @ObservedObject var locationViewModel: LocationViewModel
    @State private var isLoading = true
    @State private var showContacts = false
    @State private var shouldShowExistingUsersOnContacts = false
    @State private var showLocationSearch = false
    @State private var selectedTab: Tab = .restaurants // Default to restaurants
    @State private var showPollUploadView = false
    @StateObject private var pollViewModel = PollViewModel()
    @State private var currentTabHeight: CGFloat = 650
    @State private var selectedPollIndex: Int = 0
    @ObservedObject var feedViewModel: FeedViewModel
    @State private var greetingType: GreetingType = .morning
    @State private var greeting: String = ""
    @State private var selectedCuisines: [String] = []
    @State private var mealTime: MealTime = .breakfast
    @State private var showCuisineSheet: Bool = false
    @State private var selectedCuisineForSheet: String? = nil
    @State private var initialLoad: Bool = true
    @State var selectedPost: Post? = nil
    @Binding var newPostsCount: Int
    @EnvironmentObject var tabController: TabBarController
    @State private var randomRestaurantFact: String = ""
    @State private var showTrendingPostsSheet = false
    @State private var showGlobalTrendingPostsSheet = false

    enum Tab {
        case restaurants
        case leaderboards
        case poll
    }
    
    var body: some View {
        LazyVStack {
            if !isLoading {
                Color.clear
                    .frame(height: 100)
                userUpdatesSection
                Button(action: {
                    showLocationSearch.toggle()
                }) {
                    HStack {
                        Image(systemName: "location")
                            .font(.system(size: 11))
                            .foregroundColor(.gray)
                        Text(locationViewModel.city != nil && locationViewModel.state != nil ? "\(locationViewModel.city!), \(locationViewModel.state!)" : "Any Location")
                            .font(.custom("MuseoSansRounded-500", size: 12))
                            .foregroundColor(.gray)
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray, lineWidth: 1)
                    )
                    
                }
                tabButtons
                ScrollView {
                    LazyVStack{
                        contentBasedOnSelectedTab
                    }
                }
                .refreshable {
                    Task {
                        isLoading = true
                        await refreshData()
                        isLoading = false
                    }
                }
            } else {
                VStack {
                    Color.clear
                        .frame(height: 100)
                        .edgesIgnoringSafeArea(.top)
                    FastCrossfadeFoodImageView()
                }
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showLocationSearch) {
            LocationSearchView(locationViewModel: locationViewModel)
                .presentationDetents([.height(UIScreen.main.bounds.height * 0.5)])
        }
        .sheet(isPresented: $showGlobalTrendingPostsSheet) {
                    TrendingPostsListView(viewModel: viewModel, isGlobal: true)
                }
        .sheet(item: $selectedPost) { post in
            NavigationStack {
                ScrollView {
                    WrittenFeedCell(viewModel: FeedViewModel(), post: .constant(post), scrollPosition: .constant(nil), pauseVideo: .constant(false), selectedPost: .constant(nil), checkLikes: true)
                }
                .modifier(BackButtonModifier())
                .navigationDestination(for: PostRestaurant.self) { restaurant in
                    RestaurantProfileView(restaurantId: restaurant.id)
                }
            }
        }
        .sheet(isPresented: $showContacts) {
            ContactsView(shouldFetchExistingUsers: shouldShowExistingUsersOnContacts)
        }
        .sheet(isPresented: $showPollUploadView) {
            PollUploadView()
        }
        .sheet(isPresented: $showTrendingPostsSheet) {
            TrendingPostsListView(viewModel: viewModel, location: locationViewModel.selectedLocationCoordinate)
        }
        .onAppear {
            if initialLoad {
                initialLoad = false
                computeGreeting()
                randomRestaurantFact = restaurantFacts.randomElement() ?? "Restaurants are fascinating!"
                if let coordinate = locationViewModel.selectedLocationCoordinate {
                    // Use the selected coordinate
                    Task {
                        isLoading = true
                        await pollViewModel.fetchPolls()
                        await loadAllRestaurants(location: coordinate)
                        
                        isLoading = false
                    }
                } else {
                    // Request location
                    locationViewModel.requestLocation()
                }
            }
        }
        .onChange(of: locationViewModel.selectedLocationCoordinate) { newCoordinate in
            if let coordinate = newCoordinate {
                Task {
                    isLoading = true
                    viewModel.resetData()
                    await pollViewModel.fetchPolls() // Reset data when location changes
                    await loadAllRestaurants(location: coordinate)
                    isLoading = false
                }
            }
        }
        
    }
    private var userUpdatesSection: some View {
        VStack{
            VStack(alignment: .leading, spacing: 2){
                if let user = AuthService.shared.userSession {
                    Text("\(greeting), \(user.fullname)!")
                        .font(.custom("MuseoSansRounded-700", size: 25))
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                }
                
                Text("Daily Fact: \(randomRestaurantFact.lowercased())")
                    .font(.custom("MuseoSansRounded-500", size: 12))
                    .foregroundColor(.black)
                    .padding(.top, 5)
            }
            HStack(alignment: .top) {
                
                // Number of new friends' posts
                Button(action: {
                    if newPostsCount == 0 {
                        showContacts = true
                    } else {
                        feedViewModel.selectedTab = .following
                    }
                }) {
                    VStack {
                        Text("😎") // Replacing with emoji
                            .font(.largeTitle)
                        Text("\(newPostsCount) new friend posts")
                            .font(.custom("MuseoSansRounded-500", size: 14))
                        
                        // Call to action based on friend count
                        if newPostsCount == 0 {
                            Text("Find friends")
                                .font(.custom("MuseoSansRounded-300", size: 12))
                                .foregroundColor(.gray)
                        } else {
                            Text("See posts")
                                .font(.custom("MuseoSansRounded-300", size: 12))
                                .foregroundColor(.gray)
                        }
                    }
                }
                .frame(width:(UIScreen.main.bounds.width - (8 * 2)) / 4)
                Spacer()
                
                // Whether they've voted in the daily poll
                Button(action: {
                    feedViewModel.initialPrimaryScrollPosition = "DailyPoll"
                }) {
                    VStack {
                        Text(hasUserVotedToday() ? "📊" : "📊") // Replacing with emoji
                            .font(.largeTitle)
                        Text(hasUserVotedToday() ? "Voted in Poll 🎉" : "New Daily Poll!")
                            .font(.custom("MuseoSansRounded-500", size: 14))
                        
                        // Call to action based on poll status
                        if hasUserVotedToday() {
                            if let pollStreak = AuthService.shared.userSession?.pollStreak {
                                Text("🔥 streak: \(pollStreak) days")
                                    .font(.custom("MuseoSansRounded-300", size: 12))
                                    .foregroundColor(.gray)
                            }
                        } else {
                            Text("Vote now")
                                .font(.custom("MuseoSansRounded-300", size: 12))
                                .foregroundColor(.gray)
                        }
                    }
                }
                .frame(width:(UIScreen.main.bounds.width - (8 * 2)) / 4)
                Spacer()
                
                // Weekly posting streak
                if let postStreak = AuthService.shared.userSession?.weeklyStreak {
                    Button(action: {
                        tabController.selectedTab = 2
                    }) {
                        VStack {
                            Text("🔥") // Replacing with emoji
                                .font(.largeTitle)
                            Text("\(postStreak) week review streak")
                                .font(.custom("MuseoSansRounded-500", size: 14))
                            
                            // Call to action for review streak
                            Text("Post a review")
                                .font(.custom("MuseoSansRounded-300", size: 12))
                                .foregroundColor(.gray)
                        }
                    }
                    .frame(width:(UIScreen.main.bounds.width - (8 * 2)) / 4)
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1)) // Light gray background
        .cornerRadius(10)
        .padding(.bottom, 8)
        .padding(.horizontal)
    }
    private func loadAllRestaurants(location: CLLocationCoordinate2D) async {
        do {
            try await viewModel.fetchMealRestaurants(mealTime: greetingType.mealTime, location: location)
            try await viewModel.fetchRestaurants(location: location)
            try await viewModel.fetchTrendingPosts(location: location)
            await viewModel.fetchTopGlobalTrendingPosts() // Fetch top 5 global trending posts

        } catch {
            print("Error fetching restaurants: \(error)")
        }
    }
    
    private var contentBasedOnSelectedTab: some View {
        Group {
            if selectedTab == .restaurants {
                restaurantsContent
            } else if selectedTab == .leaderboards {
                leaderboardsContent
            } else if selectedTab == .poll {
                dailyPollContent
            }
        }
    }
    
    private var tabButtons: some View {
        VStack {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    actionButton(title: "Nearby Restaurants", icon: "fork.knife", isSelected: selectedTab == .restaurants) {
                        selectedTab = .restaurants
                    }
                    actionButton(title: "Leaderboards", icon: "chart.bar", isSelected: selectedTab == .leaderboards) {
                        selectedTab = .leaderboards
                    }
                    actionButton(title: "Poll", icon: "list.bullet.clipboard", isSelected: selectedTab == .poll) {
                        selectedTab = .poll
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
    
   
    
    private var locationButton: some View {
        Button(action: {
            showLocationSearch = true
        }) {
            HStack(spacing: 1) {
                Image(systemName: "location")
                    .foregroundColor(.gray)
                    .font(.caption)
                Text(locationViewModel.city != nil && locationViewModel.state != nil ? "\(locationViewModel.city!), \(locationViewModel.state!)" : "Set Location")
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
    
    private var restaurantsContent: some View {
        VStack(alignment: .leading, spacing: 25) {
            if !viewModel.mealRestaurants.isEmpty {
                VStack(alignment: .leading) {
                    Text("Popular \(greetingType.mealTimeDisplay.capitalized)")
                        .font(.custom("MuseoSansRounded-700", size: 25))
                        .padding(.horizontal)
                    ScrollView(.horizontal, showsIndicators: false) {
                        LazyHStack(spacing: 16) {
                            ForEach(viewModel.mealRestaurants, id: \.id) { restaurant in
                                NavigationLink(destination: RestaurantProfileView(restaurantId: restaurant.id)) {
                                    if let coordinate = locationViewModel.selectedLocationCoordinate {
                                        let userLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
                                        RestaurantCardView(userLocation: userLocation, restaurant: restaurant)
                                    } else {
                                        // Handle case where the coordinate is nil
                                        RestaurantCardView(userLocation: nil, restaurant: restaurant)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
            
            // Group restaurants by macrocategory (cuisine)
            let groupedRestaurants = Dictionary(grouping: viewModel.fetchedRestaurants) { $0.macrocategory ?? "" }
            let sortedCuisines = groupedRestaurants.keys.sorted { cuisine1, cuisine2 in
                let index1 = selectedCuisines.firstIndex(of: cuisine1) ?? selectedCuisines.count
                let index2 = selectedCuisines.firstIndex(of: cuisine2) ?? selectedCuisines.count
                return index1 < index2
            }
            
            // Iterate over each cuisine
            if !groupedRestaurants.isEmpty {
                ForEach(sortedCuisines, id: \.self) { cuisine in
                    if let restaurants = groupedRestaurants[cuisine], !restaurants.isEmpty {
                        VStack {
                            HStack {
                                Text("Popular \(cuisine) \(cuisineEmojis[cuisine] ?? "")")
                                    .font(.custom("MuseoSansRounded-700", size: 25))
                                Spacer()
                                Button(action: {
                                    selectedCuisineForSheet = cuisine
                                }) {
                                    Text("See more >")
                                        .font(.custom("MuseoSansRounded-300", size: 12))
                                        .foregroundColor(.gray)
                                }
                            }
                            .padding(.horizontal)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                LazyHStack(spacing: 16) {
                                    ForEach(restaurants, id: \.id) { restaurant in
                                        NavigationLink(destination: RestaurantProfileView(restaurantId: restaurant.id)) {
                                            if let coordinate = locationViewModel.selectedLocationCoordinate {
                                                let userLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
                                                RestaurantCardView(userLocation: userLocation, restaurant: restaurant)
                                            } else {
                                                // Handle case where the coordinate is nil
                                                RestaurantCardView(userLocation: nil, restaurant: restaurant)
                                            }
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
            CuisineRestaurantsView(cuisine: cuisine, location: locationViewModel.selectedLocationCoordinate)
        }
    }
    
    private var leaderboardsContent: some View {
        VStack(alignment: .leading, spacing: 25) {
            // Nearby Trending Posts Section
            if !viewModel.trendingPosts.isEmpty {
                VStack(alignment: .leading) {
                    HStack {
                        Text("Nearby Trending Posts")
                            .font(.custom("MuseoSansRounded-700", size: 25))
                            .padding(.horizontal)
                        Spacer()
                        Button(action: {
                            showTrendingPostsSheet = true
                        }) {
                            Text("See all >")
                                .font(.custom("MuseoSansRounded-300", size: 12))
                                .foregroundColor(.gray)
                        }
                        .padding(.trailing)
                    }
                    
                    VStack {
                        ForEach(Array(viewModel.trendingPosts.prefix(5).enumerated()), id: \.element.id) { index, post in
                            Button(action: {
                                selectedPost = post
                            }) {
                                TrendingPostRow(index: index, post: post)
                                    .padding(.vertical, 8)
                                    .padding(.horizontal)
                            }
                            Divider()
                        }
                    }
                }
            } else {
                // No trending posts message
                Text("No trending posts available.")
                    .padding()
            }
            
            // Global Trending Posts Section
            if !viewModel.globalTrendingPosts.isEmpty {
                VStack(alignment: .leading) {
                    HStack {
                        Text("Global Trending Posts")
                            .font(.custom("MuseoSansRounded-700", size: 25))
                            .padding(.horizontal)
                        Spacer()
                        Button(action: {
                            showGlobalTrendingPostsSheet = true
                        }) {
                            Text("See all >")
                                .font(.custom("MuseoSansRounded-300", size: 12))
                                .foregroundColor(.gray)
                        }
                        .padding(.trailing)
                    }
                    
                    VStack {
                        ForEach(Array(viewModel.globalTrendingPosts.enumerated()), id: \.element.id) { index, post in
                            Button(action: {
                                selectedPost = post
                            }) {
                                TrendingPostRow(index: index, post: post)
                                    .padding(.vertical, 8)
                                    .padding(.horizontal)
                            }
                            Divider()
                        }
                    }
                }
            }  else {
                // No global trending posts message
                Text("No global trending posts available.")
                    .padding()
            }
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
    
    private func refreshData() async {
        await pollViewModel.fetchPolls()
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
}


enum GreetingType {
    case morning, afternoon, evening
    
    var mealTimeDisplay: String {
        switch self {
        case .morning: return "Breakfast 🍳"
        case .afternoon: return "Lunch 🥪"
        case .evening: return "Dinner 🍽️ "
        }
    }
    
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


struct PostCardView: View {
    var post: Post
    private let spacing: CGFloat = 8
    private var width: CGFloat {
        (UIScreen.main.bounds.width - (spacing * 2)) / 3
    }
    var cornerRadius: CGFloat
    var showNames: Bool
    
    var body: some View {
        ZStack {
            if post.mediaType != .written, !post.thumbnailUrl.isEmpty {
                KFImage(URL(string: post.thumbnailUrl))
                    .resizable()
                    .scaledToFill()
                    .frame(width: width, height: 160)
                    .cornerRadius(cornerRadius)
                    .clipped()
                    .overlay(
                        VStack(alignment: .leading) {
                            HStack {
                                Spacer()
                                if post.repost {
                                    Image(systemName: "arrow.2.squarepath")
                                        .foregroundStyle(.white)
                                        .font(.custom("MuseoSansRounded-300", size: 16))
                                }
                            }
                            Spacer()
                        }
                    )
            } else {
                VStack {
                    if let profileImageUrl = post.restaurant.profileImageUrl {
                        RestaurantCircularProfileImageView(imageUrl: profileImageUrl, size: .large)
                    }
                    if !post.caption.isEmpty {
                        Image(systemName: "line.3.horizontal")
                            .resizable()
                            .foregroundStyle(.gray)
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 45, height: 15)
                    }
                }
                .frame(width: width, height: 160)
                .background(Color.gray.opacity(0.2))
                .cornerRadius(cornerRadius)
                .clipped()
            }
            
            VStack(alignment: .leading) {
                HStack {
                    
                    HStack(spacing: 1) {
                        
                        
                        Text("@\(post.user.username)")
                            .lineLimit(2)
                            .truncationMode(.tail)
                            .foregroundColor(.white)
                            .font(.custom("MuseoSansRounded-300", size: 10))
                            .bold()
                            .shadow(color: .black, radius: 2, x: 0, y: 1)
                            .multilineTextAlignment(.leading)
                            .minimumScaleFactor(0.5)
                    }
                    
                    Spacer()
                    HStack(spacing: 1) {
                        Image(systemName: "heart")
                            .font(.footnote)
                            .foregroundColor(.white)
                            .shadow(color: .black, radius: 2, x: 0, y: 1)
                        Text("\(post.likes)")
                            .font(.custom("MuseoSansRounded-300", size: 10))
                            .bold()
                            .foregroundColor(.white)
                            .shadow(color: .black, radius: 2, x: 0, y: 1)
                    }
                }
                Spacer()
                HStack(alignment: .bottom) {
                    if showNames {
                        Text("\(post.restaurant.name)")
                            .lineLimit(2)
                            .truncationMode(.tail)
                            .foregroundColor(.white)
                            .font(.custom("MuseoSansRounded-300", size: 10))
                            .bold()
                            .shadow(color: .black, radius: 2, x: 0, y: 1)
                            .multilineTextAlignment(.leading)
                            .minimumScaleFactor(0.5)
                    }
                    
                    Spacer()
                    if let rating = post.overallRating{
                        let formatted =  String(format: "%.1f", rating)
                        Text("\(formatted)")
                            .lineLimit(2)
                            .truncationMode(.tail)
                            .foregroundColor(.white)
                            .font(.custom("MuseoSansRounded-300", size: 10))
                            .bold()
                            .shadow(color: .black, radius: 2, x: 0, y: 1)
                            .multilineTextAlignment(.leading)
                            .minimumScaleFactor(0.5)
                    }
                }
            }
            .padding(4)
        }
    }
}

struct TrendingPostRow: View {
    var index: Int
    var post: Post

    var body: some View {
        HStack(spacing: 12) {
            // Ranking number
            Text("\(index + 1).")
                .font(.custom("MuseoSansRounded-700", size: 16))
                .foregroundColor(.black)

            // Thumbnail Image
            if !post.thumbnailUrl.isEmpty {
                KFImage(URL(string: post.thumbnailUrl))
                    .resizable()
                    .scaledToFill()
                    .frame(width: 60, height: 60)
                    .cornerRadius(8)
                    .clipped()
            } else {
                // Placeholder image if thumbnail is missing
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 60, height: 60)
                    .cornerRadius(8)
            }

            VStack(spacing:6) {
                if let rating = post.overallRating {
                    ScrollFeedOverallRatingView(rating: rating, font: .black, size: 30)
                        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                }
                HStack(spacing: 1) {
                    Image(systemName: "heart")
                        .font(.footnote)
                        .foregroundColor(.gray)

                    Text("\(post.likes)")
                        .font(.custom("MuseoSansRounded-300", size: 10))
                        .foregroundColor(.gray)
                }
            }

            VStack(alignment: .leading, spacing: 0) {
                // Restaurant name
                Text(post.restaurant.name)
                    .font(.custom("MuseoSansRounded-700", size: 14))
                    .foregroundColor(.black)

                // City and state (new addition)
                if let city = post.restaurant.city, let state = post.restaurant.state {
                    Text("\(city), \(state)")
                        .font(.custom("MuseoSansRounded-500", size: 12))
                        .foregroundColor(.gray)
                }

                // Username
                Text("@\(post.user.username)")
                    .font(.custom("MuseoSansRounded-500", size: 12))
                    .foregroundColor(.gray)

                // Rating and caption
                Text(post.caption)
                    .font(.custom("MuseoSansRounded-300", size: 12))
                    .foregroundColor(.black)
                    .lineLimit(2)
                    .truncationMode(.tail)
            }

            Spacer()
        }
    }
}
let cuisineEmojis: [String: String] = [
    "Italian": "🍝",
    "Chinese": "🥡",
    "Japanese": "🍣",
    "Korean": "🍜",
    "Mexican": "🌮",
    "American": "🍔",
    "French": "🥖",
    "Spanish": "🍤",
    "Greek": "🥙",
    "Middle Eastern": "🥙",
    "German": "🍖",
    "Caribbean": "🍲",
    "African": "🍛",
    "South American": "🥩",
    "Central American": "🍲",
    "Eastern European": "🥟",
    "Seafood": "🦞",
    "Vegetarian and Vegan": "🥗",
    "Fusion and International": "🌍",
    "Fast Food and Casual": "🍟",
    "Breakfast and Brunch": "🥞",
    "Barbecue and Grill": "🍖",
    "Noodles": "🍜",
    "Specialty and Dietary": "🥬",
    "Cafes and Bakeries": "☕️",
    "Bars and Pubs": "🍻",
    "Desserts and Sweets": "🍩",
    "Street Food and Food Trucks": "🚚",
    "Buffet and All-You-Can-Eat": "🍽️",
    "Markets and Specialty Shops": "🛒",
    "European": "🥐",
    "Vietnamese": "🍜",
    "Indian": "🍛"
]
let restaurantFacts = [
    "The word 'restaurant' comes from the French word 'restaurer,' which means 'to restore.'",
    "The oldest restaurant still in operation is Sobrino de Botín in Madrid, Spain, opened in 1725.",
    "McDonald's sells more than 75 hamburgers every second.",
    "The first drive-thru restaurant was created in 1948 by In-N-Out Burger.",
    "Pizza Hut delivered pizza to the International Space Station in 2001.",
    "The world’s largest restaurant is the Bawabet Dimashq (Damascus Gate) Restaurant in Syria, seating 6,014 people.",
    "In Japan, you can eat at robot-operated restaurants.",
    "Ketchup was once sold as medicine in the 1830s.",
    "The term 'fast food' was first recognized in the Merriam-Webster dictionary in 1951.",
    "There is a restaurant in Australia where you can eat while suspended 50 meters in the air.",
    "The Eiffel Tower has a Michelin-starred restaurant, Le Jules Verne, located 410 feet above ground.",
    "One of the smallest restaurants in the world is 'Solo per Due' in Italy, serving only two people at a time.",
    "The first pizzeria in the U.S. opened in 1905 in New York City.",
    "The 'happy meal' concept originated in Guatemala in the 1970s.",
    "Sushi chefs in Japan must train for over a decade before being considered a master.",
    "The most expensive pizza in the world, created by Renato Viola, costs around $12,000.",
    "The first restaurant to have a rotating dining room is the 'Top of the World' restaurant in Las Vegas.",
    "The restaurant industry employs over 15 million people in the U.S.",
    "The Cheesecake Factory’s menu has over 250 items!",
    "In Singapore, there’s a restaurant where diners eat in complete darkness.",
    "There’s a restaurant in China where all waiters are robots.",
    "Taco Bell was the first fast-food chain to open in outer space — on the Mir Space Station.",
    "The oldest American restaurant still in operation is the Union Oyster House in Boston, founded in 1826.",
    "The first Starbucks opened in Seattle, Washington, in 1971.",
    "The world’s longest restaurant table stretched over 2.4 km (1.49 miles).",
    "Some Michelin-starred restaurants serve tasting menus of over 20 courses.",
    "In Dubai, there’s an underwater restaurant, Ossiano, inside a giant aquarium.",
    "The French Laundry in California is one of the world’s most famous Michelin-starred restaurants.",
    "China has the highest number of restaurants globally, with over 8 million.",
    "The tradition of tipping started in England during the 17th century.",
    "In Japan, slurping your noodles is a sign of appreciation for the meal.",
    "The world’s most expensive restaurant is Sublimotion in Ibiza, with prices reaching up to $2,000 per person.",
    "Drive-thru lanes account for about 70% of fast food restaurant sales in the U.S.",
    "Chick-fil-A is the largest purchaser of peanut oil in the United States.",
    "Waffle House claims to have served over 2.5 billion waffles since its opening.",
    "The highest restaurant in the world is 'Chacaltaya' in Bolivia, located at 17,785 feet above sea level.",
    "The first fine dining restaurant in America was Delmonico’s in New York, opened in 1837.",
    "The 'all-you-can-eat' buffet concept originated in the 1940s in Las Vegas.",
    "In Italy, it is considered rude to ask for parmesan on pizza.",
    "The busiest restaurant day in the U.S. is Mother’s Day.",
    "Noma in Copenhagen, Denmark, was voted the world’s best restaurant several times.",
    "The McDonald's 'Golden Arches' are recognized by more people worldwide than the Christian cross.",
    "Some restaurants in the U.S. serve food out of food trucks, a growing trend in the culinary scene.",
    "TGI Fridays popularized the concept of casual dining in the 1960s.",
    "The world’s most expensive hamburger was sold for $5,000 at Juicys Outlaw Grill in Oregon.",
    "‘Restaurant Week’ started in New York City in 1992.",
    "The first food truck dates back to the 1860s when a Texas cattleman built a mobile kitchen.",
    "In Thailand, there's a restaurant where food is served by waiters dressed as pandas.",
    "French fries are the most popular side item in American restaurants.",
    "The first all-vegetarian restaurant opened in 1849 in London.",
    "Some high-end restaurants have secret menus that only frequent guests know about.",
    "The largest fast food chain in the world by locations is Subway.",
    "The first pizza delivery took place in 1889 in Naples, Italy, to Queen Margherita.",
    "Michelin Stars, awarded to restaurants, originated from the Michelin tire company to promote road trips.",
    "Restaurants use music, lighting, and seating arrangements to influence how fast you eat.",
    "In some sushi restaurants, the chef will refuse to serve soy sauce with certain dishes.",
    "The first fast food chain in America was White Castle, founded in 1921.",
    "Diners in Denmark pay nearly 25% VAT (sales tax) on their restaurant bills.",
    "The world's longest pizza measured 1.9 kilometers long.",
    "Some restaurants in New York have a 'no tipping' policy, with the cost of service included in the bill.",
    "Many high-end restaurants offer wine pairings customized to the tasting menu.",
    "‘Molecular gastronomy’ restaurants, like elBulli, use science to create unusual dishes.",
    "In Korea, restaurants use grills at the table for cooking your own food, called 'Korean BBQ.'",
    "Burger King is known as 'Hungry Jack's' in Australia.",
    "In France, it’s common to spend two hours or more on a multi-course meal.",
    "There are restaurants in Japan where all the food is prepared by ninjas.",
    "In Canada, ‘poutine,’ French fries topped with gravy and cheese curds, is a popular dish.",
    "Some restaurants offer 'pay-what-you-want' pricing to reduce food waste.",
    "Many Michelin-starred chefs have their own lines of cookware.",
    "There’s a restaurant in New York City that only serves peanut butter-based dishes.",
    "Alcatraz, the infamous prison, once had a highly regarded cafeteria.",
    "Some restaurants in London have a no-reservation policy, meaning long waits.",
    "The most popular ethnic cuisine in the U.S. is Italian.",
    "The concept of ‘farm-to-table’ restaurants focuses on using local and organic ingredients.",
    "A common practice in high-end sushi restaurants is serving fish caught the same day.",
    "Some restaurants in Sweden offer discounts to patrons who arrive by bicycle.",
    "In Germany, you’ll find many self-service restaurants called 'imbiss.'",
    "The oldest continuously operating soda fountain in the U.S. is in St. Louis, Missouri.",
    "There are cat-themed restaurants in Japan, where cats roam freely.",
    "In Portugal, it’s common to serve salted cod (bacalhau) in hundreds of ways.",
    "Modern-day ramen shops are inspired by Chinese noodle houses.",
    "In Peru, you’ll find restaurants that serve guinea pig as a delicacy.",
    "Some restaurants in Iceland serve fermented shark, a traditional dish.",
    "‘Diners, Drive-Ins, and Dives’ has highlighted hundreds of unique restaurants in the U.S.",
    "The Michelin Guide was originally a free publication to encourage travel.",
    "In Spain, tapas are small dishes served with drinks, originally to cover the glass (tapas means 'lid').",
    "In Vietnam, street vendors serve pho (noodle soup) from tiny stalls.",
    "In Italy, the ‘slow food’ movement began to promote traditional cooking and sustainable eating.",
    "Many luxury restaurants feature chef’s tables, offering a view of the kitchen.",
    "Some restaurants are entirely plant-based, catering to vegans and vegetarians.",
    "The world’s largest bowl of pasta weighed more than 17,000 pounds.",
    "The 'Supper Club' movement in the U.S. began in the 1930s and 1940s as elegant dining experiences.",
    "Spain’s elBulli, once the top-rated restaurant in the world, closed to become a culinary think tank.",
    "Michelin-Star inspectors dine anonymously to ensure unbiased reviews.",
    "Some restaurants charge a 'corkage fee' when guests bring their own wine.",
    "The busiest McDonald's is in Moscow, Russia, serving over 40,000 people daily.",
    "Drive-thru funeral parlors in the U.S. have partnered with fast food restaurants to offer food service.",
    "Some exclusive restaurants have waiting lists months or even years long.",
    "The Guinness World Record for the most expensive taco, created by a restaurant in Mexico, costs $25,000.",
    "The smallest restaurant in the world is only 1.8 square meters and seats just two people.",
    "In Thailand, there is a restaurant where monkeys serve the food.",
    "The world’s first pizza vending machine was introduced in Italy in 2009.",
    "The first food delivery service started in 1889 in Naples, Italy, delivering pizza.",
    "Ruth’s Chris Steak House got its name when the original restaurant burned down, and the founder had to buy a new one.",
    "Panda Express was created by Chinese immigrants and became one of the most popular Asian fast food chains in America.",
    "Many Michelin-starred restaurants have a waitlist over a year long.",
    "Restaurants in Singapore often include 'service charge' as a replacement for tipping.",
    "One of the world's rarest foods, white truffles, can cost more than $3,000 per pound.",
    "McDonald’s once tested spaghetti on its menu.",
    "The phrase 'fine dining' refers to restaurants that offer high-quality service and more elaborate menus."
]

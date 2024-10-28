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
    @State private var showLocationSearch = false
    @State private var showPollUploadView = false
    @StateObject private var pollViewModel = PollViewModel()
    @State private var currentTabHeight: CGFloat = 650
    @State private var selectedPollIndex: Int = 0
    @ObservedObject var feedViewModel: FeedViewModel
    @State private var greetingType: GreetingType = .morning
    @State private var greeting: String = ""
    @State private var selectedCuisines: [String] = []
    @State private var mealTime: MealTime = .breakfast
    @State private var initialLoad: Bool = true
    @Binding var newPostsCount: Int
    @State private var randomRestaurantFact: String = ""
    @Binding var hideTopUI: Bool
    @Binding var topBarHeight: CGFloat
    @State private var showAllCuisines = false

    // MARK: - Computed Properties
    private var groupedRestaurants: [String: [Restaurant]] {
        Dictionary(grouping: viewModel.fetchedRestaurants) { $0.macrocategory ?? "" }
    }
    
    private var cuisineCategorySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading) {
                    Text("Explore")
                        .font(.custom("MuseoSansRounded-700", size: 25))
                        .foregroundStyle(.black)
                   

                    Button {
                        showLocationSearch = true
                    } label: {
                        Text("Near \(locationViewModel.city != nil && locationViewModel.state != nil ? "\(locationViewModel.city!), \(locationViewModel.state!)" : "Any Location")")
                            .font(.custom("MuseoSansRounded-500", size: 12))
                            .foregroundColor(.gray)
                        +
                        Text(" (edit)")
                            .font(.custom("MuseoSansRounded-500", size: 12))
                            .foregroundColor(.red)
                    }
                    
                }
                Spacer()
            }
            .padding(.horizontal)
            
            let columns: [GridItem] = Array(repeating: .init(.flexible(), spacing: 10), count: 2)
            
            LazyVGrid(columns: columns, spacing: 10) {
                Button(action: {
                    showAllCuisines = true
                }) {
                    if let firstCuisine = groupedRestaurants.first {
                        ExploreCell(
                            imageUrl: firstCuisine.value.first?.profileImageUrl,
                            cuisineName: "Nearby Cuisines"
                        )
                    }
                } 
                Button(action: {
                    handlePostTap()
                }) {
                    if let recentPost = viewModel.hasUnseenFriendPosts ? viewModel.recentFriendPost : viewModel.recentGlobalPost {
                        ExploreCell(
                            imageUrl: recentPost.thumbnailUrl,
                            cuisineName: viewModel.hasUnseenFriendPosts ? "Friends Posts" : "Latest Posts",
                            alertCount: newPostsCount
                        )
                    }
                }
                Button(action: {
                    feedViewModel.initialPrimaryScrollPosition = "DailyPoll"
                }) {
                    
                        ExploreCell(
                            imageUrl: pollViewModel.polls.first?.imageUrl,
                            cuisineName: "Daily Poll",
                            alertCount: hasUserVotedToday() ? 0 : 1
                        )
                }
            }
            .padding(.horizontal)
        }
    }

    var body: some View {
        LazyVStack {
            if !isLoading {
                Color.clear
                    .frame(height: 80)
                
                if !hasUserVotedToday() {
                    dailyPollContent
                }
                
                cuisineCategorySection
                    .padding(.top)
                
                if let recentPost = viewModel.hasUnseenFriendPosts ? viewModel.recentFriendPost : viewModel.recentGlobalPost {
                    recentPostSection(post: recentPost)
                        .padding(.top)
                }
                
                if hasUserVotedToday() {
                    dailyPollContent
                        .id("DailyPoll")
                }
                
            } else {
                loadingView
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showLocationSearch) {
            LocationSearchView(locationViewModel: locationViewModel)
                .presentationDetents([.height(UIScreen.main.bounds.height * 0.5)])
        }
        .sheet(isPresented: $showPollUploadView) {
            PollUploadView()
        }
        .onAppear(perform: handleOnAppear)
        .onChange(of: locationViewModel.selectedLocationCoordinate, perform: handleLocationChange)
        .fullScreenCover(isPresented: $showAllCuisines) {
            AllCuisinesView(
                groupedRestaurants: groupedRestaurants,
                locationViewModel: locationViewModel,
                showAllCuisines: $showAllCuisines
            )
        }
    }
    
    // MARK: - View Components
    private var loadingView: some View {
        VStack {
            Color.clear
                .frame(height: 100)
                .edgesIgnoringSafeArea(.top)
            FastCrossfadeFoodImageView()
        }
    }
    
    private func recentPostSection(post: Post) -> some View {
        VStack(alignment: .leading) {
            Text(viewModel.hasUnseenFriendPosts ? "New from friends" : "Featured Post")
                .font(.custom("MuseoSansRounded-700", size: 25))
                .padding(.horizontal)
            
            if newPostsCount > 0 {
                Text("\(newPostsCount) new posts from friends")
                    .font(.custom("MuseoSansRounded-500", size: 12))
                    .foregroundStyle(.gray)
                    .padding(.horizontal)
            }
            
            Button(action: {
                handlePostTap()
            }) {
                PostPreview(post: post)
                    .padding(.vertical, 4)
                    .padding(.horizontal)
            }
        }
    }
    
    // MARK: - Helper Methods
    private func handlePostTap() {
        withAnimation(.easeInOut(duration: 0.5)) {
            feedViewModel.selectedMainTab = .feed
            hideTopUI = false
            topBarHeight = 160
        }
        
        feedViewModel.selectedFeedSubTab = viewModel.hasUnseenFriendPosts ? .following : .discover
    }
    
    private func handleOnAppear() {
        if initialLoad {
            initialLoad = false
            computeGreeting()
            randomRestaurantFact = restaurantFacts.randomElement() ?? "Restaurants are fascinating!"
            
            if let coordinate = locationViewModel.selectedLocationCoordinate {
                Task {
                    isLoading = true
                    pollViewModel.fetchPolls()
                    await loadAllRestaurants(location: coordinate)
                    await viewModel.fetchRecentPosts(unseenCount: newPostsCount)
                    isLoading = false
                }
            } else {
                locationViewModel.requestLocation()
            }
        }
    }
    
    private func handleLocationChange(_ newCoordinate: CLLocationCoordinate2D?) {
        if let coordinate = newCoordinate {
            Task {
                isLoading = true
                viewModel.resetData()
                pollViewModel.fetchPolls()
                await loadAllRestaurants(location: coordinate)
                await viewModel.fetchRecentPosts(unseenCount: newPostsCount)
                isLoading = false
            }
        }
    }
    
    private func loadAllRestaurants(location: CLLocationCoordinate2D) async {
        do {
            try await viewModel.fetchMealRestaurants(mealTime: greetingType.mealTime, location: location)
            try await viewModel.fetchRestaurants(location: location)
            try await viewModel.fetchTrendingPosts(location: location)
            await viewModel.fetchTopGlobalTrendingPosts()
        } catch {
            print("Error fetching restaurants: \(error)")
        }
    }
    
    private func computeGreeting() {
        let hour = Calendar.current.component(.hour, from: Date())
        
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
        
        if let cuisines = mealTimeCuisineMap[mealTime], !cuisines.isEmpty, mealTime == .breakfast {
            selectedCuisines = cuisines
        } else {
            selectedCuisines = []
        }
    }
    
    private func hasUserVotedToday() -> Bool {
        guard let lastVotedDate = AuthService.shared.userSession?.lastVotedPoll else {
            return false
        }
        
        let calendar = Calendar.current
        let losAngelesTimeZone = TimeZone(identifier: "America/Los_Angeles")!
        
        let lastVotedDateLA = calendar.date(byAdding: .hour, value: losAngelesTimeZone.secondsFromGMT() / 3600, to: lastVotedDate)!
        let nowLA = calendar.date(byAdding: .hour, value: losAngelesTimeZone.secondsFromGMT() / 3600, to: Date())!
        
        let lastVotedDay = calendar.startOfDay(for: lastVotedDateLA)
        let todayLA = calendar.startOfDay(for: nowLA)
        
        return calendar.isDate(lastVotedDay, inSameDayAs: todayLA)
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


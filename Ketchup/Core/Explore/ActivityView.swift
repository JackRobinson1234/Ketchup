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
    
    var body: some View {
        LazyVStack {
            if !isLoading {
                Color.clear
                    .frame(height: 80)
                userUpdatesSection
                
                if !hasUserVotedToday() {
                    dailyPollContent
                }
                
                let groupedRestaurants = Dictionary(grouping: viewModel.fetchedRestaurants) { $0.macrocategory ?? "" }
                let sortedCuisines = groupedRestaurants.keys.sorted { cuisine1, cuisine2 in
                    let index1 = selectedCuisines.firstIndex(of: cuisine1) ?? selectedCuisines.count
                    let index2 = selectedCuisines.firstIndex(of: cuisine2) ?? selectedCuisines.count
                    return index1 < index2
                }
                CuisineCategoryView(selectedCuisines: $selectedCuisines,
                                    groupedRestaurants: groupedRestaurants,
                                    locationViewModel: locationViewModel)
                    .padding(.top)
                
                if let recentPost = viewModel.hasUnseenFriendPosts ? viewModel.recentFriendPost : viewModel.recentGlobalPost {
                    VStack(alignment: .leading) {
                        Text(viewModel.hasUnseenFriendPosts ? "New from friends" : "Featured Post")
                            .font(.custom("MuseoSansRounded-700", size: 25))
                            .padding(.horizontal)
                        
                        Button(action: {
                            feedViewModel.selectedMainTab = .feed
                            if viewModel.hasUnseenFriendPosts {
                                feedViewModel.selectedFeedSubTab = .following
                            } else {
                                feedViewModel.selectedFeedSubTab = .discover
                            }
                            
                        }) {
                            PostPreview(post: recentPost)
                                .padding(.vertical, 4)
                                .padding(.horizontal)
                        }
                    }
                    .padding(.top)
                }
                
                if hasUserVotedToday() {
                    dailyPollContent
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
        .sheet(isPresented: $showPollUploadView) {
            PollUploadView()
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
                        pollViewModel.fetchPolls()
                        await loadAllRestaurants(location: coordinate)
                        await viewModel.fetchRecentPosts(unseenCount: newPostsCount)
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
                    pollViewModel.fetchPolls() // Reset data when location changes
                    await loadAllRestaurants(location: coordinate)
                    await viewModel.fetchRecentPosts(unseenCount: newPostsCount)
                    isLoading = false
                }
            }
        }
    }
    
    private var userUpdatesSection: some View {
        VStack{
            VStack(alignment: .leading, spacing: 2){
                if let user = AuthService.shared.userSession {
                    Text("\(greeting), @\(user.username)!")
                        .font(.custom("MuseoSansRounded-700", size: 22))
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                }
                
                Text("Daily Fact: \(randomRestaurantFact.lowercased())")
                    .font(.custom("MuseoSansRounded-500", size: 12))
                    .foregroundColor(.black)
                    .padding(.top, 5)
            }
            HStack{
                Button(action: {
                    showLocationSearch.toggle()
                }) {
                    HStack(spacing: 2) {
                        Image(systemName: "location")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                        Text(locationViewModel.city != nil && locationViewModel.state != nil ? "\(locationViewModel.city!), \(locationViewModel.state!)" : "Any Location")
                            .font(.custom("MuseoSansRounded-500", size: 12))
                            .foregroundColor(.black)
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
                Spacer()
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
        if let cuisines = mealTimeCuisineMap[mealTime], !cuisines.isEmpty, mealTime == .breakfast {
            selectedCuisines = cuisines
        } else {
            selectedCuisines = []
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


//struct PostCardView: View {
//    var post: Post
//    private let spacing: CGFloat = 8
//    private var width: CGFloat {
//        (UIScreen.main.bounds.width - (spacing * 2)) / 3
//    }
//    var cornerRadius: CGFloat
//    var showNames: Bool
//    
//    var body: some View {
//        ZStack {
//            if post.mediaType != .written, !post.thumbnailUrl.isEmpty {
//                KFImage(URL(string: post.thumbnailUrl))
//                    .resizable()
//                    .scaledToFill()
//                    .frame(width: width, height: 160)
//                    .cornerRadius(cornerRadius)
//                    .clipped()
//                    .overlay(
//                        VStack(alignment: .leading) {
//                            HStack {
//                                Spacer()
//                                if post.repost {
//                                    Image(systemName: "arrow.2.squarepath")
//                                        .foregroundStyle(.white)
//                                        .font(.custom("MuseoSansRounded-300", size: 16))
//                                }
//                            }
//                            Spacer()
//                        }
//                    )
//            } else {
//                VStack {
//                    if let profileImageUrl = post.restaurant.profileImageUrl {
//                        RestaurantCircularProfileImageView(imageUrl: profileImageUrl, size: .large)
//                    }
//                    if !post.caption.isEmpty {
//                        Image(systemName: "line.3.horizontal")
//                            .resizable()
//                            .foregroundStyle(.gray)
//                            .aspectRatio(contentMode: .fit)
//                            .frame(width: 45, height: 15)
//                    }
//                }
//                .frame(width: width, height: 160)
//                .background(Color.gray.opacity(0.2))
//                .cornerRadius(cornerRadius)
//                .clipped()
//            }
//            
//            VStack(alignment: .leading) {
//                HStack {
//                    
//                    HStack(spacing: 1) {
//                        
//                        
//                        Text("@\(post.user.username)")
//                            .lineLimit(2)
//                            .truncationMode(.tail)
//                            .foregroundColor(.white)
//                            .font(.custom("MuseoSansRounded-300", size: 10))
//                            .bold()
//                            .shadow(color: .black, radius: 2, x: 0, y: 1)
//                            .multilineTextAlignment(.leading)
//                            .minimumScaleFactor(0.5)
//                    }
//                    
//                    Spacer()
//                    HStack(spacing: 1) {
//                        Image(systemName: "heart")
//                            .font(.footnote)
//                            .foregroundColor(.white)
//                            .shadow(color: .black, radius: 2, x: 0, y: 1)
//                        Text("\(post.likes)")
//                            .font(.custom("MuseoSansRounded-300", size: 10))
//                            .bold()
//                            .foregroundColor(.white)
//                            .shadow(color: .black, radius: 2, x: 0, y: 1)
//                    }
//                }
//                Spacer()
//                HStack(alignment: .bottom) {
//                    if showNames {
//                        Text("\(post.restaurant.name)")
//                            .lineLimit(2)
//                            .truncationMode(.tail)
//                            .foregroundColor(.white)
//                            .font(.custom("MuseoSansRounded-300", size: 10))
//                            .bold()
//                            .shadow(color: .black, radius: 2, x: 0, y: 1)
//                            .multilineTextAlignment(.leading)
//                            .minimumScaleFactor(0.5)
//                    }
//                    
//                    Spacer()
//                    if let rating = post.overallRating{
//                        let formatted =  String(format: "%.1f", rating)
//                        Text("\(formatted)")
//                            .lineLimit(2)
//                            .truncationMode(.tail)
//                            .foregroundColor(.white)
//                            .font(.custom("MuseoSansRounded-300", size: 10))
//                            .bold()
//                            .shadow(color: .black, radius: 2, x: 0, y: 1)
//                            .multilineTextAlignment(.leading)
//                            .minimumScaleFactor(0.5)
//                    }
//                }
//            }
//            .padding(4)
//        }
//    }
//}

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


//
//  ActivityView.swift
//  Foodi
//
//  Created by Jack Robinson on 4/19/24.
//

import SwiftUI
import FirebaseAuth
import GeoFire
enum LetsKetchupOptions {
    case friends, trending
}
struct ActivityView: View {
    @StateObject private var viewModel = ActivityViewModel()
    @StateObject private var leaderboardViewModel = LeaderboardViewModel()
    @State private var isLoading = true
    @State private var showSearchView = false
    @State private var showContacts = false
    @State private var shouldShowExistingUsersOnContacts = false
    @State private var selectedLeaderboardType: LeaderboardType?
    @State private var selectedRestaurantLeaderboardType: RestaurantLeaderboardType?
    @State private var topUSAPost: [Post]?
    @State private var stateTopPost: [Post]?
    @State private var cityTopPost: [Post]?
    @State private var topUSARestaurant: [Restaurant]?
    @State private var stateTopRestaurant: [Restaurant]?
    @State private var cityTopRestaurant: [Restaurant]?
    @State private var showLocationSearch = false
    @State private var city: String?
    @State private var surroundingGeohash: String?
    @State private var surroundingTopPost: [Post]?
    @State private var surroundingTopRestaurant: [Restaurant]?
    @State private var state: String?
    @State private var surroundingCounty: String = "Nearby"

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    loadingView
                } else {
                    mainContentView
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(){
                        toolbarLogoView
                        Spacer()
                        locationButton
                            
                    }.padding(.horizontal)
                }
                
            }
            .refreshable { await refreshData() }
            .sheet(isPresented: $showSearchView) { SearchView(initialSearchConfig: .users) }
            .sheet(isPresented: $showContacts) { ContactsView(shouldFetchExistingUsers: shouldShowExistingUsersOnContacts) }
            .sheet(item: $viewModel.post) { postView(for: $0) }
            .sheet(item: $viewModel.collection) { collectionView(for: $0) }
            .sheet(isPresented: $viewModel.showRestaurant) { restaurantView }
            .sheet(isPresented: $viewModel.showUserProfile) { userProfileView }
            .sheet(item: $viewModel.writtenPost) { writtenPostView(for: $0) }
            .fullScreenCover(item: $selectedLeaderboardType) { postLeaderboardView(for: $0) }
            .fullScreenCover(item: $selectedRestaurantLeaderboardType) { restaurantLeaderboardView(for: $0) }
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
        }
        .onAppear {
            city = AuthService.shared.userSession?.location?.city
            if let geoPoint = AuthService.shared.userSession?.location?.geoPoint {
                surroundingGeohash = GFUtils.geoHash(forLocation: CLLocationCoordinate2D(latitude: geoPoint.latitude, longitude: geoPoint.longitude))
                reverseGeocodeLocation(latitude: geoPoint.latitude, longitude: geoPoint.longitude)

            }
            
            state = AuthService.shared.userSession?.location?.state
        }
    }
    
    private var loadingView: some View {
        FastCrossfadeFoodImageView()
            .onAppear { Task { await loadInitialData() } }
    }
    private var locationButton: some View {
        Button(action: {
            showLocationSearch = true
        }) {
            HStack(spacing:1) {
                Image(systemName: "location")
                    .foregroundStyle(.gray)
                    .font(.caption)
                Text(city != nil && state != nil ? "\(city!), \(state!)" : "Set Location")
                    .font(.custom("MuseoSansRounded-300", size: 16))
                    .foregroundStyle(.gray)
                   
                Image(systemName: "chevron.down")
                    .foregroundStyle(.gray)
                    .font(.caption)
            }
            .lineLimit(2)
            .minimumScaleFactor(0.5)
            
        }
    }
    
    
    private var mainContentView: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading) {
                //                PollView(poll: Poll.createNewPoll(
                //                    question: "What's your favorite color?",
                //                    options: ["Red", "Blue", "Green", "Yellow"],
                //                    imageUrl: "https://picsum.photos/200/300"
                //                ))
                mostPostedRestaurantsSection
                mostLikedPostsSection
                if let user = viewModel.user, user.hasContactsSynced, viewModel.isContactPermissionGranted {
                    contactsSection
                }
                inviteContactsButton
                
            }
        }
    }
    
    private var toolbarLogoView: some View {
        Image("KetchupTextRed")
            .resizable()
            .scaledToFit()
            .frame(width: 100)
    }
    
    private var inviteContactsButton: some View {
        Button {
            shouldShowExistingUsersOnContacts = false
            showContacts = true
        } label: {
            InviteContactsButton()
        }
    }
    
    private var mostPostedRestaurantsSection: some View {
           VStack(alignment: .leading) {
               sectionTitle("Most Posted Restaurants")
                   .padding(.horizontal)
               ScrollView(.horizontal, showsIndicators: false) {
                   HStack {
                       if cityTopRestaurant?.isEmpty == false {
                           restaurantLeaderboardButton(for: .city)
                       }
                       if surroundingTopRestaurant?.isEmpty == false {
                           restaurantLeaderboardButton(for: .surrounding)
                       }
                       if stateTopRestaurant?.isEmpty == false {
                           restaurantLeaderboardButton(for: .state)
                       }
                       if topUSARestaurant?.isEmpty == false {
                           restaurantLeaderboardButton(for: .usa)
                       }
                   }
                   .padding(.horizontal)
               }
           }
       }
    
    private var mostLikedPostsSection: some View {
           VStack(alignment: .leading) {
               sectionTitle("Most Liked Posts")
                   .padding(.horizontal)
               ScrollView(.horizontal, showsIndicators: false) {
                   HStack {
                       if let city = city, cityTopPost?.isEmpty == false {
                           leaderboardButton(for: .city(city), posts: cityTopPost)
                       }
                       if let surrounding = surroundingGeohash, surroundingTopPost?.isEmpty == false {
                           leaderboardButton(for: .surrounding(surrounding), posts: surroundingTopPost)
                       }
                       if let state = state, stateTopPost?.isEmpty == false {
                           leaderboardButton(for: .state(state), posts: stateTopPost)
                       }
                       if topUSAPost?.isEmpty == false {
                           leaderboardButton(for: .usa, posts: topUSAPost)
                       }
                   }
                   .padding(.horizontal)
               }
           }
       }
    
    private var contactsSection: some View {
        VStack(alignment: .leading) {
            HStack {
                sectionTitle("Friends on Ketchup")
                Spacer()
                seeAllButton
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
                    loadMoreContactsIndicator
                    seeAllContactsButton
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical)
    }
    
    
    
    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.custom("MuseoSansRounded-700", size: 25))
            .foregroundColor(.black)
    }
    
    private var seeAllButton: some View {
        Button(action: {
            shouldShowExistingUsersOnContacts = true
            showContacts = true
        }) {
            Text("See All")
                .font(.custom("MuseoSansRounded-300", size: 12))
                .foregroundStyle(.gray)
        }
    }
    
    private var loadMoreContactsIndicator: some View {
        Group {
            if viewModel.isLoadingMore {
                ProgressView()
                    .frame(width: 50, height: 50)
            }
            if viewModel.hasMoreContacts {
                Color.clear
                    .frame(width: 1, height: 1)
                    .onAppear { viewModel.loadMoreContacts() }
            }
        }
    }
    
    private var seeAllContactsButton: some View {
        Button(action: { showContacts = true }) {
            Text("See All")
                .font(.custom("MuseoSansRounded-300", size: 14))
                .foregroundColor(.white)
                .padding(.vertical, 8)
                .padding(.horizontal, 16)
                .background(Color("Colors/AccentColor"))
                .cornerRadius(20)
        }
    }
    
    private var searchButton: some View {
        Button {
            showSearchView.toggle()
        } label: {
            VStack {
                Image(systemName: "magnifyingglass")
                    .resizable()
                    .scaledToFit()
                Text("Search Users")
                    .font(.custom("MuseoSansRounded-300", size: 12))
            }
            .frame(height: 40)
            .foregroundStyle(.gray)
        }
    }
    
    private var activityList: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(alignment: .top, spacing: 16) {
                ForEach(viewModel.followingActivity) { activity in
                    ActivityCell(activity: activity, viewModel: viewModel)
                        .onAppear {
                            if activity == viewModel.followingActivity.last {
                                viewModel.loadMore()
                            }
                        }
                }
                if viewModel.isLoadingMore {
                    FastCrossfadeFoodImageView()
                }
            }
            .padding(.horizontal)
        }
    }
    
    private func leaderboardButton(for type: LeaderboardType, posts: [Post]?) -> some View {
           Button {
               selectedLeaderboardType = type
           } label: {
               LeaderboardCover(
                   imageUrl: posts?.first?.thumbnailUrl,
                   title: leaderboardTitle(for: type)
               )
           }
       }
    
    private func restaurantLeaderboardButton(for type: RestaurantLeaderboardType) -> some View {
            Button {
                selectedRestaurantLeaderboardType = type
            } label: {
                LeaderboardCover(
                    imageUrl: restaurantImageForLeaderboard(type),
                    title: leaderboardTitle(for: type)
                )
            }
        }
    
    private func leaderboardTitle(for type: LeaderboardType) -> String {
            switch type {
            case .usa: return "USA"
            case .state(let state): return StateNameConverter.fullName(for: state)
            case .city(let city): return city
            case .surrounding: return surroundingCounty
            }
        }
    
    private func leaderboardTitle(for type: RestaurantLeaderboardType) -> String {
            switch type {
            case .usa: return "USA"
            case .state: return state ?? ""
            case .city: return city ?? ""
            case .surrounding: return surroundingCounty
            }
        }
    
    private func postLeaderboardView(for type: LeaderboardType) -> some View {
        PostLeaderboard(
            viewModel: leaderboardViewModel,
            topImage: topImageForLeaderboard(type),
            title: leaderboardTitle(for: type),
            state: stateForLeaderboard(type),
            city: cityForLeaderboard(type),
            surrounding: surroundingForLeaderboard(type)
        )
    }
    
    private func restaurantLeaderboardView(for type: RestaurantLeaderboardType) -> some View {
        RestaurantLeaderboard(
            viewModel: leaderboardViewModel,
            topImage: restaurantImageForLeaderboard(type),
            title: leaderboardTitle(for: type),
            state: type == .state ? state : nil,
            city: type == .city ? city : nil,
            surrounding: type == .surrounding ? surroundingGeohash : nil
        )
    }
    
    private func topImageForLeaderboard(_ type: LeaderboardType) -> String? {
        switch type {
        case .usa: return topUSAPost?.first?.thumbnailUrl
        case .state: return stateTopPost?.first?.thumbnailUrl
        case .city: return cityTopPost?.first?.thumbnailUrl
        case .surrounding: return surroundingTopPost?.first?.thumbnailUrl
        }
    }
    
    private func restaurantImageForLeaderboard(_ type: RestaurantLeaderboardType) -> String? {
        switch type {
        case .usa: return topUSARestaurant?.first?.profileImageUrl
        case .state: return stateTopRestaurant?.first?.profileImageUrl
        case .city: return cityTopRestaurant?.first?.profileImageUrl
        case .surrounding: return surroundingTopRestaurant?.first?.profileImageUrl
        }
    }
    
    private func stateForLeaderboard(_ type: LeaderboardType) -> String? {
        if case .state(let state) = type { return state }
        return nil
    }
    
    private func cityForLeaderboard(_ type: LeaderboardType) -> String? {
        if case .city(let city) = type { return city }
        return nil
    }
    private func surroundingForLeaderboard(_ type: LeaderboardType) -> String? {
        if case .surrounding(let surrounding) = type { return surrounding}
        return nil
    }
    
    private func postView(for post: Post) -> some View {
        NavigationStack {
            let feedViewModel = FeedViewModel(posts: [post])
            SecondaryFeedView(viewModel: feedViewModel, hideFeedOptions: true, checkLikes: true)
        }
    }
    
    private func collectionView(for collection: Collection) -> some View {
        CollectionView(collectionsViewModel: viewModel.collectionsViewModel)
    }
    
    private var restaurantView: some View {
        NavigationStack {
            if let selectedRestaurantId = viewModel.selectedRestaurantId {
                RestaurantProfileView(restaurantId: selectedRestaurantId)
            }
        }
    }
    
    private var userProfileView: some View {
        NavigationStack {
            if let selectedUid = viewModel.selectedUid {
                ProfileView(uid: selectedUid)
                    .navigationDestination(for: PostUser.self) { user in
                        ProfileView(uid: user.id)
                    }
                    .navigationDestination(for: PostRestaurant.self) { restaurant in
                        RestaurantProfileView(restaurantId: restaurant.id)
                    }
            }
        }
    }
    
    private func writtenPostView(for post: Post) -> some View {
        NavigationStack {
            ScrollView {
                let feedViewModel = FeedViewModel(posts: [post])
                WrittenFeedCell(viewModel: feedViewModel, post: .constant(post), scrollPosition: .constant(nil), pauseVideo: .constant(false), selectedPost: .constant(nil), checkLikes: true)
            }
            .modifier(BackButtonModifier())
            .navigationDestination(for: PostRestaurant.self) { restaurant in
                RestaurantProfileView(restaurantId: restaurant.id)
            }
        }
        .presentationDetents([.height(UIScreen.main.bounds.height * 0.8)])
    }
    
    private func loadInitialData() async {
        viewModel.user = AuthService.shared.userSession
        viewModel.checkContactPermission()
        
        async let contacts: () = viewModel.fetchTopContacts()
        async let usaPosts: () = fetchTopPosts(count: 1)
        async let statePosts: () = fetchTopPosts(count: 1, state: state)
        async let cityPosts: () = fetchTopPosts(count: 1, city: city)
        async let surroundingPosts: () = fetchTopPosts(count: 1, geohash: surroundingGeohash)
        async let usaRestaurants: () = fetchTopRestaurants(count: 1)
        async let stateRestaurants: () = fetchTopRestaurants(count: 1, state: state)
        async let cityRestaurants: () = fetchTopRestaurants(count: 1, city: city)
        async let surroundingRestaurants: () = fetchTopRestaurants(count: 1, geohash: surroundingGeohash)
        
        do {
            try await ( _, _, _, _, _, _, _, _, _) = (contacts, usaPosts, statePosts, cityPosts, surroundingPosts, usaRestaurants, stateRestaurants, cityRestaurants, surroundingRestaurants)
            isLoading = false
        } catch {
            print("Error loading initial data: \(error.localizedDescription)")
            isLoading = false
        }
    }
    
    private func refreshData() async {
        viewModel.checkContactPermission()
        viewModel.resetContactsPagination()
        
        async let contacts: () = viewModel.fetchTopContacts()
        async let usaPosts: () = fetchTopPosts(count: 1)
        async let statePosts: () = fetchTopPosts(count: 1, state: state)
        async let cityPosts: () = fetchTopPosts(count: 1, city: city)
        async let surroundingPosts: () = fetchTopPosts(count: 1, geohash: surroundingGeohash)
        async let usaRestaurants: () = fetchTopRestaurants(count: 1)
        async let stateRestaurants: () = fetchTopRestaurants(count: 1, state: state)
        async let cityRestaurants: () = fetchTopRestaurants(count: 1, city: city)
        async let surroundingRestaurants: () = fetchTopRestaurants(count: 1, geohash: surroundingGeohash)
        
        do {
            try await (_, _, _, _, _, _, _, _, _) = (contacts, usaPosts, statePosts, cityPosts, surroundingPosts, usaRestaurants, stateRestaurants, cityRestaurants, surroundingRestaurants)
        } catch {
            print("Error refreshing data: \(error.localizedDescription)")
        }
    }

    
    private func refreshLocationData() async {
        async let usaPosts: () = fetchTopPosts(count: 1)
        async let statePosts: () = fetchTopPosts(count: 1, state: state)
        async let cityPosts: () = fetchTopPosts(count: 1, city: city)
        async let surroundingPosts: () = fetchTopPosts(count: 1, geohash: surroundingGeohash)
        async let usaRestaurants: () = fetchTopRestaurants(count: 1)
        async let stateRestaurants: () = fetchTopRestaurants(count: 1, state: state)
        async let cityRestaurants: () = fetchTopRestaurants(count: 1, city: city)
        async let surroundingRestaurants: () = fetchTopRestaurants(count: 1, geohash: surroundingGeohash)
        
        //do {
            try await ( _, _, _, _, _, _, _, _) = (usaPosts, statePosts, cityPosts, surroundingPosts, usaRestaurants, stateRestaurants, cityRestaurants, surroundingRestaurants)
//        } catch {
//            print("Error refreshing data: \(error.localizedDescription)")
//        }
    }
    private func fetchTopPosts(count: Int, state: String? = nil, city: String? = nil, geohash: String? = nil) async {
            do {
                let posts = try await leaderboardViewModel.fetchTopPosts(count: count, state: state, city: city, geohash: geohash)
                if state == nil && city == nil && geohash == nil {
                    topUSAPost = posts.isEmpty ? nil : posts
                } else if city == nil && geohash == nil {
                    stateTopPost = posts.isEmpty ? nil : posts
                } else if geohash == nil {
                    cityTopPost = posts.isEmpty ? nil : posts
                } else {
                    surroundingTopPost = posts.isEmpty ? nil : posts
                }
            } catch {
                print("Error fetching top posts: \(error.localizedDescription)")
            }
        }
    
    private func fetchTopRestaurants(count: Int, state: String? = nil, city: String? = nil, geohash: String? = nil) async {
           do {
               let restaurants = try await leaderboardViewModel.fetchTopRestaurants(count: count, state: state, city: city, geohash: geohash)
               if state == nil && city == nil && geohash == nil {
                   topUSARestaurant = restaurants.isEmpty ? nil : restaurants
               } else if city == nil && geohash == nil {
                   stateTopRestaurant = restaurants.isEmpty ? nil : restaurants
               } else if geohash == nil {
                   cityTopRestaurant = restaurants.isEmpty ? nil : restaurants
               } else {
                   surroundingTopRestaurant = restaurants.isEmpty ? nil : restaurants
               }
           } catch {
               print("Error fetching top restaurants: \(error.localizedDescription)")
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
                
                if let placemark = placemarks?.first {
                    if let county = placemark.subAdministrativeArea {
                        DispatchQueue.main.async {
                            self.surroundingCounty = county
                        }
                    } else {
                        print("County information not available")
                    }
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

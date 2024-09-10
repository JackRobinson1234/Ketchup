//
//  ActivityView.swift
//  Foodi
//
//  Created by Jack Robinson on 4/19/24.
//

import SwiftUI
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
    @State private var state: String?
    
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
                    VStack(spacing: 2){
                        toolbarLogoView
                        locationButton
                            .padding(.bottom,2)
                    }}
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
                LocationSearchView(city: $city, state: $state, onLocationSelected: {
                    Task {
                        await refreshData()
                    }
                })
                .presentationDetents([.height(UIScreen.main.bounds.height * 0.5)])
            }
        }
        .onAppear {
            city = AuthService.shared.userSession?.location?.city
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
        }
    }
    
    private var mainContentView: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading) {
                
                inviteContactsButton
                mostPostedRestaurantsSection
                mostLikedPostsSection
                if let user = viewModel.user, user.hasContactsSynced, viewModel.isContactPermissionGranted {
                    contactsSection
                }
//                HorizontalCollectionScrollView()
//                    .padding(.bottom)
               // activityListSection
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
    
//    private var activityListSection: some View {
//        VStack(alignment: .leading) {
//            HStack(alignment: .top) {
//                sectionTitle("Following Activity")
//                Spacer()
//                searchButton
//            }
//            .padding(.horizontal)
//            
//            if !viewModel.followingActivity.isEmpty {
//                activityList
//            } else if viewModel.isFetching {
//                FastCrossfadeFoodImageView()
//            } else {
//                Text("No activity from your friends yet.")
//                    .font(.custom("MuseoSansRounded-300", size: 16))
//                    .foregroundColor(.gray)
//                    .padding()
//            }
//        }
//    }
    
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
        }
    }
    
    private func leaderboardTitle(for type: RestaurantLeaderboardType) -> String {
        switch type {
        case .usa: return "USA"
        case .state: return state ?? ""
        case .city: return city ?? ""
        }
    }
    
    private func postLeaderboardView(for type: LeaderboardType) -> some View {
        PostLeaderboard(
            viewModel: leaderboardViewModel,
            topImage: topImageForLeaderboard(type),
            title: leaderboardTitle(for: type),
            state: stateForLeaderboard(type),
            city: cityForLeaderboard(type)
        )
    }
    
    private func restaurantLeaderboardView(for type: RestaurantLeaderboardType) -> some View {
        RestaurantLeaderboard(
            viewModel: leaderboardViewModel,
            topImage: restaurantImageForLeaderboard(type),
            title: leaderboardTitle(for: type),
            state: type == .state ? state : nil,
            city: type == .city ? city : nil
        )
    }
    
    private func topImageForLeaderboard(_ type: LeaderboardType) -> String? {
        switch type {
        case .usa: return topUSAPost?.first?.thumbnailUrl
        case .state: return stateTopPost?.first?.thumbnailUrl
        case .city: return cityTopPost?.first?.thumbnailUrl
        }
    }
    
    private func restaurantImageForLeaderboard(_ type: RestaurantLeaderboardType) -> String? {
        switch type {
        case .usa: return topUSARestaurant?.first?.profileImageUrl
        case .state: return stateTopRestaurant?.first?.profileImageUrl
        case .city: return cityTopRestaurant?.first?.profileImageUrl
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
        async let usaRestaurants: () = fetchTopRestaurants(count: 1)
        async let stateRestaurants: () = fetchTopRestaurants(count: 1, state: state)
        async let cityRestaurants: () = fetchTopRestaurants(count: 1, city: city)
        
        do {
            try await ( _, _, _, _, _, _, _) = (contacts, usaPosts, statePosts, cityPosts, usaRestaurants, stateRestaurants, cityRestaurants)
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
        async let usaRestaurants: () = fetchTopRestaurants(count: 1)
        async let stateRestaurants: () = fetchTopRestaurants(count: 1, state: state)
        async let cityRestaurants: () = fetchTopRestaurants(count: 1, city: city)
        
        do {
            try await (_, _, _, _, _, _, _) = (contacts, usaPosts, statePosts, cityPosts, usaRestaurants, stateRestaurants, cityRestaurants)
        } catch {
            print("Error refreshing data: \(error.localizedDescription)")
        }
    }
    private func refreshLocationData() async {
       
        async let contacts: () = viewModel.fetchTopContacts()
        async let usaPosts: () = fetchTopPosts(count: 1)
        async let statePosts: () = fetchTopPosts(count: 1, state: state)
        async let cityPosts: () = fetchTopPosts(count: 1, city: city)
        async let usaRestaurants: () = fetchTopRestaurants(count: 1)
        async let stateRestaurants: () = fetchTopRestaurants(count: 1, state: state)
        async let cityRestaurants: () = fetchTopRestaurants(count: 1, city: city)
        
        do {
            try await (_, _, _, _, _, _, _) = (contacts, usaPosts, statePosts, cityPosts, usaRestaurants, stateRestaurants, cityRestaurants)
        } catch {
            print("Error refreshing data: \(error.localizedDescription)")
        }
    }
    private func fetchTopPosts(count: Int, state: String? = nil, city: String? = nil) async {
        do {
            let posts = try await leaderboardViewModel.fetchTopPosts(count: count, state: state, city: city)
            if state == nil && city == nil {
                topUSAPost = posts.isEmpty ? nil : posts
            } else if city == nil {
                stateTopPost = posts.isEmpty ? nil : posts
            } else {
                cityTopPost = posts.isEmpty ? nil : posts
            }
        } catch {
            print("Error fetching top posts: \(error.localizedDescription)")
        }
    }
    
    private func fetchTopRestaurants(count: Int, state: String? = nil, city: String? = nil) async {
        do {
            let restaurants = try await leaderboardViewModel.fetchTopRestaurants(count: count, state: state, city: city)
            if state == nil && city == nil {
                topUSARestaurant = restaurants.isEmpty ? nil : restaurants
            } else if city == nil {
                stateTopRestaurant = restaurants.isEmpty ? nil : restaurants
            } else {
                cityTopRestaurant = restaurants.isEmpty ? nil : restaurants
            }
        } catch {
            print("Error fetching top restaurants: \(error.localizedDescription)")
        }
    }
}

enum LeaderboardType: Identifiable {
    case usa
    case state(String)
    case city(String)
    
    var id: String {
        switch self {
        case .usa: return "usa"
        case .state(let state): return "state_\(state)"
        case .city(let city): return "city_\(city)"
        }
    }
}

enum RestaurantLeaderboardType: Identifiable {
    case usa
    case state
    case city
    
    var id: String {
        switch self {
        case .usa: return "usa"
        case .state: return "state"
        case .city: return "city"
        }
    }
}

struct ActivityContactRow: View {
    @ObservedObject var viewModel: ActivityViewModel
    @State var contact: Contact
    @State private var isFollowed: Bool
    @State private var isCheckingFollowStatus: Bool = false
    @State private var hasCheckedFollowStatus: Bool = false
    @State private var isShowingProfile: Bool = false
    
    init(viewModel: ActivityViewModel, contact: Contact) {
        self.viewModel = viewModel
        self._contact = State(initialValue: contact)
        self._isFollowed = State(initialValue: contact.isFollowed ?? false)
    }
    
    var body: some View {
        HStack(spacing: 12) {
            profileImageButton
            userInfoView
            Spacer()
            followStatusView
        }
        .padding(.vertical, 8)
        .onAppear(perform: checkFollowStatus)
    }
    
    private var profileImageButton: some View {
        Button(action: { isShowingProfile = true }) {
            UserCircularProfileImageView(profileImageUrl: contact.user?.profileImageUrl, size: .small)
        }
        .fullScreenCover(isPresented: $isShowingProfile) {
            if let userId = contact.user?.id {
                NavigationStack {
                    ProfileView(uid: userId)
                }
            }
        }
    }
    
    private var userInfoView: some View {
        VStack(alignment: .leading, spacing: 2) {
            Button(action: { isShowingProfile = true }) {
                Text(contact.user?.fullname ?? contact.deviceContactName ?? contact.phoneNumber)
                    .font(.custom("MuseoSansRounded-500", size: 16))
                    .foregroundStyle(.black)
            }
            
            if let username = contact.user?.username {
                Text("@\(username)")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }
        }
    }
    
    private var followStatusView: some View {
        Group {
            if isCheckingFollowStatus {
                ProgressView()
                    .scaleEffect(0.7)
            } else {
                followButton
            }
        }
    }
    
    private var followButton: some View {
        Button(action: handleFollowAction) {
            Text(isFollowed ? "Following" : "Follow")
                .font(.custom("MuseoSansRounded-300", size: 16))
                .fontWeight(.semibold)
                .frame(width: 110)
                .padding(.vertical, 8)
                .foregroundColor(isFollowed ? Color("Colors/AccentColor") : .white)
                .background(isFollowed ? Color.clear : Color.red)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color("Colors/AccentColor"), lineWidth: isFollowed ? 1 : 0)
                )
        }
    }
    
    private func checkFollowStatus() {
        guard let userId = contact.user?.id, !hasCheckedFollowStatus else { return }
        
        isCheckingFollowStatus = true
        Task {
            do {
                isFollowed = try await viewModel.checkIfUserIsFollowed(contact: contact)
                isCheckingFollowStatus = false
                hasCheckedFollowStatus = true
            } catch {
                print("Error checking follow status: \(error.localizedDescription)")
                isCheckingFollowStatus = false
            }
        }
    }
    
    private func handleFollowAction() {
        guard let userId = contact.user?.id else { return }
        Task {
            do {
                if isFollowed {
                    try await viewModel.unfollow(userId: userId)
                } else {
                    try await viewModel.follow(userId: userId)
                }
                isFollowed.toggle()
                viewModel.updateContactFollowStatus(contact: contact, isFollowed: isFollowed)
            } catch {
                print("Failed to follow/unfollow: \(error.localizedDescription)")
            }
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

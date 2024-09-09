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
    @State var isLoading = true
    @State var isTransitioning = false
    @StateObject var viewModel = ActivityViewModel()
    @State var showSearchView: Bool = false
    @State var showContacts: Bool = false
    @Namespace private var animation
    @State var shouldShowExistingUsersOnContacts: Bool = false
    @StateObject var leaderboardViewModel = LeaderboardViewModel()
    @State var showPostLeaderboard = false
    @State var topUSAPost: [Post]? = nil
    @State var stateTopPost: [Post]? = nil
    @State var showStatePostLeaderboard = false
    @State var cityTopPost: [Post]? = nil
    @State var showCityPostLeaderboard = false
    @State var state: String? = AuthService.shared.userSession?.location?.state
    @State var city: String? = AuthService.shared.userSession?.location?.city
    @State var showRestaurantLeaderboard = false
    @State var topUSARestaurant: [Restaurant]? = nil
    @State var stateTopRestaurant: [Restaurant]? = nil
    @State var showStateRestaurantLeaderboard = false
    @State var cityTopRestaurant: [Restaurant]? = nil
    @State var showCityRestaurantLeaderboard = false
    var body: some View {
        NavigationStack {
            VStack {
                if isLoading {
                    FastCrossfadeFoodImageView()
                        .onAppear {
                            Task {
                                viewModel.user = AuthService.shared.userSession
                                viewModel.checkContactPermission()
                                try? await viewModel.fetchInitialActivities()
                                try? await viewModel.fetchTopContacts()
                                topUSAPost = try await leaderboardViewModel.fetchTopPosts(count: 1)
                                
                                if let state = AuthService.shared.userSession?.location?.state {
                                    stateTopPost = try await leaderboardViewModel.fetchTopPosts(count: 1, state: state)
                                }
                                if let city = AuthService.shared.userSession?.location?.city {
                                    stateTopPost = try await leaderboardViewModel.fetchTopPosts(count: 1, city: city)
                                }
                                topUSARestaurant = try await leaderboardViewModel.fetchTopRestaurants(count: 1)
                                if let state = AuthService.shared.userSession?.location?.state {
                                    stateTopRestaurant = try await leaderboardViewModel.fetchTopRestaurants(count: 1, state: state)
                                }
                                if let city = AuthService.shared.userSession?.location?.city {
                                    cityTopRestaurant = try await leaderboardViewModel.fetchTopRestaurants(count: 1, city: city)
                                }
                                isLoading = false
                                
                            }
                        }
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading){
                            Button{
                                shouldShowExistingUsersOnContacts = false
                                showContacts = true
                            } label: {
                                InviteContactsButton()
                            }
                            Text("Top Restaurants")
                                .font(.custom("MuseoSansRounded-700", size: 25))
                                .foregroundColor(.black)
                                .padding(.horizontal)
                                .padding(.top)
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack {
                                    Button {
                                        showCityRestaurantLeaderboard = true
                                    } label: {
                                        if let city = city {
                                            if let firstRestaurant = cityTopRestaurant?.first {
                                                LeaderboardCover(imageUrl: firstRestaurant.profileImageUrl, title: city)
                                            } else {
                                                LeaderboardCover(imageUrl: nil, title: city)
                                            }
                                        }
                                    }
                                    Button {
                                        showStateRestaurantLeaderboard = true
                                    } label: {
                                        if let state = AuthService.shared.userSession?.location?.state {
                                            if let firstRestaurant = stateTopRestaurant?.first {
                                                LeaderboardCover(imageUrl: firstRestaurant.profileImageUrl, title: state)
                                            } else {
                                                LeaderboardCover(imageUrl: nil, title: state)
                                            }
                                        }
                                    }
                                    Button {
                                        showRestaurantLeaderboard = true
                                    } label: {
                                        if let firstRestaurant = topUSARestaurant?.first {
                                            LeaderboardCover(imageUrl: firstRestaurant.profileImageUrl, title: "USA")
                                        } else {
                                            LeaderboardCover(imageUrl: nil, title: "Top USA Restaurants")
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                            Text("Trending Posts")
                                .font(.custom("MuseoSansRounded-700", size: 25))
                                .foregroundColor(.black)
                                .padding(.horizontal)
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack{
                                    Button{
                                        showCityPostLeaderboard = true
                                    } label: {
                                        if let city = city {
                                            if let firstPost = stateTopPost?.first{
                                                LeaderboardCover(imageUrl: firstPost.thumbnailUrl, title: city)
                                            } else {
                                                LeaderboardCover(imageUrl: nil, title: city)
                                            }
                                        }
                                        
                                    }
                                    Button{
                                        showStatePostLeaderboard = true
                                    } label: {
                                        if let state = AuthService.shared.userSession?.location?.state {
                                            if let firstPost = stateTopPost?.first{
                                                LeaderboardCover(imageUrl: firstPost.thumbnailUrl, title: state)
                                            } else {
                                                LeaderboardCover(imageUrl: nil, title: state)
                                            }
                                        }
                                        
                                    }
                                    Button{
                                        showPostLeaderboard = true
                                    } label: {
                                        if let firstPost = topUSAPost?.first{
                                            LeaderboardCover(imageUrl: firstPost.thumbnailUrl, title: "USA")
                                        } else {
                                            LeaderboardCover(imageUrl: nil, title: "Global Posts")
                                        }
                                        
                                    }
                                }
                                .padding(.horizontal)
                            }
                            // MARK: Contacts Section
                            if let user = viewModel.user, user.hasContactsSynced, viewModel.isContactPermissionGranted {
                                contactsSection
                            }
                            
                            HorizontalCollectionScrollView()
                                .padding(.bottom)
                            
                            // MARK: Activity List
                            activityListSection
                        }
                    }
                    .toolbar {
                        ToolbarItem(placement: .principal) {
                            Image("KetchupTextRed") // Replace with your image name
                                .resizable()
                                .scaledToFit()
                                .frame(width: 100)
                        }
                    }
                    .refreshable {
                        Task {
                            viewModel.checkContactPermission()
                            viewModel.resetContactsPagination()
                            try? await viewModel.fetchInitialActivities()
                            try? await viewModel.fetchTopContacts()
                            
                        }
                    }
                    .fullScreenCover(isPresented: $showSearchView) {
                        SearchView(initialSearchConfig: .users)
                    }
                    .sheet(isPresented: $showContacts) {
                        ContactsView(shouldFetchExistingUsers: shouldShowExistingUsersOnContacts)
                    }
                    .sheet(item: $viewModel.post){ post in
                        NavigationStack{
                            if let post = viewModel.post {
                                let feedViewModel = FeedViewModel(posts: [post])
                                SecondaryFeedView(viewModel: feedViewModel, hideFeedOptions: true, checkLikes: true)
                            }
                        }
                    }
                    .sheet(item: $viewModel.collection) { collection in
                        if let collection = viewModel.collection, let user = viewModel.user {
                            CollectionView(collectionsViewModel: viewModel.collectionsViewModel)
                        }
                    }
                    .sheet(isPresented: $viewModel.showRestaurant){
                        if let selectedRestaurantId = viewModel.selectedRestaurantId {
                            NavigationStack{
                                RestaurantProfileView(restaurantId: selectedRestaurantId)
                            }
                        }
                    }
                    .sheet(isPresented: $viewModel.showUserProfile) {
                        if let selectedUid = viewModel.selectedUid {
                            NavigationStack{
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
                    .sheet(item: $viewModel.writtenPost) { post in
                        NavigationStack {
                            ScrollView {
                                if let post = viewModel.writtenPost {
                                    let feedViewModel = FeedViewModel(posts: [post])
                                    WrittenFeedCell(viewModel: feedViewModel, post: .constant(post), scrollPosition: .constant(nil), pauseVideo: .constant(false), selectedPost: .constant(nil), checkLikes: true)
                                }
                            }
                            .modifier(BackButtonModifier())
                            .navigationDestination(for: PostRestaurant.self) { restaurant in
                                RestaurantProfileView(restaurantId: restaurant.id)
                            }
                        }
                        .presentationDetents([.height(UIScreen.main.bounds.height * 0.8)])
                    }
                    .navigationDestination(for: Activity.self) {activity in
                        if let id = activity.restaurantId{
                            RestaurantProfileView(restaurantId: id)
                        }
                    }
                    .fullScreenCover(isPresented: $showPostLeaderboard) {
                        PostLeaderboard(viewModel: leaderboardViewModel, topImage: topUSAPost?.first?.thumbnailUrl, title: "USA")
                    }
                    .fullScreenCover(isPresented: $showStatePostLeaderboard) {
                        if let state {
                            PostLeaderboard(viewModel: leaderboardViewModel, topImage: stateTopPost?.first?.thumbnailUrl, title: state, state: state)
                        }
                    }
                    .fullScreenCover(isPresented: $showCityPostLeaderboard) {
                        if let city {
                            PostLeaderboard(viewModel: leaderboardViewModel, topImage: cityTopPost?.first?.thumbnailUrl, title: city, city: city)
                        }
                    }
                    .fullScreenCover(isPresented: $showRestaurantLeaderboard) {
                        RestaurantLeaderboard(
                            viewModel: leaderboardViewModel,
                            topImage: topUSARestaurant?.first?.profileImageUrl,
                            title: "USA"
                        )
                    }
                    .fullScreenCover(isPresented: $showStateRestaurantLeaderboard) {
                        if let state = state {
                            RestaurantLeaderboard(
                                viewModel: leaderboardViewModel,
                                topImage: stateTopRestaurant?.first?.profileImageUrl,
                                title: state,
                                state: state
                            )
                        }
                    }
                    .fullScreenCover(isPresented: $showCityRestaurantLeaderboard) {
                        if let city = city {
                            RestaurantLeaderboard(
                                viewModel: leaderboardViewModel,
                                topImage: cityTopRestaurant?.first?.profileImageUrl,
                                title: city,
                                city: city
                            )
                        }
                    }
                    
                }
            }
        }
    }
    
    private var contactsSection: some View {
        VStack(alignment: .leading) {
            HStack{
                Text("Friends on Ketchup")
                    .font(.custom("MuseoSansRounded-700", size: 25))
                    .foregroundStyle(.black)
                
                Spacer()
                Button(action: {
                    shouldShowExistingUsersOnContacts = true
                    showContacts = true
                }) {
                    
                    VStack {
                        Text("See All")
                            .font(.custom("MuseoSansRounded-300", size: 12))
                    }
                    
                    
                }
                .frame(height: 40)
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
                        ProgressView()
                            .frame(width: 50, height: 50)
                    }
                    
                    if viewModel.hasMoreContacts {
                        Color.clear
                            .frame(width: 1, height: 1)
                            .onAppear {
                                viewModel.loadMoreContacts()
                            }
                    }
                    
                    Button(action: {
                        showContacts = true
                    }) {
                        Text("See All")
                            .font(.custom("MuseoSansRounded-300", size: 14))
                            .foregroundColor(.white)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 16)
                            .background(Color("Colors/AccentColor"))
                            .cornerRadius(20)
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical)
    }
    
    private var activityListSection: some View {
        VStack(alignment: .leading) {
            HStack(alignment: .top) {
                Text("Following Activity")
                    .font(.custom("MuseoSansRounded-700", size: 25))
                    .foregroundStyle(.black)
                Spacer()
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
            .padding(.horizontal)
            
            if !viewModel.followingActivity.isEmpty {
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
            } else if viewModel.isFetching {
                FastCrossfadeFoodImageView()
            } else {
                Text("No activity from your friends yet.")
                    .font(.custom("MuseoSansRounded-300", size: 16))
                    .foregroundColor(.gray)
                    .padding()
            }
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
            Button(action: {
                isShowingProfile = true
            }) {
                UserCircularProfileImageView(profileImageUrl: contact.user?.profileImageUrl, size: .small)
            }
            .fullScreenCover(isPresented: $isShowingProfile) {
                if let userId = contact.user?.id {
                    NavigationStack {
                        ProfileView(uid: userId)
                    }
                }
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Button(action: {
                    isShowingProfile = true
                }) {
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
            
            Spacer()
            
            if isCheckingFollowStatus {
                ProgressView()
                    .scaleEffect(0.7)
            } else {
                followButton
            }
        }
        .padding(.vertical, 8)
        .onAppear(perform: checkFollowStatus)
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
                //print("Error checking follow status: \(error.localizedDescription)")
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
                //print("Failed to follow/unfollow: \(error.localizedDescription)")
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
}


struct InviteContactsButton: View {
    var body: some View {
        VStack{
            Divider()
            HStack{
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

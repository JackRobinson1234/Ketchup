//
//  FeedView.swift
//  Foodi
//
//  Created by Jack Robinson on 2/1/24.
//

import SwiftUI
import AVKit
import Combine
import Contacts
import CryptoKit

struct PrimaryFeedView: View {
    @StateObject var viewModel: FeedViewModel
    @State var scrollPosition: String?
    @State private var showSearchView = false
    @State private var showFilters = false
    @State private var isLoading = true
    @State private var selectedFeed: FeedType = .discover
    @State var pauseVideo = false
    @StateObject var filtersViewModel: FiltersViewModel
    @Environment(\.dismiss) var dismiss
    @State var startingPostId: String?
    private var titleText: String
    @State private var showSuccessMessage = false
    @State var selectedPost: Post?
    @State var showLocationFilter: Bool = false
    @State private var isRefreshing = false
    @State private var canSwitchTab = true
    @EnvironmentObject var tabBarController: TabBarController
    @State private var showAddFriends = false
    @State private var isContactsPermissionDenied = false
    @State private var hideTopUI = false
    @State private var lastScrollOffset: CGFloat = 0
    @State private var debounceTask: Task<Void, Never>? = nil
    private let scrollThreshold: CGFloat = 20
    private let debounceDelay: TimeInterval = 0.2
    @State private var topBarHeight: CGFloat = 150 // Default height
    @State var showPostSuccess = false
    @State private var newPostsCount: Int = 0
    @State private var scrollOffset: CGFloat = 0
    
    init(viewModel: FeedViewModel, initialScrollPosition: String? = nil, titleText: String = "") {
        self._viewModel = StateObject(wrappedValue: viewModel)
        self._filtersViewModel = StateObject(wrappedValue: FiltersViewModel(feedViewModel: viewModel))
        self._scrollPosition = State(initialValue: initialScrollPosition)
        self.titleText = titleText
        self.startingPostId = viewModel.startingPostId
    }
    
    var body: some View {
        if isLoading && viewModel.posts.isEmpty {
            FastCrossfadeFoodImageView()
                .onAppear {
                    Task {
                        updateNewPostsCount()
                        viewModel.setupLocation()
                        isLoading = false
                    }
                }
                .toolbar(.hidden, for: .tabBar)
        } else {
            NavigationStack {
                ZStack(alignment: .top) {
                    ScrollViewReader { scrollProxy in
                        ScrollView(showsIndicators: false) {
                            GeometryReader { geometry in
                                Color.clear
                                    .frame(height: 0) // GeometryReader only needs a small frame
                                    .onAppear {
                                        let initialOffset = geometry.frame(in: .global).minY
                                        viewModel.initialOffset = initialOffset
                                        lastScrollOffset = initialOffset
                                    }
                                    .onChange(of: geometry.frame(in: .global).minY) { newValue in
                                        let scrollOffset = newValue - (viewModel.initialOffset ?? 0)
                                        let scrollDifference = scrollOffset - lastScrollOffset
                                        
                                        // Trigger only when significant scroll change happens
                                        if abs(scrollDifference) > scrollThreshold {
                                            debounceTask?.cancel()
                                            debounceTask = Task { [scrollOffset] in
                                                await debounceScrollUpdate(scrollOffset, scrollDifference)
                                            }
                                        }
                                    }
                            }
                            LazyVStack {
                                if viewModel.isInitialLoading {
                                    FastCrossfadeFoodImageView()
                                } else {
                                    ForEach($viewModel.posts) { $post in
                                        WrittenFeedCell(viewModel: viewModel, post: $post, scrollPosition: $scrollPosition, pauseVideo: $pauseVideo, selectedPost: $selectedPost)
                                            .id(post.id)
                                            .onAppear {
                                                
                                                
                                                // Update scrollPosition when this cell appears
                                                scrollPosition = post.id
                                                // Trigger pagination when reaching near the end
                                                if let index = viewModel.posts.firstIndex(where: { $0.id == post.id }) {
                                                    if index >= viewModel.posts.count - 5 {
                                                        Task {
                                                            await viewModel.loadMoreContentIfNeeded(currentPost: post.id)
                                                        }
                                                    }
                                                }
                                            }
                                    }
                                    if viewModel.isLoadingMoreContent {
                                        FastCrossfadeFoodImageView()
                                            .padding()
                                    }
                                    // Optional: A clear rectangle to detect when the user has scrolled to the bottom
                                    Rectangle()
                                        .foregroundStyle(.clear)
                                        .onAppear {
                                            if let last = viewModel.posts.last {
                                                Task {
                                                    await viewModel.loadMoreContentIfNeeded(currentPost: last.id)
                                                }
                                            }
                                        }
                                }
                            }
                            .edgesIgnoringSafeArea(.top)
                            .padding(.top, 160)
                        }
                        .refreshable {
                            await refreshFeed()
                        }
                        .onAppear {
                            if viewModel.showPostAlert {
                                withAnimation(.easeInOut(duration: 1.0)) {
                                    showPostSuccess = true
                                    viewModel.showPostAlert = false
                                }
                                triggerHapticFeedback()
                            }
                        }
                        .onChange(of: viewModel.initialPrimaryScrollPosition) { newValue in
                            if let newPosition = newValue {
                                scrollProxy.scrollTo(newPosition, anchor: .center)
                            }
                        }
                        .onChange(of: tabBarController.scrollToTop) { _ in
                            if let post = viewModel.posts.first {
                                withAnimation(.smooth) {
                                    scrollProxy.scrollTo(post.id, anchor: .center)
                                }
                            }
                        }
                        .onChange(of: viewModel.isInitialLoading) { newValue in
                            if !viewModel.isInitialLoading {
                                if let post = viewModel.posts.first {
                                    withAnimation(.smooth) {
                                        scrollProxy.scrollTo(post.id, anchor: .center)
                                    }
                                }
                            }
                        }
                    }
                    .background(.white)
                    
                    // Top bar and other UI components
                    Rectangle()
                        .fill(Color.white)
                        .frame(height: topBarHeight)
                        .clipShape(
                            RoundedCorner(radius: 20, corners: [.bottomLeft, .bottomRight])
                        )
                        .shadow(color: Color.gray.opacity(0.1), radius: 2, x: 0, y: 2)
                        .animation(.easeInOut(duration: 0.3), value: topBarHeight)
                        .edgesIgnoringSafeArea(.top)
                    
                    VStack(spacing: 5) {
                        HStack(spacing: 0) {
                            
                            //                            actionButton(title: viewModel.currentLocationFilter != .anywhere && viewModel.city != nil && viewModel.state != nil ? "\(viewModel.city!), \(viewModel.state!)" : "Any Location", icon: "location") {
                            //                                pauseVideo = true
                            //                                showLocationFilter.toggle()
                            //                            }
                            
                            Button {
                                pauseVideo = true
                                showFilters.toggle()
                            } label: {
                                
                                VStack{
                                    Image(systemName: "slider.horizontal.3")
                                        .font(.system(size: 27))
                                        .foregroundStyle(.gray)
                                    Text("Filter Feed")
                                        .font(.custom("MuseoSansRounded-300", size: 10))
                                        .foregroundStyle(.gray)
                                }
                                .frame(width: 100)
                                
                            }
                            
                            
                            
                            Spacer()
                            Button {
                                tabBarController.scrollToTop.toggle()
                            } label: {
                                Image("KetchupTextRed")
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 60, height: 17)
                            }
                            Spacer()
                            
                            Button {
                                pauseVideo = true
                                showLocationFilter.toggle()
                            } label: {
                                
                                VStack{
                                    Image(systemName: "location")
                                        .font(.system(size: 24))
                                        .foregroundStyle(.gray)
                                    Text(viewModel.currentLocationFilter != .anywhere && viewModel.city != nil && viewModel.state != nil ? "\(viewModel.city!), \(viewModel.state!)" : "Any Location")
                                        .font(.custom("MuseoSansRounded-300", size: 10))
                                        .foregroundStyle(.gray)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.5)
                                }
                                .frame(width: 100)
                            }
                            
                            
                        }
                        .padding(.horizontal, 3)
                        .frame(maxWidth: .infinity)
                        .foregroundStyle(.black)
                        
                        if !hideTopUI {
                            // Search bar button
                            Button(action: {
                                showSearchView.toggle()
                            }) {
                                HStack {
                                    Image(systemName: "magnifyingglass")
                                        .foregroundColor(.black)
                                    Text("Search restaurants, sushi, users, etc.")
                                        .font(.custom("MuseoSansRounded-500", size: 14))
                                        .foregroundColor(.gray)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.5)
                                    Spacer()
                                }
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(10)
                                .padding(.horizontal)
                                .padding(.top, 4)
                            }
                            HStack{
                                HStack {
                                    
                                    //                                    ZStack(alignment: .bottomTrailing){
                                    //                                        actionButton(title: "Filter Feed", icon: "slider.horizontal.3") {
                                    //                                            pauseVideo = true
                                    //                                            showFilters.toggle() // Toggle the search view or feed filter when tapped
                                    //                                        }
                                    //                                        if viewModel.activeCuisineAndPriceFiltersCount > 0 {
                                    //                                            ZStack {
                                    //                                                Circle()
                                    //                                                    .fill(Color("Colors/AccentColor"))
                                    //                                                    .frame(width: 16, height: 16)
                                    //                                                Text("\(viewModel.activeCuisineAndPriceFiltersCount)")
                                    //                                                    .font(.custom("MuseoSansRounded-500", size: 10))
                                    //                                                    .foregroundColor(.white)
                                    //                                            }
                                    //                                            .offset(x: 5, y: 5)
                                    //                                            .padding(.leading, 1)
                                    //                                        }
                                    //                                    }
                                    
                                }
                                .padding(.horizontal)
                            }
                            
                            HStack(spacing: 40) {
                                HStack(spacing: 2) {
                                    
                                    
                                    Button {
                                        newPostsCount = 0
                                        if canSwitchTab {
                                            withAnimation(.easeInOut(duration: 0.5)) {
                                                viewModel.selectedTab = .following
                                            }
                                            canSwitchTab = false
                                            
                                            // Re-enable switching after a delay
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                                canSwitchTab = true
                                            }
                                        }
                                    } label: {
                                        HStack(){
                                            if newPostsCount > 0 && viewModel.selectedTab == .discover {
                                                ZStack {
                                                    Circle()
                                                        .fill(Color("Colors/AccentColor"))
                                                        .frame(width: 8, height: 8)
                                                    //                                                        Text("\(newPostsCount)")
                                                    //                                                            .font(.custom("MuseoSansRounded-500", size: 10))
                                                    //                                                            .foregroundColor(.white)
                                                }
                                                //.offset(x: 5, y: -5)
                                                .padding(.leading, 1)
                                            }
                                            Text("Following")
                                                .font(.custom("MuseoSansRounded-500", size: 18))
                                                .foregroundColor(viewModel.selectedTab == .following ? Color("Colors/AccentColor") : .gray)
                                                .overlay(
                                                    Rectangle()
                                                        .frame(height: 2)
                                                        .foregroundColor(viewModel.selectedTab == .following ? Color("Colors/AccentColor") : .clear)
                                                        .offset(y: 17)
                                                )
                                            
                                        }
                                    }
                                    .disabled(viewModel.selectedTab == .following || !canSwitchTab)
                                    
                                }
                                Button {
                                    if canSwitchTab {
                                        withAnimation(.easeInOut(duration: 0.5)) {
                                            viewModel.selectedTab = .discover
                                        }
                                        canSwitchTab = false
                                        
                                        // Re-enable switching after a delay
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                            canSwitchTab = true
                                        }
                                    }
                                } label: {
                                    Text("Discover")
                                        .font(.custom("MuseoSansRounded-500", size: 18))
                                        .foregroundColor(viewModel.selectedTab == .discover ? Color("Colors/AccentColor") : .gray)
                                        .overlay(
                                            Rectangle()
                                                .frame(height: 2)
                                                .foregroundColor(viewModel.selectedTab == .discover ? Color("Colors/AccentColor") : .clear)
                                                .offset(y: 17)
                                        )
                                }
                                .disabled(viewModel.selectedTab == .discover || !canSwitchTab)
                            }
                            .padding(.bottom, 6)
                        }
                        
                    }
                }
                .overlay {
                    //                    if viewModel.showEmptyView {
                    //                        VStack {
                    //                            CustomUnavailableView(text: "No posts to show", image: "eye.slash")
                    //                                .foregroundStyle(Color("Colors/AccentColor"))
                    //                        }
                    //                    }
                    
                    if viewModel.showRepostAlert {
                        SuccessMessageOverlay(text: "Reposted!")
                            .transition(.opacity)
                            .onAppear {
                                Debouncer(delay: 2.0).schedule {
                                    viewModel.showRepostAlert = false
                                }
                            }
                    }
                }
                .onChange(of: showSearchView) { newValue in
                    pauseVideo = newValue
                }
                .fullScreenCover(isPresented: $showSearchView) {
                    SearchView(initialSearchConfig: .restaurants)
                }
                .onChange(of: showFilters) { newValue in
                    pauseVideo = newValue
                }
                .fullScreenCover(isPresented: $showFilters) {
                    FiltersView(filtersViewModel: filtersViewModel)
                }
                .navigationBarHidden(true)
                .fullScreenCover(item: $selectedPost) { post in
                    NavigationStack {
                        if #available(iOS 17, *) {
                            SecondaryFeedView(viewModel: viewModel, hideFeedOptions: false, initialScrollPosition: post.id, titleText: ("Discover"))
                        } else {
                            IOS16SecondaryFeedView(viewModel: viewModel, hideFeedOptions: false, initialScrollPosition: post.id, titleText: ("Discover"))
                        }
                    }
                }
                .sheet(isPresented: $showLocationFilter) {
                    NavigationStack {
                        LocationFilter(feedViewModel: viewModel)
                            .modifier(BackButtonModifier())
                    }
                    .presentationDetents([.height(UIScreen.main.bounds.height * 0.5)])
                }
                .navigationDestination(for: PostUser.self) { user in
                    ProfileView(uid: user.id)
                }
                .navigationDestination(for: PostRestaurant.self) { restaurant in
                    RestaurantProfileView(restaurantId: restaurant.id)
                }
                .onChange(of: showAddFriends) { newValue in
                    pauseVideo = newValue
                }
                .sheet(isPresented: $showAddFriends) {
                    ContactsView()
                }
                .onAppear {
                    checkContactsPermissionAndSync()
                }
            }
        }
    }
    
    // MARK: - Helper Functions
    
    private func checkContactsPermissionAndSync() {
        let authorizationStatus = CNContactStore.authorizationStatus(for: .contacts)
        if authorizationStatus == .denied || authorizationStatus == .restricted {
            isContactsPermissionDenied = true
        } else if authorizationStatus == .notDetermined {
            CNContactStore().requestAccess(for: .contacts) { granted, _ in
                DispatchQueue.main.async {
                    isContactsPermissionDenied = !granted
                    if granted {
                        startContactSync()
                    }
                }
            }
        } else if authorizationStatus == .authorized {
            startContactSync()
        }
    }
    
    private func startContactSync() {
        if AuthService.shared.userSession?.contactsSynced == false {
            Task {
                try await ContactService.shared.syncDeviceContacts()
            }
        }
    }
    
    private func refreshFeed() async {
        isRefreshing = true
        do {
            try await viewModel.fetchInitialPosts()
        } catch {
            // Handle error
        }
        isRefreshing = false
    }
    
    private func debounceScrollUpdate(_ scrollOffset: CGFloat, _ scrollDifference: CGFloat) async {
        try? await Task.sleep(nanoseconds: UInt64(debounceDelay * 1_000_000_000))
        DispatchQueue.main.async {
            if scrollDifference > 0 {
                // Scrolling up
                withAnimation(.easeInOut(duration: 0.3)) {
                    hideTopUI = false
                    topBarHeight = 210
                }
            } else if scrollDifference < -60 {
                // Scrolling down
                withAnimation(.easeInOut(duration: 0.3)) {
                    hideTopUI = true
                    topBarHeight = 95
                }
            }
            lastScrollOffset = scrollOffset
        }
    }
    
    private func hashPhoneNumber(_ phoneNumber: String) -> String {
        let inputData = Data(phoneNumber.utf8)
        let hashed = SHA256.hash(data: inputData)
        return hashed.compactMap { String(format: "%02x", $0) }.joined()
    }
    
    private func updateNewPostsCount() {
        if let userSession = AuthService.shared.userSession {
            if userSession.followingPosts > 0 {
                newPostsCount = userSession.followingPosts
            }
        }
    }
    private func actionButton(title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 1) { // Horizontal stack to align icon and title
                Image(systemName: icon)
                    .font(.system(size: 16)) // Smaller icon size
                Text(title)
                    .font(.custom("MuseoSansRounded-500", size: 12))
                    .padding(.horizontal, 8)
            }
            .padding(.horizontal, 5)
            .padding(.vertical, 4)
            .overlay(
                Capsule()
                    .stroke(Color.gray.opacity(0.5), lineWidth: 1) // Rounded pill border
            )
        }
        .foregroundColor(.black)
        
    }
}

struct SuccessMessageOverlay: View {
    var text: String
    var body: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                VStack {
                    Image("Skip")
                        .resizable()
                        .frame(width: 40, height: 40)
                    Text(text)
                        .foregroundColor(.white)
                        .font(.custom("MuseoSansRounded-300", size: 16))
                        .bold()
                }
                .padding()
                .background(Color.gray.opacity(0.5))
                .cornerRadius(15)
                Spacer()
            }
            Spacer()
        }
        .transition(.opacity)
    }
}

enum FeedViewOption {
    case grid, feed
}

extension Color {
    init(hex: Int, alpha: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255.0,
            green: Double((hex >> 8) & 0xFF) / 255.0,
            blue: Double(hex & 0xFF) / 255.0,
            opacity: alpha
        )
    }
}


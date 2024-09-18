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
                                    ForEach($viewModel.posts) { post in
                                        WrittenFeedCell(viewModel: viewModel, post: post, scrollPosition: $scrollPosition, pauseVideo: $pauseVideo, selectedPost: $selectedPost)
                                            .id(post.id)
                                        
                                    }
                                    if viewModel.isLoadingMoreContent {
                                        FastCrossfadeFoodImageView()
                                            .padding()
                                    }
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
                            //.scrollTargetLayout()
                        }
                        .refreshable {
                            await refreshFeed()
                        }
                        .onAppear{
                            if viewModel.showPostAlert{
                                withAnimation(.easeInOut(duration: 1.0)) {
                                    showPostSuccess = true
                                    viewModel.showPostAlert = false
                                }
                                triggerHapticFeedback()
                            }
                        }
                        //.safeAreaPadding(.top, 170)
                        //.transition(.slide)
                        //.scrollPosition(id: $scrollPosition)
                        .onChange(of: viewModel.initialPrimaryScrollPosition) {newValue in
                            scrollPosition = viewModel.initialPrimaryScrollPosition
                            scrollProxy.scrollTo(viewModel.initialPrimaryScrollPosition, anchor: .center)
                            
                        }
                        .onChange(of: tabBarController.scrollToTop){ newValue in
                            if let post = viewModel.posts.first {
                                withAnimation(.smooth) {
                                    scrollProxy.scrollTo(post.id, anchor: .center)
                                }
                            }
                        }
                        .onChange(of: viewModel.isInitialLoading){newValue in
                            if !viewModel.isInitialLoading{
                                if let post = viewModel.posts.first {
                                    withAnimation(.smooth) {
                                        scrollProxy.scrollTo(post.id, anchor: .center)
                                    }
                                }
                            }
                        }
                    }
                    .background(.white)
                    
                    Rectangle()
                        .fill(Color.white)
                        .frame(height: topBarHeight)
                        .clipShape(
                            RoundedCorner(radius: 20, corners: [.bottomLeft, .bottomRight])
                        )
                        .shadow(color: Color.gray.opacity(0.1), radius: 2, x: 0, y: 2)
                        .animation(.easeInOut(duration: 0.3), value: topBarHeight)
                        .edgesIgnoringSafeArea(.top)
                    
                    
                    VStack(spacing: 5){
                        HStack(spacing: 0) {
                            Button{
                                tabBarController.scrollToTop.toggle()
                            } label: {
                                Image("KetchupTextRed")
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 60, height: 17)
                                    .padding(.leading, 40)
                            }
                            
                            Spacer()
                            Button {
                                showLocationFilter.toggle()
                            } label: {
                                HStack(spacing: 1) {
                                    Image(systemName: "location")
                                        .foregroundStyle(.gray)
                                        .font(.caption)
                                    
                                    if viewModel.currentLocationFilter != .anywhere, let city = viewModel.city, let state = viewModel.state {
                                        Text("\(city), \(state)")
                                            .font(.custom("MuseoSansRounded-500", size: 16))
                                            .foregroundStyle(.gray)
                                    } else {
                                        Text("Any Location")
                                            .font(.custom("MuseoSansRounded-500", size: 16))
                                            .foregroundStyle(.gray)
                                    }
                                    
                                    Image(systemName: "chevron.down")
                                        .foregroundStyle(.gray)
                                        .font(.caption)
                                }
                                .lineLimit(1)
                                .minimumScaleFactor(0.5)
                                .padding(.trailing, 20)
                            }
//                            Rectangle()
//                                .foregroundStyle(.clear)
//                                .frame(width: 100, height: 1)
//                            Button {
//                                showFilters.toggle()
//                            } label: {
//                                VStack{
//                                    ZStack {
//                                        
//                                        Image(systemName: "slider.horizontal.3")
//                                            .imageScale(.large)
//                                            .shadow(radius: 4)
//                                            .font(.system(size: 23))
//                                        if filtersViewModel.hasNonLocationFilters {
//                                            Circle()
//                                                .fill(Color("Colors/AccentColor"))
//                                                .frame(width: 12, height: 12)
//                                                .offset(x: 12, y: 12)
//                                        }
//                                        
//                                    }
//                                    Text("Filters")
//                                        .foregroundStyle(.gray)
//                                    
//                                        .font(.custom("MuseoSansRounded-500", size: 10))
//                                }
//                                .frame(width: 60)
//                            }
                        }
                        .frame(maxWidth: .infinity)
                        
                        .foregroundStyle(.black)
                        if !hideTopUI{

                        
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
                            Button {
                                pauseVideo = true
                                showFilters.toggle()
                            } label: {
                                HStack(spacing: 1) {
                                    Image(systemName: "slider.horizontal.3")
                                        .foregroundColor(.gray)
                                    Text("Filter Feed")
                                        .font(.custom("MuseoSansRounded-500", size: 16))
                                        .foregroundColor(.gray)
                                    
                                    if viewModel.activeCuisineAndPriceFiltersCount > 0 {
                                        ZStack {
                                            Circle()
                                                .fill(Color("Colors/AccentColor"))
                                                .frame(width: 16, height: 16)
                                            Text("\(viewModel.activeCuisineAndPriceFiltersCount)")
                                                .font(.custom("MuseoSansRounded-500", size: 10))
                                                .foregroundColor(.white)
                                        }
                                        .padding(.leading, 1)
                                    }
                                        
                                }
                                .padding(.vertical, 2)
                                .padding(.horizontal)
                            }
//
//                                                    ScrollView(.horizontal, showsIndicators: false) {
//                                                        HStack(spacing: 8) {
//                                                            ForEach(["Filter Cuisine", "Filter Price"], id: \.self) { filter in
//                                                                Text(filter)
//                                                                    .font(.custom("MuseoSansRounded-300", size: 12))
//                                                                    .foregroundColor(.black)
//                                                                    .padding(.horizontal, 12)
//                                                                    .padding(.vertical, 6)
//                                                                    
//                                                                    .overlay(
//                                                                        RoundedRectangle(cornerRadius: 20)
//                                                                            .stroke( Color("Colors/AccentColor"), lineWidth: 1)
//                                                                    )
//                                                                    .cornerRadius(16)
//                                                                
//                                                            }
//                                                        }
//                                                        .padding(.horizontal)
//                                                    }
                            HStack(spacing: 40) {
                                HStack(spacing: 2) {
                                    if newPostsCount > 0 && viewModel.selectedTab == .discover {
                                           ZStack {
                                               Circle()
                                                   .fill(Color("Colors/AccentColor"))
                                                   .frame(width: 20, height: 20)
                                               Text("\(newPostsCount)")
                                                   .font(.custom("MuseoSansRounded-500", size: 10))
                                                   .foregroundColor(.white)
                                           }
                                       }
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
                .onAppear{
                    
                }
                .overlay {
                    if viewModel.showEmptyView {
                        VStack{
                            CustomUnavailableView(text: "No posts to show", image: "eye.slash")
                                .foregroundStyle(Color("Colors/AccentColor"))
                            
                        }
                    }
                    
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
//                .onChange(of: scrollPosition) { oldPostId, newPostId in
//                    if let oldIndex = viewModel.posts.firstIndex(where: { $0.id == oldPostId }),
//                       let newIndex = viewModel.posts.firstIndex(where: { $0.id == newPostId }) {
//                        if newIndex > oldIndex {
//                            Task {
//                                await viewModel.loadMoreContentIfNeeded(currentPost: newPostId)
//                            }
//                            viewModel.updateCache(scrollPosition: newPostId)
//                            
//                        } else {
//                        }
//                    }
//                }
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
                        SecondaryFeedView(viewModel: viewModel, hideFeedOptions: false, initialScrollPosition: post.id, titleText: ("Discover"))
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
                    print(hashPhoneNumber("+1234567890"))
                    checkContactsPermissionAndSync()
                }
            }
        }
    }
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
        if AuthService.shared.userSession?.hasContactsSynced == false {
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
            //print("Error refreshing: \(error)")
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
                    
                    
                    topBarHeight = 85
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
        if let userSession = AuthService.shared.userSession{
            if userSession.followingPosts > 0 {
                newPostsCount = userSession.followingPosts
            }
        }
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

//struct ConditionalSafeAreaPadding: ViewModifier {
//    var condition: Bool
//    var padding: CGFloat
//    
//    func body(content: Content) -> some View {
//        if condition {
//            content.safeAreaPadding(.vertical, padding)
//        } else {
//            content
//        }
//    }
//}
//
//extension View {
//    func conditionalSafeAreaPadding(_ condition: Bool, padding: CGFloat) -> some View {
//        self.modifier(ConditionalSafeAreaPadding(condition: condition, padding: padding))
//    }
//}


import SwiftUI
import AVKit
import Combine
import Contacts
import CryptoKit
import Kingfisher

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
    @State private var topBarHeight: CGFloat = 90 // Default height
    @State var showPostSuccess = false
    @State private var newPostsCount: Int = 0
    @State private var scrollOffset: CGFloat = 0
    @StateObject var locationViewModel = LocationViewModel()
    @StateObject private var pollViewModel = PollViewModel()
    @State private var showPollView = false // Add this line
    @State private var showPollUploadView = false

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
                        pollViewModel.fetchPolls()
                        isLoading = false
                    }
                }
                .toolbar(.hidden, for: .tabBar)
            
        } else {
            NavigationStack {
                ZStack(alignment: .top) {
                    if viewModel.selectedMainTab == .dashboard {
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
                                ActivityView(locationViewModel: locationViewModel, feedViewModel: viewModel, newPostsCount: $newPostsCount, hideTopUI: $hideTopUI, topBarHeight: $topBarHeight, showAddFriends: $showAddFriends)
                                    .onChange(of: viewModel.initialPrimaryScrollPosition) { newValue in
                                        if let newPosition = newValue {
                                            withAnimation(.smooth) {
                                                scrollProxy.scrollTo(newPosition, anchor: .center)
                                            }
                                        }
                                        viewModel.initialPrimaryScrollPosition = nil
                                    }
                                    .onChange(of: tabBarController.scrollToTop) { _ in
                                        withAnimation(.smooth) {
                                            scrollProxy.scrollTo("userUpdates", anchor: .center)
                                        }
                                        
                                    }
                            }
                    
                        }
                    } else {
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
                                        Spacer()
                                    } else {
                                        if isRefreshing{
                                            FastCrossfadeFoodImageView()
                                            Spacer()
                                        }
                                       
                                        inviteContactsButton
                                    
//                                        Button {
//                                            showPollUploadView = true
//                                        } label: {
//                                            Text("Poll Manager")
//                                                .font(.custom("MuseoSansRounded-300", size: 12))
//                                                .modifier(StandardButtonModifier(width: 80))
//                                                .padding(.trailing)
//                                        }
                                        if let poll = pollViewModel.polls.first {
                                            
                                            Button(action: {
                                                // Navigate to the daily poll
                                                showPollView = true
                                                pauseVideo = true
                                                
                                            }) {
                                                HStack {
                                                    if let imageUrl = poll.imageUrl {
                                                        KFImage(URL(string: imageUrl))
                                                            .resizable()
                                                            .frame(width: 80, height: 80)
                                                            .cornerRadius(8)
                                                    }
                                                    VStack(alignment: .leading) {
                                                        Text("Daily Poll")
                                                            .font(.custom("MuseoSansRounded-700", size: 16))
                                                            .foregroundColor(.black)  // Changed to white
                                                        
                                                        Text(poll.question)
                                                            .foregroundColor(.black)  // Changed to white
                                                            .font(.custom("MuseoSansRounded-500", size: 14))
                                                            .multilineTextAlignment(.leading)
                                                            .lineLimit(2)
                                                        
                                                    }
                                                    Spacer()
                                                    Image(systemName: "chevron.right")
                                                        .foregroundColor(.gray)
                                                        .padding(.trailing)
                                                    // Changed to white
                                                }
                                               
                                                .overlay(
                                                            RoundedRectangle(cornerRadius: 12)
                                                                .stroke(Color.gray.opacity(0.5), lineWidth: 1) // Thin gray stencil outline
                                                        )
                                                .cornerRadius(8)
                                                .id("DailyPoll")
                                                .padding(.horizontal)
                                                .padding(.bottom, 30)
                                            }
                                        }
                                       Divider()
                                        ForEach($viewModel.posts) { $post in
                                            if !post.isReported{
                                            
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
                            }
                            .padding(.top, 50)
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
                            .sheet(isPresented: $showPollUploadView) {
                                PollUploadView()
                            }
                            .onChange(of: viewModel.initialPrimaryScrollPosition) { newValue in
                                if let newPosition = newValue {
                                    scrollProxy.scrollTo(newPosition, anchor: .center)
                                }
                            }
                            .onChange(of: tabBarController.scrollToTop) { _ in
                                if let post = viewModel.posts.first {
                                    withAnimation(.smooth) {
                                        scrollProxy.scrollTo("DailyPoll", anchor: .center)
                                    }
                                }
                            }
//                            .onChange(of: viewModel.isInitialLoading) { newValue in
//                                if !viewModel.isInitialLoading {
//                                    if let post = viewModel.posts.first {
//                                        withAnimation(.smooth) {
//                                            scrollProxy.scrollTo(post.id, anchor: .center)
//                                        }
//                                    }
//                                }
//                            }
                        }
                        
                        .background(.white)
                        
                    }
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
                            Button {
                                tabBarController.scrollToTop.toggle()
                            } label: {
                                Image("KetchupTextRed")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 100)
                            }
                            Spacer()
                            if viewModel.selectedMainTab == .feed {
                                HStack {
                                    // Left side: Filters button
                                    Button {
                                        pauseVideo = true
                                        showFilters.toggle()
                                    } label: {
                                        HStack(spacing: 1) {
                                            Image(systemName: "slider.horizontal.3")
                                                .font(.system(size: 16))
                                            Text("Filters")
                                                .font(.custom("MuseoSansRounded-500", size: 12))
                                        }
                                        .padding(.horizontal, 5)
                                        .padding(.vertical, 4)
                                        .overlay(
                                            Capsule()
                                                .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                                        )
                                    }
                                    .foregroundColor(.black)
                                    
                                    
                                    // Right side: Followers or Anyone
                                    Button {
                                        // Toggle between following and discover
                                        withAnimation {
                                            if viewModel.selectedFeedSubTab == .following {
                                                viewModel.selectedFeedSubTab = .discover
                                            } else {
                                                viewModel.selectedFeedSubTab = .following
                                            }
                                        }
                                    } label: {
                                        HStack(spacing: 1) {
                                            Image(systemName: "person.2")
                                            
                                            Text(viewModel.selectedFeedSubTab == .following ? "Following only" : "See following only")
                                        }
                                        .font(.custom("MuseoSansRounded-500", size: 12))
                                        .padding(.horizontal, 5)
                                        .padding(.vertical, 4)
                                        .background(
                                            viewModel.selectedFeedSubTab == .following ? Color.red : Color.clear
                                        )
                                        .cornerRadius(15)
                                        .overlay(
                                            Capsule()
                                                .stroke(viewModel.selectedFeedSubTab == .following ? Color.red : Color.gray.opacity(0.5), lineWidth: 1)
                                        )
                                    }
                                    .foregroundColor(viewModel.selectedFeedSubTab == .following ? .white : .black)
                                    .animation(.easeInOut, value: viewModel.selectedFeedSubTab)
                                }
                                .padding(.horizontal, 16)
                            }
//                            Button{
//                                //showAddFriends = true
//                            } label: {
//                                Text("Check In")
//                                    .font(.custom("MuseoSansRounded-300", size: 12))
//                                    .fontWeight(.semibold)
//                                    .foregroundColor(.white)
//                                    .frame(width: 80, height: 28)
//                                    .background(Color("Colors/AccentColor"))
//                                    .cornerRadius(8)
//                            }
                        }
                        .padding(.horizontal, 20)
                        .foregroundStyle(.black)
                        
                        if !hideTopUI {
                            VStack{
                                HStack {
                                    // Dashboard Tab
//                                    Button {
//                                        if canSwitchTab {
//                                            withAnimation(.easeInOut(duration: 0.5)) {
//                                                viewModel.selectedMainTab = .dashboard
//                                                hideTopUI = false
//                                                topBarHeight = 120
//                                            }
//                                            canSwitchTab = false
//                                            // Re-enable switching after a delay
//                                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
//                                                canSwitchTab = true
//                                            }
//                                        }
//                                        
//                                    } label: {
//                                        Text("Home")
//                                            .font(.custom("MuseoSansRounded-500", size: 18))
//                                            .foregroundColor(viewModel.selectedMainTab == .dashboard ? Color("Colors/AccentColor") : .gray)
//                                            .overlay(
//                                                Rectangle()
//                                                    .frame(height: 2)
//                                                    .foregroundColor(viewModel.selectedMainTab == .dashboard ? Color("Colors/AccentColor") : .clear)
//                                                    .offset(y: 17)
//                                            )
//                                    }
//                                    .frame(width:(UIScreen.main.bounds.width - (16 * 2)) / 4)
//                                    .disabled(viewModel.selectedMainTab == .dashboard || !canSwitchTab)
                                    
                                    // Following Tab
//                                    Button {
//                                        newPostsCount = 0
//                                        if canSwitchTab {
//                                            withAnimation(.easeInOut(duration: 0.5)) {
//                                                viewModel.selectedMainTab = .feed
//                                                hideTopUI = false
//                                                topBarHeight = 160
//                                            }
//                                            canSwitchTab = false
//                                            // Re-enable switching after a delay
//                                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
//                                                canSwitchTab = true
//                                            }
//                                        }
//                                        
//                                    } label: {
//                                        HStack{
//                                            if newPostsCount > 0  {
//                                                ZStack {
//                                                    Circle()
//                                                        .fill(Color("Colors/AccentColor"))
//                                                        .frame(width: 8, height: 8)
//                                                }
//                                                .padding(.leading, 1)
//                                            }
//                                            Text("Feed")
//                                                .font(.custom("MuseoSansRounded-500", size: 18))
//                                                .foregroundColor(viewModel.selectedMainTab == .feed ? Color("Colors/AccentColor") : .gray)
//                                                .overlay(
//                                                    Rectangle()
//                                                        .frame(height: 2)
//                                                        .foregroundColor(viewModel.selectedMainTab == .feed ? Color("Colors/AccentColor") : .clear)
//                                                        .offset(y: 17)
//                                                )
//                                        }
//                                    }
//                                    .frame(width:(UIScreen.main.bounds.width - (16 * 2)) / 4)
//                                    .disabled(viewModel.selectedMainTab == .feed || !canSwitchTab)
                                    
                                    // Discover Tab
                                    //                                Button {
                                    //                                    if canSwitchTab {
                                    //                                        withAnimation(.easeInOut(duration: 0.5)) {
                                    //                                            viewModel.selectedTab = .discover
                                    //                                        }
                                    //                                        canSwitchTab = false
                                    //                                        // Re-enable switching after a delay
                                    //                                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                    //                                            canSwitchTab = true
                                    //                                        }
                                    //                                    }
                                    //                                } label: {
                                    //                                    Text("Explore")
                                    //                                        .font(.custom("MuseoSansRounded-500", size: 18))
                                    //                                        .foregroundColor(viewModel.selectedTab == .discover ? Color("Colors/AccentColor") : .gray)
                                    //                                        .overlay(
                                    //                                            Rectangle()
                                    //                                                .frame(height: 2)
                                    //                                                .foregroundColor(viewModel.selectedTab == .discover ? Color("Colors/AccentColor") : .clear)
                                    //                                                .offset(y: 17)
                                    //                                        )
                                    //                                }
                                    //                                .frame(width:(UIScreen.main.bounds.width - (16 * 2)) / 3)
                                    //                                .disabled(viewModel.selectedTab == .discover || !canSwitchTab)
                                }
                                .padding(.bottom, 6)
                                .padding(.bottom, 6)
                          
                            }
                        }
                    }
                }
                
                .overlay {
                    if viewModel.showEmptyView && viewModel.selectedMainTab == .feed {
                        VStack {
                            CustomUnavailableView(text: "No posts to show", image: "eye.slash")
                                .foregroundStyle(Color("Colors/AccentColor"))
                            if viewModel.selectedFeedSubTab == .following {
                                Button{
                                    showAddFriends = true
                                } label: {
                                    Text("Invite your friends!")
                                        .foregroundStyle(Color("Colors/AccentColor"))
                                        .font(.custom("MuseoSansRounded-700", size: 14))
                                }
                            }
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
                .sheet(isPresented: $showPollView) {
                    if let poll = pollViewModel.polls.first {
                        NavigationStack{
                            ScrollView {
                                PollView(poll: .constant(poll), pollViewModel: pollViewModel, feedViewModel: viewModel)
                                    .presentationDetents([.height(UIScreen.main.bounds.height * 0.75)])
                                    .toolbar {
                                        ToolbarItem(placement: .confirmationAction) {
                                            Button("Done") {
                                                showPollView = false
                                            }
                                        }
                                    }
                            }
                        }
                    }
                }
                .sheet(isPresented: $showLocationFilter) {
                    LocationSearchView(locationViewModel: locationViewModel)
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
                    if viewModel.selectedMainTab == .dashboard{
                        topBarHeight = 120
                    } else {
                        topBarHeight = 90                    }
                }
            } else if scrollDifference < -60 {
                // Scrolling down
                withAnimation(.easeInOut(duration: 0.3)) {
                    hideTopUI = true
                    topBarHeight = 90
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
    func abbreviatedDistance(_ distance: String) -> String {
        return distance
            .replacingOccurrences(of: " miles", with: "mi")
            .replacingOccurrences(of: " mile", with: "mi")
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
    private var inviteContactsButton: some View {
        Button {
            pauseVideo = true
            showAddFriends = true
        } label: {
            HStack {
                VStack{
                    Image(systemName: "envelope")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 40, height: 80)
                        .cornerRadius(8)
                        .foregroundColor(.black)
                        
                }
                .frame(width: 80, height: 80)
                VStack(alignment: .leading) {
                    Text("Ketchup is Invite Only")
                        .font(.custom("MuseoSansRounded-700", size: 16))
                        .foregroundColor(.black)
                    
                    Text("You have \(AuthService.shared.userSession?.remainingReferrals ?? 3) invites left!")
                        .font(.custom("MuseoSansRounded-500", size: 14))
                        .foregroundColor(.black)
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                    
                    Text("Share your code: \(AuthService.shared.userSession?.referralCode ?? "ketchup583")")
                        .font(.custom("MuseoSansRounded-300", size: 12))
                        .foregroundColor(.gray)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
                    .padding(.trailing)
            }
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.gray.opacity(0.5), lineWidth: 1)
            )
            .cornerRadius(8)
            .padding(.horizontal)
         
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

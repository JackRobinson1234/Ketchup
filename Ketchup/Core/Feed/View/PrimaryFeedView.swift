//
//  FeedView.swift
//  Foodi
//
//  Created by Jack Robinson on 2/1/24.
//

import SwiftUI
import AVKit
import Combine

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
    
    init(viewModel: FeedViewModel, initialScrollPosition: String? = nil, titleText: String = "") {
        self._viewModel = StateObject(wrappedValue: viewModel)
        self._filtersViewModel = StateObject(wrappedValue: FiltersViewModel(feedViewModel: viewModel))
        self._scrollPosition = State(initialValue: initialScrollPosition)
        self.titleText = titleText
        self.startingPostId = viewModel.startingPostId
    }
    
    var body: some View {
        if isLoading && viewModel.posts.isEmpty {
            ProgressView("Loading...")
                .onAppear {
                    Task {
                        try await viewModel.fetchInitialPosts()
                        isLoading = false
                    }
                }
                .toolbar(.hidden, for: .tabBar)
        } else {
            NavigationStack {
                ZStack(alignment: .top) {
                    ScrollViewReader { scrollProxy in
                        ScrollView(showsIndicators: false) {
                            LazyVStack {
                                ForEach($viewModel.posts) { post in
                                    WrittenFeedCell(viewModel: viewModel, post: post, scrollPosition: $scrollPosition, pauseVideo: $pauseVideo, selectedPost: $selectedPost)
                                        .id(post.id)
                                    
                                }
                                if viewModel.isLoadingMoreContent {
                                    ProgressView()
                                        .padding()
                                }
                                Rectangle()
                                    .foregroundStyle(.clear)
                                    .onAppear {
                                        print("CLEAR APPEARED")
                                        if let last = viewModel.posts.last {
                                            Task {
                                                await viewModel.loadMoreContentIfNeeded(currentPost: last.id)
                                            }
                                        }
                                    }
                            }
                            .scrollTargetLayout()
                        }
                        .refreshable {
                            await refreshFeed()
                        }
                        .safeAreaPadding(.top, 90)
                        .transition(.slide)
                        .scrollPosition(id: $scrollPosition)
                        .onChange(of: viewModel.initialPrimaryScrollPosition) {
                            scrollPosition = viewModel.initialPrimaryScrollPosition
                            scrollProxy.scrollTo(viewModel.initialPrimaryScrollPosition, anchor: .center)
                            
                        }
                        .onChange(of: tabBarController.scrollToTop){
                            print("SCROLLING")
                            if let post = viewModel.posts.first {
                                print("Moving to first")
                                withAnimation(.smooth) {
                                    scrollProxy.scrollTo(post.id, anchor: .center)
                                }
                            }
                        }
                    }
                    .background(Color("Colors/HingeGray"))
                    Color.white
                        .frame(height: 140)
                        .edgesIgnoringSafeArea(.top)
                    VStack(spacing: 0){
                        HStack(spacing: 0) {
                            Button {
                                showSearchView.toggle()
                            } label: {
                                Image(systemName: "magnifyingglass")
                                    .font(.system(size: 27))
                                    .frame(width: 60)
                            }
                            Spacer()
                            Button{
                                tabBarController.scrollToTop.toggle()
                            } label: {
                                Image("KetchupTextRed")
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 60, height: 17)
                            }
                            Spacer()
                            Button {
                                showFilters.toggle()
                            } label: {
                                ZStack {
                                    Image(systemName: "slider.horizontal.3")
                                        .imageScale(.large)
                                        .shadow(radius: 4)
                                        .font(.system(size: 23))
                                    if filtersViewModel.hasNonLocationFilters {
                                        Circle()
                                            .fill(Color("Colors/AccentColor"))
                                            .frame(width: 12, height: 12)
                                            .offset(x: 12, y: 12)
                                    }
                                }
                                .frame(width: 60)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 20)
                        .foregroundStyle(.primary)
                        .padding(.bottom, 10)
                        HStack(spacing: 40) {
                            Button {
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
                                    .font(.custom("MuseoSansRounded-300", size: 18))
                                    .foregroundColor(viewModel.selectedTab == .following ? Color("Colors/AccentColor") : .gray)
                                    .padding(.bottom, 5)
                                    .overlay(
                                        Rectangle()
                                            .frame(height: 2)
                                            .foregroundColor(viewModel.selectedTab == .following ? Color("Colors/AccentColor") : .clear)
                                            .offset(y: 12)
                                    )
                            }
                            .disabled(viewModel.selectedTab == .following || !canSwitchTab)
                            
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
                                    .font(.custom("MuseoSansRounded-300", size: 18))
                                    .foregroundColor(viewModel.selectedTab == .discover ? Color("Colors/AccentColor") : .gray)
                                    .padding(.bottom, 5)
                                    .overlay(
                                        Rectangle()
                                            .frame(height: 2)
                                            .foregroundColor(viewModel.selectedTab == .discover ? Color("Colors/AccentColor") : .clear)
                                            .offset(y: 12)
                                    )
                            }
                            .disabled(viewModel.selectedTab == .discover || !canSwitchTab)
                        }
                        .padding(.bottom, 6)
                        Button {
                            showLocationFilter.toggle()
                        } label: {
                            HStack {
                                if let cityFilter = viewModel.filters?.first(where: { $0.key == "restaurant.city" }) {
                                    if let cities = cityFilter.value as? [String], !cities.isEmpty {
                                        if cities.count > 1 {
                                            HStack (spacing: 1){
                                                Image(systemName: "location")
                                                    .foregroundStyle(.gray)
                                                    .font(.caption)
                                                Text("\(cities[0]) +\(cities.count - 1) more")
                                                    .font(.custom("MuseoSansRounded-300", size: 16))
                                                    .foregroundStyle(.gray)
                                                Image(systemName: "chevron.down")
                                                    .foregroundStyle(.gray)
                                                    .font(.caption)
                                            }
                                        } else {
                                            HStack(spacing: 1) {
                                                Image(systemName: "location")
                                                    .foregroundStyle(.gray)
                                                    .font(.caption)
                                                Text(cities[0])
                                                    .font(.custom("MuseoSansRounded-300", size: 16))
                                                    .foregroundStyle(.gray)
                                                Image(systemName: "chevron.down")
                                                    .foregroundStyle(.gray)
                                                    .font(.caption)
                                            }
                                        }
                                    } else {
                                        HStack(spacing: 1) {
                                            Image(systemName: "location")
                                                .foregroundStyle(.gray)
                                                .font(.caption)
                                            Text("Any Location")
                                                .font(.custom("MuseoSansRounded-300", size: 16))
                                                .foregroundStyle(.gray)
                                            Image(systemName: "chevron.down")
                                                .foregroundStyle(.gray)
                                                .font(.caption)
                                        }
                                    }
                                } else {
                                    HStack(spacing: 1) {
                                        Image(systemName: "location")
                                            .foregroundStyle(.gray)
                                            .font(.caption)
                                        Text("Any Location")
                                            .font(.custom("MuseoSansRounded-300", size: 16))
                                            .foregroundStyle(.gray)
                                        Image(systemName: "chevron.down")
                                            .foregroundStyle(.gray)
                                            .font(.caption)
                                    }
                                }
                            }
                        }
                    }
                    .background(Color.white)
                }
                .overlay {
                    if viewModel.showEmptyView {
                        ContentUnavailableView("No posts to show", systemImage: "eye.slash")
                            .foregroundStyle(Color("Colors/AccentColor"))
                    }
                    if viewModel.showPostAlert {
                        SuccessMessageOverlay(text: "Post Uploaded!")
                            .transition(.opacity)
                            .onAppear {
                                viewModel.showEmptyView = false
                                Debouncer(delay: 2.0).schedule {
                                    viewModel.showPostAlert = false
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
                .onChange(of: scrollPosition) { oldPostId, newPostId in
                    if let oldIndex = viewModel.posts.firstIndex(where: { $0.id == oldPostId }),
                       let newIndex = viewModel.posts.firstIndex(where: { $0.id == newPostId }) {
                        if newIndex > oldIndex {
                            Task {
                                await viewModel.loadMoreContentIfNeeded(currentPost: newPostId)
                            }
                            viewModel.updateCache(scrollPosition: newPostId)
                        }
                    }
                }
                .onChange(of: showSearchView) { oldValue, newValue in
                    pauseVideo = newValue
                }
                .fullScreenCover(isPresented: $showSearchView) {
                    SearchView()
                }
                .onChange(of: showFilters) { oldValue, newValue in
                    pauseVideo = newValue
                }
                .fullScreenCover(isPresented: $showFilters) {
                    FiltersView(filtersViewModel: filtersViewModel)
                }
                .navigationBarHidden(true)
                .onChange(of: viewModel.showPostAlert) { oldValue, newValue in
                    if newValue {
                        showSuccessMessage = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            showSuccessMessage = false
                        }
                    }
                }
                .fullScreenCover(item: $selectedPost) { post in
                    NavigationStack {
                        SecondaryFeedView(viewModel: viewModel, hideFeedOptions: false, initialScrollPosition: post.id, titleText: ("Discover"))
                    }
                }
                .sheet(isPresented: $showLocationFilter) {
                    NavigationStack {
                        LocationFilter(filtersViewModel: filtersViewModel)
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
            }
        }
    }
    
    private func refreshFeed() async {
        isRefreshing = true
        do {
            try await viewModel.fetchInitialPosts(withFilters: viewModel.filters)
        } catch {
            print("Error refreshing: \(error)")
        }
        isRefreshing = false
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
                    Image(systemName: "Skip")
                        .resizable()
                        .frame(width: 40, height: 40)
                    Text(text)
                        .foregroundColor(.white)
                        .font(.custom("MuseoSansRounded-300", size: 16))
                        .bold()
                }
                .padding()
                .background(Color.gray.opacity(1.0))
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

struct ConditionalSafeAreaPadding: ViewModifier {
    var condition: Bool
    var padding: CGFloat
    
    func body(content: Content) -> some View {
        if condition {
            content.safeAreaPadding(.vertical, padding)
        } else {
            content
        }
    }
}

extension View {
    func conditionalSafeAreaPadding(_ condition: Bool, padding: CGFloat) -> some View {
        self.modifier(ConditionalSafeAreaPadding(condition: condition, padding: padding))
    }
}

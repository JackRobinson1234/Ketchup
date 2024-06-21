//
//  FeedView.swift
//  Foodi
//
//  Created by Jack Robinson on 2/1/24.
//

import SwiftUI
import AVKit
import Combine

struct FeedView: View {
    @ObservedObject var videoCoordinator: VideoPlayerCoordinator
    @StateObject var viewModel: FeedViewModel
    @State var scrollPosition: String?
    @State private var showSearchView = false
    @State private var showFilters = false
    @State private var isLoading = true
    @State private var selectedFeed: FeedType = .discover
    @State var pauseVideo = false
    @StateObject var filtersViewModel: FiltersViewModel
    @Environment(\.dismiss) var dismiss
    private var hideFeedOptions: Bool
    @State var startingPostId: String?
    private var titleText: String
    @State private var showSuccessMessage = false
    
    init(videoCoordinator: VideoPlayerCoordinator, viewModel: FeedViewModel, hideFeedOptions: Bool = false, initialScrollPosition: String? = nil, titleText: String = "") {
        self.videoCoordinator = videoCoordinator
        self._viewModel = StateObject(wrappedValue: viewModel)
        self._filtersViewModel = StateObject(wrappedValue: FiltersViewModel(feedViewModel: viewModel))
        self.hideFeedOptions = hideFeedOptions
        self._scrollPosition = State(initialValue: initialScrollPosition)
        self.titleText = titleText
        self.startingPostId = viewModel.startingPostId
    }

    var body: some View {
        if isLoading && viewModel.posts.isEmpty {
            ProgressView("Loading...")
                .onAppear {
                    Task {
                        await viewModel.fetchInitialPosts()
                        isLoading = false
                    }
                }
                .toolbar(.hidden, for: .tabBar)
        } else {
            NavigationStack {
                ZStack(alignment: .top) {
                    if viewModel.feedViewOption == .feed {
                        ScrollViewReader { scrollProxy in
                            ScrollView(showsIndicators: false) {
                                LazyVStack(spacing: 0) {
                                    ForEach($viewModel.posts) { post in
                                        FeedCell(post: post, viewModel: viewModel, scrollPosition: $scrollPosition, pauseVideo: $pauseVideo, hideFeedOptions: hideFeedOptions)
                                            .id(post.id)
                                    }
                                }
                                .onAppear {
                                    if hideFeedOptions {
                                        Debouncer(delay: 0.5).schedule {
                                            viewModel.combineEarlyPosts()
                                        }
                                    } else {
                                        scrollProxy.scrollTo(viewModel.startingPostId, anchor: .top)
                                        viewModel.startingPostId = ""
                                    }
                                }
                            }
                            .scrollTargetLayout()
                            .scrollPosition(id: $scrollPosition)
                            .scrollTargetBehavior(.paging)
                        }
                        .animation(.easeInOut(duration: 0.5), value: viewModel.feedViewOption)
                    } else if viewModel.feedViewOption == .grid {
                        ScrollView(showsIndicators: false) {
                            VStack {
                                FeedGridView(viewModel: viewModel)
                            }
                        }
                        .scrollTargetLayout()
                        .scrollPosition(id: $scrollPosition)
                        .animation(.easeInOut(duration: 0.5), value: viewModel.feedViewOption)
                    }
                    
                    if viewModel.feedViewOption == .grid {
                        Color.white
                            .frame(height: 135)
                            .edgesIgnoringSafeArea(.top)
                    }
                    
                    if !hideFeedOptions {
                        HStack(spacing: 0) {
                            Image("KetchupTextWhite")
                                .resizable()
                                .scaledToFill()
                                .frame(width: 60, height: 17)
                            
                            Spacer()
                            ZStack {
                                Color.white.opacity(0.3)
                                    .cornerRadius(15)
                                    .frame(width: 100, height: 45)
                                HStack(spacing: 10) {
                                    Button {
                                        viewModel.feedViewOption = .grid
                                    } label: {
                                        ZStack {
                                            if viewModel.feedViewOption == .grid {
                                                Color("Colors/AccentColor")
                                                    .cornerRadius(12)
                                                    .frame(width: 38, height: 38)
                                            }
                                            Image(systemName: "square.grid.2x2")
                                                .font(.title)
                                                .foregroundColor(viewModel.feedViewOption == .grid ? .white : .gray)
                                                .fontWeight(viewModel.feedViewOption == .grid ? .bold : .regular)
                                        }
                                    }
                                    .disabled(viewModel.feedViewOption == .grid)
                                    
                                    Button {
                                        viewModel.feedViewOption = .feed
                                    } label: {
                                        ZStack {
                                            if viewModel.feedViewOption == .feed {
                                                Color("Colors/AccentColor")
                                                    .cornerRadius(12)
                                                    .frame(width: 38, height: 38)
                                            }
                                            Image(systemName: "line.3.horizontal")
                                                .font(.title)
                                                .foregroundColor(viewModel.feedViewOption == .feed ? .white : .gray)
                                                .fontWeight(viewModel.feedViewOption == .feed ? .bold : .regular)
                                        }
                                    }
                                    .disabled(viewModel.feedViewOption == .feed)
                                }
                            }
                            Spacer()
                            HStack(spacing: 10) {
                                Button {
                                    showSearchView.toggle()
                                } label: {
                                    Image(systemName: "magnifyingglass")
                                        .font(.system(size: 27))
                                }
                                Button {
                                    showFilters.toggle()
                                } label: {
                                    ZStack {
                                        Image(systemName: "slider.horizontal.3")
                                            .imageScale(.large)
                                            .shadow(radius: 4)
                                            .font(.system(size: 23))
                                        
                                        if !filtersViewModel.filters.isEmpty {
                                            Circle()
                                                .fill(Color("Colors/AccentColor"))
                                                .frame(width: 12, height: 12)
                                                .offset(x: 12, y: 12)
                                        }
                                    }
                                }
                            }
                            .frame(width: 60)
                        }
                        .frame(maxWidth: .infinity)
                        .ignoresSafeArea()
                        .padding(.top, 70)
                        .padding(.horizontal, 40)
                        .foregroundStyle(.white)
                        .padding(.bottom, 10)
                        .shadow(color: Color.gray.opacity(0.7), radius: 5, x: 0, y: 0)
                    } else {
                        HStack {
                            Button {
                                dismiss()
                            } label: {
                                Image(systemName: "chevron.left")
                                    .foregroundStyle(.white)
                                    .background(
                                        Circle()
                                            .fill(Color.gray.opacity(0.5)) // Adjust the opacity as needed
                                            .frame(width: 40, height: 40) // Adjust the size as needed
                                    )
                                    .padding()
                            }
                            Spacer()
                            
                            Text(titleText)
                                .foregroundStyle(.white)
                                .font(.headline)
                                .lineLimit(1)
                                .minimumScaleFactor(0.5)
                            Spacer()
                            Rectangle()
                                .frame(width: 40, height: 40)
                                .foregroundStyle(.clear)
                        }
                        .padding(30)
                        .padding(.vertical)
                       
                    }
                }
                .overlay {
                    if viewModel.showEmptyView {
                        ContentUnavailableView("No posts to show", systemImage: "eye.slash")
                            .foregroundStyle(Color("Colors/AccentColor"))
                    }
                    if viewModel.showPostAlert {
                        SuccessMessageOverlay(text: "Post Uploaded!")
                            .transition(.opacity)
                            .onAppear{
                                Debouncer(delay: 2.0).schedule{
                                    viewModel.showPostAlert = false
                                }
                            }
                    }
                    if viewModel.showRepostAlert {
                        SuccessMessageOverlay(text: "Reposted!")
                            .transition(.opacity)
                            .onAppear{
                                Debouncer(delay: 2.0).schedule{
                                    viewModel.showRepostAlert = false
                                }
                            }
                    }
                }
                .onChange(of: scrollPosition) { oldValue, newValue in
                    if !hideFeedOptions {
                        Task {
                            await viewModel.loadMoreContentIfNeeded(currentPost: newValue)
                        }
                        viewModel.updateCache(scrollPosition: newValue)
                    }
                }
                .background(Color("Colors/HingeGray"))
                .ignoresSafeArea()
                .navigationDestination(for: PostUser.self) { user in
                    ProfileView(uid: user.id)
                }
                .navigationDestination(for: SearchModelConfig.self) { config in
                    SearchView(searchConfig: config)
                }
                .navigationDestination(for: PostRestaurant.self) { restaurant in
                    RestaurantProfileView(restaurantId: restaurant.id)
                }
                .onChange(of: showSearchView) { oldValue, newValue in
                    pauseVideo = newValue
                }
                .fullScreenCover(isPresented: $showSearchView) {
                    SearchView(searchConfig: .restaurants, searchSlideBar: true)
                }
                .onChange(of: showFilters) { oldValue, newValue in
                    pauseVideo = newValue
                }
                .fullScreenCover(isPresented: $showFilters) {
                    FiltersView(filtersViewModel: filtersViewModel)
                }
                .navigationBarHidden(true)
                .onChange(of: viewModel.showPostAlert) {oldValue, newValue in
                    if newValue {
                        showSuccessMessage = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            showSuccessMessage = false
                        }
                    }
                }
               
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
                    Image(systemName: "checkmark")
                        .resizable()
                        .frame(width: 40, height: 40)
                        .foregroundColor(.green)
                    Text(text)
                        .foregroundColor(.white)
                        .font(.subheadline)
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


#Preview {
    FeedView(videoCoordinator: VideoPlayerCoordinator(), viewModel: FeedViewModel())
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

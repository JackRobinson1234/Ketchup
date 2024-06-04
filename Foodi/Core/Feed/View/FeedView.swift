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
    
    //MARK: Variables
    @ObservedObject var videoCoordinator: VideoPlayerCoordinator
    @StateObject var viewModel: FeedViewModel
    @State private var scrollPosition: String?
    @State private var showSearchView = false
    @State private var showFilters = false
    @State private var isLoading = true
    @State private var selectedFeed: FeedType = .discover
    @State var pauseVideo = false
    private var posts: [Post]
    //@State private var fetchTask: Task<Void, Error>?
    @StateObject var filtersViewModel: FiltersViewModel
    @State var feedViewOption: FeedViewOption = .feed
    @Environment(\.dismiss) var dismiss
    private var hideFeedOptions: Bool
    
    
    
    
    init(videoCoordinator: VideoPlayerCoordinator, posts: [Post] = [], hideFeedOptions: Bool = false) {
        self.videoCoordinator = videoCoordinator
        let viewModel = FeedViewModel(posts: posts)
        self._viewModel = StateObject(wrappedValue: viewModel)
        self.posts = posts
        self._filtersViewModel = StateObject(wrappedValue: FiltersViewModel(feedViewModel: viewModel))
        self.hideFeedOptions = hideFeedOptions
        
    }
    
    var body: some View {
        /// Loading screen will only appear when the app first opens and will fetch posts
        if isLoading && posts.isEmpty {
            // Loading screen
            ProgressView("Loading...")
                .onAppear {
                    Task {
                        await viewModel.fetchInitialPosts()
                        isLoading = false
                    }
                }
                .toolbar(.hidden, for: .tabBar)
        } else {
            //MARK: Video Cells
            NavigationStack {
                ZStack(alignment: .topTrailing) {
                        if feedViewOption == .feed {
                            ScrollView(showsIndicators: false) {
                                LazyVStack(spacing: 0) {
                                    ForEach($viewModel.posts) { post in
                                        FeedCell(post: post, viewModel: viewModel, scrollPosition: $scrollPosition, pauseVideo: $pauseVideo)
                                            .id(post.id)
                                    }
                                }
                                
                            }
                            .scrollTargetLayout()
                            .scrollPosition(id: $scrollPosition)
                            .scrollTargetBehavior(.paging)
                        }
                           
                        else if feedViewOption == .grid {
                            ScrollView(showsIndicators: false) {
                                VStack{
                                    FeedGridView(viewModel: viewModel)
                                }
                            }
                        }
            
                    
                    
                    if !hideFeedOptions {
                        HStack(spacing: 0) {
                            Image("KetchupTextWhite")
                                .resizable()
                                .scaledToFill()
                                .frame(width: 60, height: 17)
                                .padding(.horizontal)
                            
                            // Button for "Grid"
                            Spacer()
                            ZStack {
                                Color.white.opacity(0.1) // Adjust opacity as needed
                                    .cornerRadius(15)
                                    .frame(width: 100, height: 45)
                                HStack(spacing: 10){
                                    Button{
                                        feedViewOption = .grid
                                        
                                    } label: {
                                        ZStack {
                                            if feedViewOption == .grid {
                                                Color("Colors/AccentColor") // Red background for selected option
                                                    .cornerRadius(12) // Adjust corner radius as needed
                                                    .frame(width: 38, height: 38) // Adjust size as needed
                                            }
                                            Image(systemName: "square.grid.2x2")
                                                .font(.title)
                                                .foregroundColor(feedViewOption == .grid ? .white : .gray)
                                                .fontWeight(feedViewOption == .grid ? .bold : .regular)
                                        }
                                        
                                    }
                                    .disabled(feedViewOption == .grid)
                                    
                                    // Vertical Line
                                    
                                    
                                    // Button for "Feed"
                                    Button{
                                        feedViewOption = .feed
                                        
                                    } label: {
                                        ZStack {
                                            if feedViewOption == .feed {
                                                Color("Colors/AccentColor") // Red background for selected option
                                                    .cornerRadius(12) // Adjust corner radius as needed
                                                    .frame(width: 38, height: 38) // Adjust size as needed
                                            }
                                            Image(systemName: "line.3.horizontal")
                                                .font(.title)
                                                .foregroundColor(feedViewOption == .feed ? .white : .gray)
                                                .fontWeight(feedViewOption == .feed ? .bold : .regular)
                                        }
                                        //.frame(width: 78)
                                    }
                                    .disabled(feedViewOption == .feed)
                                }
                            }
                            Spacer()
                            HStack (spacing: 10) {
                                Button{
                                    showSearchView.toggle()
                                    
                                } label: {
                                    Image(systemName: "magnifyingglass")
                                        .font(.system(size: 27))
                                }
                                //MARK: Filters Button
                                Button {
                                    showFilters.toggle()
                                }
                            label: {
                                ZStack {
                                    Image(systemName: "slider.horizontal.3")
                                        .imageScale(.large)
                                        .shadow(radius: 4)
                                        .font(.system(size: 23))
                                    
                                    
                                    if !filtersViewModel.filters.isEmpty {
                                        Circle()
                                            .fill(Color("Colors/AccentColor"))
                                            .frame(width: 12, height: 12)
                                            .offset(x: 12, y: 12) // Adjust the offset as needed
                                    }
                                }
                            }
                                //MARK: Filters and Search Buttons
                            }
                        }
                        .padding(.top, 70)
                        .padding(.horizontal, 20)
                        .frame(maxWidth: .infinity)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.bottom, 10)
                        //.opacity(1)
                        .shadow(color: Color.gray.opacity(0.5), radius: 5, x: 0, y: 5)
                    }
                    
                }
                
                
                
                //MARK: Loading/ No posts
                
                //MARK: Navigation
                
                .overlay {
                    if viewModel.showEmptyView {
                        ContentUnavailableView("No posts to show", systemImage: "eye.slash")
                            .foregroundStyle(Color("Colors/AccentColor"))
                    }
                }
                /// loads the next 5 videos in the cache
                .onChange(of: scrollPosition) {oldValue, newValue in
                    Task {
                        await viewModel.loadMoreContentIfNeeded(currentPost: newValue)
                    }
                    viewModel.updateCache(scrollPosition: newValue)
                    }
                .background(Color("Colors/HingeGray"))
                //.background(.black)
                .ignoresSafeArea()
                
                /// sets destination of user profile links
                .navigationDestination(for: PostUser.self) { user in
                    ProfileView(uid: user.id)
                }
                
                /// sets destination of searchview for the search button
                .navigationDestination(for: SearchModelConfig.self) { config in
                    SearchView(searchConfig: config)}
                
                /// sets the destination of the restaurant profile when the restaurant profile is clicked
                .navigationDestination(for: PostRestaurant.self) { restaurant in
                    RestaurantProfileView(restaurantId: restaurant.id)}
                
                /// pauses the video when search button is clicked
                .onChange(of: showSearchView) { oldValue, newValue in
                    if newValue {
                        pauseVideo = true
                    }
                    else {
                        pauseVideo = false
                    }
                }
                /// puts the search view in view when search button is clicked
                .fullScreenCover(isPresented: $showSearchView) {
                    SearchView(searchConfig: .restaurants, searchSlideBar: true)
                }
                /// pauses the video when filters are shown
                .onChange(of: showFilters) { oldValue, newValue in
                    if newValue {
                        pauseVideo = true
                    }
                    else {
                        pauseVideo = false
                    }
                }
                
                /// presents the filters view when filters are clicked
                .fullScreenCover(isPresented: $showFilters) {
                    FiltersView(filtersViewModel: filtersViewModel)
                }
                .toolbar {
                    if hideFeedOptions{
                        ToolbarItem(placement: .topBarLeading) {
                            Button {
                                dismiss()
                            } label: {
                                Image(systemName: "chevron.left")
                                    .foregroundStyle(.white)
                                    .background(
                                        Circle()
                                            .fill(Color.gray.opacity(0.5)) // Adjust the opacity as needed
                                            .frame(width: 30, height: 30) // Adjust the size as needed
                                    )
                                    .padding()
                            }
                        }
                    }
                }
                
            }
        }
    }
}


#Preview {
    FeedView(videoCoordinator: VideoPlayerCoordinator(), posts: DeveloperPreview.posts)
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

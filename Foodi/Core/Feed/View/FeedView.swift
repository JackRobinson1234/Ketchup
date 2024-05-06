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
    @State private var path = NavigationPath()
    @State private var showSearchView = false
    @State private var showFilters = false
    @State private var isLoading = true
    @State private var selectedFeed: FeedType = .discover
    @State var pauseVideo = false
    private var posts: [Post]
    @State private var fetchTask: Task<Void, Error>?
    @StateObject var filtersViewModel: FiltersViewModel
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
                            await viewModel.fetchPosts()
                            isLoading = false
                        }
                    }
                    .toolbar(.hidden, for: .tabBar)
        } else {
        //MARK: Video Cells
        NavigationStack(path: $path) {
            ZStack(alignment: .topTrailing) {
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 0) {
                        ForEach($viewModel.posts) { post in
                            FeedCell(post: post, viewModel: viewModel, scrollPosition: $scrollPosition, pauseVideo: $pauseVideo)
                                .id(post.id)
                            
                        }
                        
                    }
                    .scrollTargetLayout()
                }
                
                
                //MARK: Discover and Following
                if !hideFeedOptions {
                    HStack() {
                        // Button for "Following"
                        Button(action: {
                            fetchTask?.cancel()
                            viewModel.posts.removeAll()
                            selectedFeed = .following
                            viewModel.setFeedType(.following)
                            fetchTask = Task {
                                await viewModel.fetchPosts()
                                
                            }
                        }) {
                            Text("Following")
                                .foregroundColor(selectedFeed == .following ? .white : .gray)
                                .fontWeight(selectedFeed == .following ? .bold : .regular)
                                .frame(width: 78)
                        }
                        .disabled(selectedFeed == .following)
                        
                        // Vertical Line
                        Rectangle()
                            .frame(width: 2, height: 18)
                            .foregroundColor(.gray)
                        
                        // Button for "Recommended"
                        Button(action: {
                            fetchTask?.cancel()
                            viewModel.posts.removeAll()
                            selectedFeed = .discover
                            viewModel.setFeedType(.discover)
                            fetchTask = Task {
                                await viewModel.fetchPosts()
                                
                            }
                            
                        }) {
                            Text("Discover")
                                .foregroundColor(selectedFeed == .discover ?
                                    .white : .gray)
                                .fontWeight(selectedFeed == .discover ? .bold : .regular)
                                .frame(width: 78)
                        }
                        .disabled(selectedFeed == .discover)
                    }
                    .padding(.top, 70)
                    .padding(.horizontal)
                    .frame(maxWidth: .infinity)
                    //MARK: Filters and Search Buttons
                    HStack{
                        Button{
                            showSearchView.toggle()
                            
                        } label: {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 27))
                        }
                        Spacer()
                        Button {
                            showFilters.toggle()
                            
                        }
                    label: {
                        Image(systemName: "slider.horizontal.3")
                            .imageScale(.large)
                            .shadow(radius: 4)
                            .font(.system(size: 23))
                    }
                        
                    }
                    .padding(32)
                    .padding(.top, 20)
                    .foregroundStyle(.white)
                }
            }
            
            
            
            //MARK: Loading/ No posts
            
            //MARK: Navigation
            .scrollPosition(id: $scrollPosition)
            .scrollTargetBehavior(.paging)
            .overlay {
                if viewModel.showEmptyView {
                    ContentUnavailableView("No posts to show", systemImage: "eye.slash")
                        .foregroundStyle(.white)
                }
            }
            /// loads the next 3 videos in the cache
            .onChange(of: scrollPosition) {oldValue, newValue in
                viewModel.updateCache(scrollPosition: newValue)
            }
            .background(.black)
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
        }
    }
}
    
}


#Preview {
    FeedView(videoCoordinator: VideoPlayerCoordinator(), posts: DeveloperPreview.posts)
}

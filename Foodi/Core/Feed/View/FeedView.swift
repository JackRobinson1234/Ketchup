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
    private let userService: UserService
    @State var pauseVideo = false
    private var posts: [Post]
    @State private var fetchTask: Task<Void, Error>?
    

        
    
    init(videoCoordinator: VideoPlayerCoordinator, posts: [Post] = [], userService: UserService) {
        self.videoCoordinator = videoCoordinator
        let viewModel = FeedViewModel(
            postService: PostService(),
            posts: posts)
        self._viewModel = StateObject(wrappedValue: viewModel)
        self.userService = userService
        self.posts = posts
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
                ScrollView {
                        LazyVStack(spacing: 0) {
                                ForEach($viewModel.posts) { post in
                                    FeedCell(post: post, viewModel: viewModel, scrollPosition: $scrollPosition, pauseVideo: $pauseVideo)
                                        .id(post.id)
                                    
                                }
                                
                    }
                        .scrollTargetLayout()
                }
                
                
               //MARK: Discover and Following
                
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
            .background(.black)
            .ignoresSafeArea()
            .navigationDestination(for: postUser.self) { user in
                ProfileView(uid: user.id, userService: userService)
            }
            .navigationDestination(for: SearchModelConfig.self) { config in
                SearchView(userService: UserService(), searchConfig: config)}
            .navigationDestination(for: postRestaurant.self) { restaurant in
                RestaurantProfileView(restaurantId: restaurant.id)}
            
            .onChange(of: showSearchView) { oldValue, newValue in
                if newValue {
                    pauseVideo = true
                }
                else {
                    pauseVideo = false
                }
            }
            .onChange(of: scrollPosition, { oldValue, newValue in
                print("Scroll Position : \(newValue)")
            })
            
            .fullScreenCover(isPresented: $showSearchView) {
                SearchView(userService: userService, searchConfig: .users(userListConfig: .users), searchSlideBar: true)
            }
            .onChange(of: showFilters) { oldValue, newValue in
                if newValue {
                    pauseVideo = true
                }
                else {
                    pauseVideo = false
                }
            }
            .fullScreenCover(isPresented: $showFilters) {
                FiltersView()
            }
        }
    }
}
    
}


#Preview {
    FeedView(videoCoordinator: VideoPlayerCoordinator(), posts: DeveloperPreview.posts, userService: UserService())
}



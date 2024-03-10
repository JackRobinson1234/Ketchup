//
//  FeedView.swift
//  Foodi
//
//  Created by Jack Robinson on 2/1/24.
//

import SwiftUI
import AVKit


struct FeedView: View {
    
    //MARK: Variables
    @Binding var player: AVPlayer
    @StateObject var viewModel: FeedViewModel
    @State private var visiblePostID: String?
    @State private var path = NavigationPath()
    @State private var showSearchView = false
    @State private var showFilters = false
    @State private var isLoading = true
    @State private var selectedFeed: FeedType = .discover
    private let userService: UserService
    
    
    init(player: Binding<AVPlayer>, posts: [Post] = [], userService: UserService) {
        self._player = player
        
        let viewModel = FeedViewModel(
            postService: PostService(),
            posts: posts)
        self._viewModel = StateObject(wrappedValue: viewModel)
        self.userService = userService
    }
    
    var body: some View {
        if isLoading {
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
        //MARK: Video
        NavigationStack(path: $path) {
            ZStack(alignment: .topTrailing) {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach($viewModel.posts) { post in
                            FeedCell(post: post, player: player, viewModel: viewModel)
                                .id(post.id)
                                .onAppear { playInitialVideoIfNecessary(forPost: post.wrappedValue) }
                            
                        }
                    }
                    .scrollTargetLayout()
                }
                //MARK: Search + Filters
                // Toggle Button
                
                HStack() {
                    // Button for "Following"
                    Button(action: {
                        selectedFeed = .following
                        viewModel.setFeedType(.following)
                        player.replaceCurrentItem(with: nil)
                        Task {
                            await viewModel.fetchPosts()
                            isLoading = false
                            updatePlayerWithFirstPostVideo()
                        }
                    }) {
                        Text("Following")
                            .foregroundColor(selectedFeed == .following ? .white : .gray)
                            .fontWeight(selectedFeed == .following ? .bold : .regular)
                            .frame(width: 78)
                    }
                    
                    // Vertical Line
                    Rectangle()
                        .frame(width: 2, height: 18)
                        .foregroundColor(.gray)
                    
                    // Button for "Recommended"
                    Button(action: {
                        selectedFeed = .discover
                        viewModel.setFeedType(.discover)
                        player.replaceCurrentItem(with: nil)
                        Task {
                            await viewModel.fetchPosts()
                            isLoading = false
                            updatePlayerWithFirstPostVideo()
                        }
                    }) {
                        Text("Discover")
                            .foregroundColor(selectedFeed == .discover ?
                                .white : .gray)
                            .fontWeight(selectedFeed == .discover ? .bold : .regular)
                            .frame(width: 78)
                    }
                }
                .padding(.top, 70)
                .padding(.horizontal)
                .frame(maxWidth: .infinity)
                
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
            .background(.black)
            .onAppear { player.play() }
            .onDisappear { player.pause() }
            
            //MARK: Loading/ No posts
            .overlay {
                if viewModel.showEmptyView {
                    ContentUnavailableView("No posts to show", systemImage: "eye.slash")
                        .foregroundStyle(.white)
                }
            }
            //MARK: Navigation
            .scrollPosition(id: $visiblePostID)
            .scrollTargetBehavior(.paging)
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
                    player.pause()
                }
                else {
                    player.play()
                }
            }
            
            .fullScreenCover(isPresented: $showSearchView) {
                SearchView(userService: userService, searchConfig: .users(userListConfig: .users), searchSlideBar: true)
            }
            .onChange(of: showFilters) { oldValue, newValue in
                if newValue {
                    player.pause()
                }
                else {
                    player.play()
                }
            }
            .fullScreenCover(isPresented: $showFilters) {
                FiltersView()
            }
            .onChange(of: visiblePostID, { oldValue, newValue in
                print("DEBUG: Scroll position changed from \(oldValue ?? "nil") to \(newValue ?? "nil")")
                playVideoOnChangeOfScrollPosition(postId: newValue)
            })
        }
    }
}
    
    //MARK: Playing/ pausing
    func playInitialVideoIfNecessary(forPost post: Post) {
        guard
            visiblePostID == nil,
            let post = viewModel.posts.first,
            player.currentItem == nil else { return }
        
        player.replaceCurrentItem(with: AVPlayerItem(url: URL(string: post.videoUrl)!))
    }
    
    func playVideoOnChangeOfScrollPosition(postId: String?) {
        guard let currentPost = viewModel.posts.first(where: {$0.id == postId }) else { return }
        player.replaceCurrentItem(with: nil)
        let playerItem = AVPlayerItem(url: URL(string: currentPost.videoUrl)!)
        player.replaceCurrentItem(with: playerItem)
    }
    
    func updatePlayerWithFirstPostVideo() {
        guard let firstPostVideoUrl = viewModel.posts.first?.videoUrl, let url = URL(string: firstPostVideoUrl) else { return }
        let playerItem = AVPlayerItem(url: url)
        player.replaceCurrentItem(with: playerItem)
    }
    
}


#Preview {
    FeedView(player: .constant(AVPlayer()), posts: DeveloperPreview.posts, userService: UserService())
}



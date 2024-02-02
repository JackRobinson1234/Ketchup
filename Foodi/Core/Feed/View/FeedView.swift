//
//  FeedView.swift
//  Foodi
//
//  Created by Jack Robinson on 2/1/24.
//

import SwiftUI
import AVKit

struct FeedView: View {
    @Binding var player: AVPlayer
    @StateObject var viewModel: FeedViewModel
    @State private var scrollPosition: String?
    @State private var path = NavigationPath()
    @State private var showSearchView = false
    @State private var showFilters = false
    private let userService: UserService
    
    
    init(player: Binding<AVPlayer>, posts: [Post] = [], userService: UserService) {
        self._player = player
        
        let viewModel = FeedViewModel(feedService: FeedService(),
                                      postService: PostService(),
                                      posts: posts)
        self._viewModel = StateObject(wrappedValue: viewModel)
        self.userService = userService
    }
    
    var body: some View {
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
                HStack{
                    /* Button {
                        Task { await viewModel.refreshFeed() }
                    } label: {
                        Image(systemName: "arrow.counterclockwise")
                            .imageScale(.large)
                            .shadow(radius: 4)
                    }*/
                    Button{
                        showSearchView.toggle()
                      
                    } label: {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 22))
                    }
                    Spacer()
                    Button {
                        showFilters.toggle()
                    }
                     label: {
                        Image(systemName: "slider.horizontal.3")
                            .imageScale(.large)
                            .shadow(radius: 4)
                    }
                    
                }
                .padding(32)
                .padding(.top)
                .foregroundStyle(.white)
            }
            .background(.black)
            .onAppear { player.play() }
            .onDisappear { player.pause() }
            .overlay {
                if viewModel.isLoading {
                    ProgressView()
                } else if viewModel.showEmptyView {
                    ContentUnavailableView("No posts to show", systemImage: "eye.slash")
                        .foregroundStyle(.white)
                }
            }
            .scrollPosition(id: $scrollPosition)
            .scrollTargetBehavior(.paging)
            .ignoresSafeArea()
            .navigationDestination(for: User.self) { user in
                ProfileView(user: user, userService: userService)
            }
            .navigationDestination(for: SearchModelConfig.self) { config in
                SearchView(userService: UserService(), searchConfig: config)}
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
            .onChange(of: scrollPosition, { oldValue, newValue in
                playVideoOnChangeOfScrollPosition(postId: newValue)
            })
        }
    }
    
    func playInitialVideoIfNecessary(forPost post: Post) {
        guard
            scrollPosition == nil,
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
}

#Preview {
    FeedView(player: .constant(AVPlayer()), posts: DeveloperPreview.posts, userService: UserService())
}

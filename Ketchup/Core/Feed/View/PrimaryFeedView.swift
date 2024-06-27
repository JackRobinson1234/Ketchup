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
    private var hideFeedOptions: Bool
    @State var startingPostId: String?
    private var titleText: String
    @State private var showSuccessMessage = false
    @State var selectedPost: Post?
    init(viewModel: FeedViewModel, hideFeedOptions: Bool = false, initialScrollPosition: String? = nil, titleText: String = "") {
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
            
            ZStack(alignment: .top) {
                ScrollViewReader { scrollProxy in
                    ScrollView(showsIndicators: false) {
                        LazyVStack() {
                            ForEach($viewModel.posts) { post in
                                WrittenFeedCell(viewModel: viewModel, post: post, scrollPosition: $scrollPosition, pauseVideo: $pauseVideo, selectedPost: $selectedPost)
                                    .id(post.id)
                                
                            }
                            Rectangle()
                                .foregroundStyle(.clear)
                                .onAppear{
                                    print("CLEAR APPEARED")
                                    if let last = viewModel.posts.last {
                                        Task {
                                            if !hideFeedOptions{
                                                await viewModel.loadMoreContentIfNeeded(currentPost: last.id)
                                            }
                                        }
                                    }
                                }
                        }
                        .scrollTargetLayout()
                    }
                    .transition(.slide)
                    .conditionalSafeAreaPadding(!hideFeedOptions, padding: 115)
                    .scrollPosition(id: $scrollPosition)
                    .onAppear {
                        if hideFeedOptions {
                            Debouncer(delay: 0.5).schedule {
                                viewModel.combineEarlyPosts()
                            }
                        } else {
                            print("Scrolling to ", viewModel.startingPostId)
                            scrollProxy.scrollTo(viewModel.scrollPosition, anchor: .center)
                            viewModel.startingPostId = ""
                        }
                    }
                }
                
                
                if !hideFeedOptions{
                    Color.white
                        .frame(height: 100)
                        .edgesIgnoringSafeArea(.top)
                }
                
                if !hideFeedOptions {
                    HStack(spacing: 0) {
                        
                        Button {
                            showSearchView.toggle()
                        } label: {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 27))
                                .frame(width: 60)
                        }
                        Spacer()
                        Image("KetchupTextRed")
                            .resizable()
                            .scaledToFill()
                            .frame(width: 60, height: 17)
                        
                        Spacer()
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
                            .frame(width: 60)
                        }
                        
                    }
                    .frame(maxWidth: .infinity)
                    .ignoresSafeArea()
                    .padding(.top, 55)
                    .padding(.horizontal, 20)
                    .foregroundStyle(.primary)
                    .padding(.bottom, 10)
                    
                }
            }
            .animation(.easeInOut(duration: 0.5), value: viewModel.feedViewOption)
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
            .onChange(of: scrollPosition) { oldPostId, newPostId in
                // Get the indices of the old and new post IDs
                if let oldIndex = viewModel.posts.firstIndex(where: { $0.id == oldPostId }),
                   let newIndex = viewModel.posts.firstIndex(where: { $0.id == newPostId }) {
                    
                    // Ensure that we only proceed if the new post index is greater than the old post index (scrolling down)
                    if newIndex > oldIndex {
                        if !hideFeedOptions {
                            Task {
                                await viewModel.loadMoreContentIfNeeded(currentPost: newPostId)
                            }
                        }
                        viewModel.updateCache(scrollPosition: newPostId)
                    }
                }
            }
            
            .background(Color("Colors/HingeGray"))
            .ignoresSafeArea()
            
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
            .onChange(of: viewModel.showPostAlert) {oldValue, newValue in
                if newValue {
                    showSuccessMessage = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        showSuccessMessage = false
                    }
                }
            }
            .fullScreenCover(item: $selectedPost) { post in
                NavigationStack{
                    SecondaryFeedView( viewModel: viewModel, hideFeedOptions: false, initialScrollPosition: post.id, titleText: ("Discover"))
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

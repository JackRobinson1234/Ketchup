//
//  PrimaryFeed.swift
//  Ketchup
//
//  Created by Jack Robinson on 6/26/24.
//

import SwiftUI

struct IOS16SecondaryFeedView: View {
    @ObservedObject var viewModel: FeedViewModel
    @State var scrollPosition: String?
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
    var checkLikes: Bool
    
    init(viewModel: FeedViewModel, hideFeedOptions: Bool = false, initialScrollPosition: String? = nil, titleText: String = "", checkLikes: Bool = false) {
        self.viewModel = viewModel
        self._filtersViewModel = StateObject(wrappedValue: FiltersViewModel(feedViewModel: viewModel))
        self.hideFeedOptions = hideFeedOptions
        self._scrollPosition = State(initialValue: initialScrollPosition)
        self.titleText = titleText
        self.checkLikes = checkLikes
        self.startingPostId = viewModel.startingPostId
    }
    
    var body: some View {
            ZStack(alignment: .top) {
                ScrollViewReader { scrollProxy in
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: 0) {
                            ForEach($viewModel.posts) { post in
                                if hasValidMedia(post.wrappedValue) {
                                    if viewModel.startingPostId == post.wrappedValue.id || viewModel.posts.count == 1 {
                                        FeedCell(post: post, viewModel: viewModel, scrollPosition: $scrollPosition, pauseVideo: $pauseVideo, hideFeedOptions: hideFeedOptions, checkLikes: checkLikes)
                                            .id(post.id)
                                            .frame(height: UIScreen.main.bounds.height)
                                            .onAppear {
                                                if scrollPosition != post.wrappedValue.id {
                                                    scrollPosition = post.wrappedValue.id
                                                    handleScrollPositionChange(newPostId: post.wrappedValue.id)
                                                }
                                            }
                                            .opacity(isLoading ? 0 : 1)
                                    }
                                }
                            }
                        }
                    }
                    .onAppear {
                        Task {
                            isLoading = true
                            scrollProxy.scrollTo(viewModel.startingPostId, anchor: .center)
                            isLoading = false
                        }
                    }
                }
            }
            
            
        
        .overlay {
            if viewModel.showPostAlert {
                SuccessMessageOverlay(text: "Post Uploaded!")
                    .transition(.opacity)
                    .onAppear {
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
//        .onChange(of: scrollPosition) { newPostId in
//            //print("SCROLL POSITION", scrollPosition)
//            if let newPostId{
//                handleScrollPositionChange(newPostId: newPostId)
//            }
//        }
        .ignoresSafeArea()
        .navigationDestination(for: PostUser.self) { user in
            ProfileView(uid: user.id)
        }
        .navigationDestination(for: PostRestaurant.self) { restaurant in
            RestaurantProfileView(restaurantId: restaurant.id)
        }
        .onChange(of: showFilters) { newValue in
            pauseVideo = newValue
        }
        .fullScreenCover(isPresented: $showFilters) {
            FiltersView(filtersViewModel: filtersViewModel)
        }
        //.navigationBarHidden(true)
        .onChange(of: viewModel.showPostAlert) { newValue in
            if newValue {
                showSuccessMessage = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    showSuccessMessage = false
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    if let scrollPosition = scrollPosition {
                        viewModel.initialPrimaryScrollPosition = scrollPosition
                    }
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .foregroundStyle(.white)
                        .background(
                            Circle()
                                .fill(Color.gray.opacity(0.5))
                                .frame(width: 30, height: 30)
                        )
                }
            }
            
            ToolbarItem(placement: .principal) {
                if hideFeedOptions {
                    Text(titleText)
                        .foregroundStyle(.black)
                        .font(.custom("MuseoSansRounded-300", size: 18))
                        .bold()
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                } else {
                    Image("KetchupTextRed")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 17)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        
    }
    
    
    private func handleScrollPositionChange(newPostId: String) {
        if let newIndex = viewModel.posts.firstIndex(where: { $0.id == newPostId }) {
            viewModel.updateCache(scrollPosition: newPostId)
            
            if !hideFeedOptions && newIndex >= viewModel.posts.count - 5 { // Load when 5 items from the end
                Task {
                    await viewModel.loadMoreContentIfNeeded(currentPost: newPostId)
                }
            }
        }
    }
    
    private func hasValidMedia(_ post: Post) -> Bool {
        switch post.mediaType {
        case .mixed:
            return post.mixedMediaUrls?.isEmpty == false
        case .video, .photo:
            return !post.mediaUrls.isEmpty
        case .written:
            return false // Assuming text-only posts should not be displayed in this feed
        }
    }
}

//
//  PrimaryFeed.swift
//  Ketchup
//
//  Created by Jack Robinson on 6/26/24.
//

import SwiftUI

struct SecondaryFeedView: View {
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
                                ZStack {
                                    Color("Colors/HingeGray")
                                        .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
                                        .ignoresSafeArea(.all)
                                    FeedCell(post: post, viewModel: viewModel, scrollPosition: $scrollPosition, pauseVideo: $pauseVideo, hideFeedOptions: hideFeedOptions, checkLikes: checkLikes)
                                }
                                .ignoresSafeArea(.all)
                                .id(post.id)
                            }
                        }
                    }
                    .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
                    .onAppear {
                       
                            scrollProxy.scrollTo(startingPostId, anchor: .center)
                        
                    }
                }
                .transition(.slide)
            }
            
            if !hideFeedOptions {
                HStack(spacing: 0) {
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
                                    .fill(Color.gray.opacity(0.5)) // Adjust the opacity as needed
                                    .frame(width: 30, height: 30)
                            )
                            .padding()
                    }
                    .frame(width: 60)
                    
                    Spacer()
                    
                    Image("KetchupTextRed")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 60, height: 17)
                    
                    Spacer()
                    Color.clear
                        .frame(width: 60, height: 17)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 55)
                .padding(.horizontal, 20)
                .foregroundStyle(.black)
                .padding(.bottom, 10)
            } else {
                HStack {
                    Button {
                        viewModel.initialPrimaryScrollPosition = scrollPosition
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .foregroundStyle(.white)
                            .background(
                                Circle()
                                    .fill(Color.gray.opacity(0.5)) // Adjust the opacity as needed
                                    .frame(width: 40, height: 40)
                            )
                            .padding()
                    }
                    Spacer()
                    
                    Text(titleText)
                        .foregroundStyle(.black)
                        .font(.custom("MuseoSansRounded-300", size: 18))
                        .bold()
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
                CustomUnavailableView(text: "No posts to show", image: "eye.slash")
                    .foregroundStyle(Color("Colors/AccentColor"))
            }
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
        .onChange(of: scrollPosition) { newPostId in
            if let newPostId = newPostId {
                handleScrollChange(newPostId: newPostId)
            }
        }
        .background(Color("Colors/HingeGray"))
        .ignoresSafeArea()
        .onChange(of: showFilters) { newValue in
            pauseVideo = newValue
        }
        .fullScreenCover(isPresented: $showFilters) {
            FiltersView(filtersViewModel: filtersViewModel)
        }
        .onChange(of: viewModel.showPostAlert) { newValue in
            if newValue {
                showSuccessMessage = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    showSuccessMessage = false
                }
            }
        }
    }
    
    private func handleScrollChange(newPostId: String) {
        if let oldIndex = viewModel.posts.firstIndex(where: { $0.id == scrollPosition }),
           let newIndex = viewModel.posts.firstIndex(where: { $0.id == newPostId }), newIndex > oldIndex {
            viewModel.updateCache(scrollPosition: newPostId)
            if !hideFeedOptions && newIndex >= viewModel.posts.count - 5 {
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
            return false
        }
    }
}
struct CustomUnavailableView: View {
    var text: String
    var image: String
    
    var body: some View {
        VStack {
            Image(systemName: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 50, height: 50)
                .foregroundStyle(.gray)
            Text(text)
                .font(.headline)
                .foregroundStyle(.gray)
        }
        .padding()
    }
}

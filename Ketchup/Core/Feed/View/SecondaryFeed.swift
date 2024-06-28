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
    
    init(viewModel: FeedViewModel, hideFeedOptions: Bool = false, initialScrollPosition: String? = nil, titleText: String = "") {
        self.viewModel = viewModel
        self._filtersViewModel = StateObject(wrappedValue: FiltersViewModel(feedViewModel: viewModel))
        self.hideFeedOptions = hideFeedOptions
        self._scrollPosition = State(initialValue: initialScrollPosition)
        self.titleText = titleText
        self.startingPostId = viewModel.startingPostId
    }
    var body: some View {
        ZStack(alignment: .top) {
            ScrollViewReader { scrollProxy in
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 0) {
                        ForEach($viewModel.posts) { post in
                            if !post.mediaUrls.isEmpty {
                                ZStack{
                                    Color.clear
                                        .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
                                        .ignoresSafeArea(.all)
                                        .containerRelativeFrame([.horizontal, .vertical])
                                        
                                    FeedCell(post: post, viewModel: viewModel, scrollPosition: $scrollPosition, pauseVideo: $pauseVideo, hideFeedOptions: hideFeedOptions)
                                }
                                .ignoresSafeArea(.all)
                                .id(post.id)
                            }
                        }
                    }
                    .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
                    .onAppear {
                        if hideFeedOptions {
                            Debouncer(delay: 0.5).schedule {
                                viewModel.combineEarlyPosts()
                            }
                        } else {
                            scrollProxy.scrollTo(viewModel.startingPostId, anchor: .center)
                        }
                    }
                }
                .transition(.slide)
                .scrollTargetLayout()
                .scrollPosition(id: $scrollPosition)
                .scrollTargetBehavior(.paging)
            }
            if !hideFeedOptions {
                HStack(spacing: 0) {
                    Button{
                        
                            if let scrollPosition = scrollPosition{
                               
                                viewModel.initialPrimaryScrollPosition = scrollPosition
                                print("Assigning SCROLL", scrollPosition)
                            }
                            print("DISMISSING SCROLL")
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
                    .frame(width: 60)
                    
                    Spacer()
                    
                    Image("KetchupTextWhite")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 60, height: 17)
                    
                    Spacer()
                    Color.clear
                        .frame(width: 60, height: 17)
                           
                           }
                    
                .frame(maxWidth: .infinity)
                .ignoresSafeArea()
                .padding(.top, 55)
                .padding(.horizontal, 20)
                .foregroundStyle(.primary)
                .padding(.bottom, 10)
                
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
        .navigationDestination(for: PostUser.self) { user in
            ProfileView(uid: user.id)
        }
        .navigationDestination(for: PostRestaurant.self) { restaurant in
            RestaurantProfileView(restaurantId: restaurant.id)
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

//#Preview {
//    SecondaryFeed()
//}

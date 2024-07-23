//
//  ActivityView.swift
//  Foodi
//
//  Created by Jack Robinson on 4/19/24.
//

import SwiftUI
enum LetsKetchupOptions {
    case friends, trending
}

struct ActivityView: View {
    @State var isLoading = true
    @State var isTransitioning = false
    @StateObject var viewModel = ActivityViewModel()
    @State var showSearchView: Bool = false
    @Namespace private var animation
    var body: some View {
        NavigationStack {
            VStack {
                if isLoading {
                    ProgressView()
                        .onAppear {
                            Task {
                                viewModel.user = AuthService.shared.userSession
                                try? await viewModel.fetchInitialActivities()
                                isLoading = false
                            }
                        }
                    
                } else {
                    ScrollView(showsIndicators: false){
                        VStack {
                            // MARK: Buttons
                            
                            HStack{
                                Image("Skip")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 40)
                                Image("KetchupTextRed")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 110)
                            }
                            
                            Divider()
                            HorizontalCollectionScrollView()
                                .padding(.bottom)
                            // MARK: Activity List
                            HStack(alignment: .top){
                                Text("Following Activity")
                                    .font(.custom("MuseoSansRounded-700", size: 25))
                                Spacer()
                                Button{
                                    showSearchView.toggle()
                                } label : {
                                    VStack{
                                        Image(systemName: "magnifyingglass")
                                            .resizable()
                                            .scaledToFit()
                                            
                                        Text("Find Friends")
                                            .font(.custom("MuseoSansRounded-300", size: 12))
                                    }
                                    .frame(height: 40)
                                    .foregroundStyle(.gray)
                                }
                            
                            }
                            .padding(.horizontal)
                            if !viewModel.followingActivity.isEmpty {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    LazyHStack(alignment: .top, spacing: 16) {
                                        ForEach(viewModel.followingActivity) { activity in
                                            ActivityCell(activity: activity, viewModel: viewModel)
                                                .onAppear {
                                                    if activity == viewModel.followingActivity.last {
                                                        viewModel.loadMore()
                                                    }
                                                }
                                        }
                                        if viewModel.isLoadingMore {
                                            ProgressView()
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            } else if viewModel.isFetching {
                                ProgressView()
                            } else {
                                Text("No activity from your friends yet.")
                                    .font(.custom("MuseoSansRounded-300", size: 16))
                                    .foregroundColor(.gray)
                                    .padding()
                            }
                        }
                    }
                    .fullScreenCover(isPresented: $showSearchView) {
                        SearchView(initialSearchConfig: .users)
                    }
                    .refreshable {
                        Task {
                            try? await viewModel.fetchInitialActivities()
                        }
                    }
                    .sheet(item: $viewModel.post){ post in
                        NavigationStack{
                            if let post = viewModel.post {
                                let feedViewModel = FeedViewModel(posts: [post])
                                SecondaryFeedView(viewModel: feedViewModel, hideFeedOptions: true, checkLikes: true)
                            }
                        }
                    }
                    .sheet(item: $viewModel.collection) { collection in
                        if let collection = viewModel.collection, let user = viewModel.user {
                            CollectionView(collectionsViewModel: viewModel.collectionsViewModel)
                        }
                    }
                    .sheet(isPresented: $viewModel.showRestaurant){
                        if let selectedRestaurantId = viewModel.selectedRestaurantId {
                            NavigationStack{
                                RestaurantProfileView(restaurantId: selectedRestaurantId)
                            }
                        }
                    }
                    .sheet(isPresented: $viewModel.showUserProfile) {
                        if let selectedUid = viewModel.selectedUid {
                            NavigationStack{
                                ProfileView(uid: selectedUid)
                                    .navigationDestination(for: PostUser.self) { user in
                                        ProfileView(uid: user.id)
                                    }
                                    .navigationDestination(for: PostRestaurant.self) { restaurant in
                                        RestaurantProfileView(restaurantId: restaurant.id)
                                    }
                            }
                        }
                    }
                    .sheet(item: $viewModel.writtenPost) { post in
                        NavigationStack {
                            ScrollView {
                                if let post = viewModel.writtenPost {
                                    let feedViewModel = FeedViewModel(posts: [post])
                                    WrittenFeedCell(viewModel: feedViewModel, post: .constant(post), scrollPosition: .constant(nil), pauseVideo: .constant(false), selectedPost: .constant(nil), checkLikes: true)
                                }
                            }
                            .modifier(BackButtonModifier())
                            .navigationDestination(for: PostRestaurant.self) { restaurant in
                                RestaurantProfileView(restaurantId: restaurant.id)
                            }
                        }
                        .presentationDetents([.height(UIScreen.main.bounds.height * 0.8)])
                    }
                    .navigationDestination(for: Activity.self) {activity in
                        if let id = activity.restaurantId{
                            RestaurantProfileView(restaurantId: id)
                        }
                    }
                }
            }
        }
    }
}


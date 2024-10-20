//
//  TrendingPostsListView.swift
//  Ketchup
//
//  Created by Jack Robinson on 10/18/24.
//

import SwiftUI
import MapKit
import CoreLocation
struct TrendingPostsListView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: ActivityViewModel
    var location: CLLocationCoordinate2D?
    var isGlobal: Bool = false
    @State private var isLoading = true
    @State private var selectedPost: Post?

    var body: some View {
        NavigationView {
            VStack {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .onAppear {
                            Task {
                                await fetchTrendingPosts()
                            }
                        }
                } else {
                    List {
                        ForEach(currentPosts, id: \.id) { post in
                            Button(action: {
                                selectedPost = post
                            }) {
                                TrendingPostRow(index: currentPosts.firstIndex(of: post) ?? 0, post: post)
                            }
                            .onAppear {
                                if post == currentPosts.last {
                                    Task {
                                        await fetchMoreTrendingPosts()
                                    }
                                }
                            }
                        }
                        if isGlobal ? viewModel.isLoadingMoreGlobalTrendingPosts : viewModel.isLoadingMoreTrendingPosts {
                            HStack {
                                Spacer()
                                ProgressView()
                                Spacer()
                            }
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle(isGlobal ? "Global Trending Posts" : "Nearby Trending Posts")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(item: $selectedPost) { post in
                NavigationStack {
                    ScrollView {
                        WrittenFeedCell(viewModel: FeedViewModel(), post: .constant(post), scrollPosition: .constant(nil), pauseVideo: .constant(false), selectedPost: .constant(nil), checkLikes: true)
                    }
                    .modifier(BackButtonModifier())
                    .navigationDestination(for: PostRestaurant.self) { restaurant in
                        RestaurantProfileView(restaurantId: restaurant.id)
                    }
                }
            }
            .onAppear {
                if isGlobal {
                    viewModel.resetGlobalTrendingPostsPagination()
                }
            }
        }
    }

    private var currentPosts: [Post] {
        isGlobal ? viewModel.globalTrendingPostsFullList : viewModel.trendingPosts
    }

    private func fetchTrendingPosts() async {
        isLoading = true
        if isGlobal {
            await viewModel.fetchGlobalTrendingPostsForFullList()
        } else if let location = location {
            try? await viewModel.fetchTrendingPosts(location: location)
        }
        isLoading = false
    }

    private func fetchMoreTrendingPosts() async {
        if isGlobal {
            await viewModel.fetchGlobalTrendingPostsForFullList()
        } else {
            await viewModel.fetchMoreTrendingPosts()
        }
    }
}

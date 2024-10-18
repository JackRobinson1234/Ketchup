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
    @State private var isLoading = false
    @State private var selectedPost: Post?

    var body: some View {
        NavigationView {
            VStack {
                if viewModel.trendingPosts.isEmpty && isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .onAppear {
                            Task {
                                await fetchTrendingPosts()
                            }
                        }
                } else {
                    List {
                        ForEach(viewModel.trendingPosts, id: \.id) { post in
                            Button(action: {
                                selectedPost = post
                            }) {
                                TrendingPostRow(index: viewModel.trendingPosts.firstIndex(of: post) ?? 0, post: post)
                            }
                            .onAppear {
                                if post == viewModel.trendingPosts.last {
                                    Task {
                                        await fetchMoreTrendingPosts()
                                    }
                                }
                            }
                        }
                        if viewModel.isLoadingMoreTrendingPosts {
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
            .navigationTitle("Trending Posts")
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
        }
    }

    private func fetchTrendingPosts() async {
        isLoading = true
        do {
            if let location = location {
                try await viewModel.fetchTrendingPosts(location: location)
            }
        } catch {
            print("Error fetching trending posts: \(error)")
        }
        isLoading = false
    }

    private func fetchMoreTrendingPosts() async {
        if !viewModel.isLoadingMoreTrendingPosts && viewModel.hasMoreTrendingPosts {
            await viewModel.fetchMoreTrendingPosts()
        }
    }
}

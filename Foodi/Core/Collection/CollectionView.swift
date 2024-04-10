//
//  CollectionView.swift
//  Foodi
//
//  Created by Jack Robinson on 4/10/24.
//

import SwiftUI

struct CollectionView: View {
    var collection: Collection
    @State var selectedPost: Post?
    @State var selectedRestaurant: String?
    @State var showPost: Bool = false
    @State var showRestaurant: Bool = false
    private let restaurantService = RestaurantService()
    private let postService = PostService()
    var body: some View {
        NavigationStack{
            VStack{
                ScrollView {
                    if let items = collection.items {
                        LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                            ForEach(items, id: \.id) { item in
                                if item.postType == "restaurant" {
                                    NavigationLink(destination: RestaurantProfileView(restaurantId: item.id)) {
                                        CollectionItemCell(item: item)
                                            .aspectRatio(1.0, contentMode: .fit)
                                    }
                                    //                                Button{
                                    //                                    Task{
                                    //                                        selectedRestaurant = item.id
                                    //                                        showRestaurant.toggle()
                                    //                                    }
                                    //                                } label: {
                                    //                                    CollectionItemCell(item: item)
                                    //                                        .aspectRatio(1.0, contentMode: .fit)
                                    //                                }
                                } else if item.postType == "atHome" {
                                    Button{
                                        Task{
                                            selectedPost = try await
                                            postService.fetchPost(postId: item.id)
                                        }
                                        showPost.toggle()
                                    } label: {
                                        CollectionItemCell(item: item)
                                            .aspectRatio(1.0, contentMode: .fit)
                                    }
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .sheet(isPresented: $showPost) {
                if let post = selectedPost {
                    FeedView(videoCoordinator: VideoPlayerCoordinator(), posts: [post], userService: UserService(), hideFeedOptions: true)
                }
            }
            .sheet(isPresented: $showRestaurant) {
                if let restaurant = selectedRestaurant {
                    NavigationStack{
                        RestaurantProfileView(restaurantId: restaurant)
                    }
                }
            }
        }
    }
}
#Preview {
    CollectionView(collection: DeveloperPreview.collections[0])
}

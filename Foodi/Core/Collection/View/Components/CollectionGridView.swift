//
//  CollectionView.swift
//  Foodi
//
//  Created by Jack Robinson on 4/10/24.
//

import SwiftUI
import FirebaseAuth

struct CollectionGridView: View {
    @State var selectedPost: Post?
    @State var selectedRestaurant: String?
    @State var showPost: Bool = false
    @State var showRestaurant: Bool = false
    @State var showAddItem = false
    @ObservedObject var collectionsViewModel: CollectionsViewModel
    @State var isLoading = true
    var body: some View {
        //MARK: Search Bar
        if isLoading {
            ProgressView()
                .onAppear{
                    Task{
                        try await collectionsViewModel.fetchItems()
                        isLoading = false
                    }
                }
        } else {
            VStack{
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                    //MARK: Add Item Button
                    if collectionsViewModel.selectedCollection?.uid == Auth.auth().currentUser?.uid {
                        Button{
                            showAddItem.toggle()
                        } label: {
                            AddItemCollectionButton()
                        }
                    }
                    //MARK: VGrid of Items
                    ForEach(collectionsViewModel.items, id: \.id) { item in
                        if item.postType == "restaurant" {
                            NavigationLink(destination: RestaurantProfileView(restaurantId: item.id)) {
                                CollectionItemCell(item: item)
                                    .aspectRatio(1.0, contentMode: .fit)
                            }
                        } else if item.postType == "atHome" {
                            Button{
                                Task{
                                    selectedPost = try await
                                    PostService.shared.fetchPost(postId: item.id)
                                }
                                showPost.toggle()
                            } label: {
                                CollectionItemCell(item: item)
                                    .aspectRatio(1.0, contentMode: .fit)
                            }
                        }
                    }
                    .padding(7)
                }
            }
            //MARK: Add Item Sheet
            .sheet(isPresented: $showAddItem) {
                ItemSelectorView( collectionsViewModel: collectionsViewModel)
            }
            //MARK: Show Post Sheet
            .sheet(isPresented: $showPost) {
                if let post = selectedPost {
                    FeedView(videoCoordinator: VideoPlayerCoordinator(), posts: [post], hideFeedOptions: true)
                }
            }
            //MARK: Restaurant Sheet
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
    CollectionGridView(collectionsViewModel: CollectionsViewModel(user: DeveloperPreview.user))
}

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
    private let restaurantService = RestaurantService()
    private let postService = PostService()
    @State var searchText: String = ""
    @State private var filteredItems: [CollectionItem] = []
    @State var showAddItem = false
    @ObservedObject var collectionsViewModel: CollectionsViewModel
    var body: some View {
        VStack{
            HStack{
                Image(systemName: "magnifyingglass")
                    .imageScale(.small)
                TextField("Search", text: $searchText)
                    .font(.subheadline)
                    .frame(height:44)
                    .padding(.horizontal)
            }
            .frame(height: 44)
            .padding(.horizontal)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(lineWidth: 1.0)
                    .foregroundStyle(Color(.systemGray4)))
            .padding(.horizontal)

                LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                    //if collection.uid == Auth.auth().currentUser?.uid{
                    Button{
                        showAddItem.toggle()
                    } label: {
                        AddItemCollectionButton()
                    }
                    if let items = collectionsViewModel.selectedCollection?.items, !items.isEmpty {
                        ForEach(filteredItems, id: \.id) { item in
                            if item.postType == "restaurant" {
                                NavigationLink(destination: RestaurantProfileView(restaurantId: item.id)) {
                                    CollectionItemCell(item: item)
                                        .aspectRatio(1.0, contentMode: .fit)
                                }
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
                        .padding(7)
                    }
                }
            }
        .onAppear{
            if let items = collectionsViewModel.selectedCollection?.items{
                filteredItems = items
            }
        }
        .onChange(of: searchText) {
            if searchText.isEmpty{
                if let items = collectionsViewModel.selectedCollection?.items{
                    filteredItems = items
                }
            } else {
                filteredItems = filterItems(searchText: searchText)
            }
        }
        .sheet(isPresented: $showAddItem) {
            ItemSelectorView( collectionsViewModel: collectionsViewModel)
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
        .onChange(of: collectionsViewModel.updateItems) {
            if let items = collectionsViewModel.selectedCollection?.items{
                searchText = ""
                filteredItems = items
                collectionsViewModel.updateItems = false
            }
        }
    }
    func filterItems(searchText: String) -> [CollectionItem] {
        let lowercasedQuery = searchText.lowercased()
        return collectionsViewModel.selectedCollection?.items?.filter { item in
            item.name.lowercased().contains(lowercasedQuery)
        } ?? []
    }
}
#Preview {
    CollectionGridView(collectionsViewModel: CollectionsViewModel(user: DeveloperPreview.user))
}

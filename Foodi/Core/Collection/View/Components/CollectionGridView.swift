//
//  CollectionView.swift
//  Foodi
//
//  Created by Jack Robinson on 4/10/24.
//

import SwiftUI
import FirebaseAuth

struct CollectionGridView: View {
    var collection: Collection
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
            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                    //if collection.uid == Auth.auth().currentUser?.uid{
                    Button{
                        collectionsViewModel.selectedCollection = collection
                        showAddItem.toggle()
                    } label: {
                        AddItemCollectionButton()
                    }
                    if let items = collection.items, !items.isEmpty {
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
        }
            .onAppear{
                if let items = collection.items{
                    filteredItems = items
                }
            }
            .onChange(of: searchText) {
                if searchText.isEmpty{
                    if let items = collection.items{
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
        }
    func filterItems(searchText: String) -> [CollectionItem] {
        let lowercasedQuery = searchText.lowercased()
        return collection.items?.filter { item in
            item.name.lowercased().contains(lowercasedQuery)
        } ?? []
    }
}
#Preview {
    CollectionGridView(collection: DeveloperPreview.collections[0], collectionsViewModel: CollectionsViewModel())
}

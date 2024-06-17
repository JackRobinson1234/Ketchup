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
    let width = (UIScreen.main.bounds.width / 3) - 5
    let spacing: CGFloat = 3
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
                LazyVGrid(columns: [GridItem(.flexible(), spacing: spacing), GridItem(.flexible(), spacing: spacing), GridItem(.flexible(), spacing: spacing)], spacing: spacing) {
                    //MARK: Add Item Button
                    if collectionsViewModel.selectedCollection?.uid == Auth.auth().currentUser?.uid {
                        Button{
                            showAddItem.toggle()
                        } label: {
                            AddItemCollectionButton(width: width)
                                .aspectRatio(1.0, contentMode: .fit)
                        }
                    }
                    
                    //MARK: VGrid of Items
                    
                    ForEach(collectionsViewModel.items, id: \.id) { item in
                        if item.postType == .dining {
                            ZStack(alignment: .topTrailing){
                                NavigationLink(destination: RestaurantProfileView(restaurantId: item.id)) {
                                    CollectionItemCell(item: item, width: width, viewModel: collectionsViewModel)
                                        .aspectRatio(1.0, contentMode: .fit)
                                }
                                if let notes = item.notes, !notes.isEmpty {
                                    Button {
                                        collectionsViewModel.notesPreview = item
                                    } label: {
                                        VStack(spacing: 0){
                                            Image(systemName: "pencil")
                                                .resizable()
                                                .scaledToFit()
                                                .frame(width: 20)
                                                .foregroundColor(Color("Colors/AccentColor"))
                                                

                                            Text("Notes")
                                                .foregroundStyle(Color(.black))
                                                .font(.footnote)
                                            
                                        }
                                        .padding(.vertical, 3)
                                        .padding(.horizontal, 6)
                                        .background(
                                            RoundedRectangle(cornerRadius: 10) // Set the corner radius for rounded corners
                                                .fill(Color.white) // Set the background color to white
                                        )
                                    }
//                                    .offset(x: width/2.8, y: -width/2.3 )
                                }
                            }
                        } else if item.postType == .cooking {
                        
                            ZStack{
                                Button{
                                    Task{
                                        selectedPost = try await
                                        PostService.shared.fetchPost(postId: item.id)
                                    }
                                    showPost.toggle()
                                } label: {
                                    CollectionItemCell(item: item, width: width, viewModel: collectionsViewModel)
                                        .aspectRatio(1.0, contentMode: .fit)
                                }
                                if let notes = item.notes, !notes.isEmpty {
                                    Button {
                                        collectionsViewModel.notesPreview = item
                                    } label: {
                                        Image(systemName: "line.3.horizontal")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 30)
                                            .foregroundColor(.white)
                                        
                                            .shadow(color: .black.opacity(1), radius: 4, x: 1, y: 1)
                                            .opacity(0.8)
                                    }
                                    .offset(x: width/2.8, y: -width/2.3 )
                                }
                            
                            }
                            
                        }
                    }
                }
                .padding(3)
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

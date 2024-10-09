//
//  CollectionView.swift
//  Foodi
//
//  Created by Jack Robinson on 4/10/24.
//

import SwiftUI
import FirebaseAuth

struct CollectionListView: View {
    @ObservedObject var collectionsViewModel: CollectionsViewModel
    @State var isLoading = true
    @State var showAddItem = false
    @State var selectedRestaurant: String?
    @State var showRestaurant: Bool = false

    var body: some View {
        if isLoading {
            FastCrossfadeFoodImageView()
                .onAppear {
                    ////print("FETCHING ITEMS")
                    Task {
                        try await collectionsViewModel.fetchItems()
                        isLoading = false
                    }
                }
        } else {
            ScrollView {
                LazyVStack(spacing: 0) {
                    // Add Item Button (if user owns the collection)
                    if let currentUserID = Auth.auth().currentUser?.uid,
                       let selectedCollection = collectionsViewModel.selectedCollection,
                       selectedCollection.uid == currentUserID || selectedCollection.collaborators.contains(currentUserID) == true{
                        Button(action: {
                            showAddItem.toggle()
                        }) {
                            HStack {
                                Spacer()
                                Image(systemName: "plus")
                                    .foregroundStyle(Color("Colors/AccentColor"))
                                    .scaledToFit()
                                    .frame(width: 25, height: 25)
                                
                                Text("Add Restaurant")
                                    .font(.custom("MuseoSansRounded-500", size: 16))
                                    .foregroundStyle(Color("Colors/AccentColor"))
                                Spacer()
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                        }
                        
                    }

                    // List of Items
                    ForEach(collectionsViewModel.items, id: \.id) { item in
                        NavigationLink(destination: RestaurantProfileView(restaurantId: item.id)) {
                            CollectionItemCell(item: item, viewModel: collectionsViewModel)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Divider()
                            .padding(.leading, 84) // Aligns divider with the end of the image
                    }
                }
            }
            
            // Add Item Sheet
            .fullScreenCover(isPresented: $showAddItem) {
                CollectionRestaurantSearch(collectionsViewModel: collectionsViewModel)
            }
            
            // Restaurant Sheet
            .sheet(isPresented: $showRestaurant) {
                if let restaurant = selectedRestaurant {
                    NavigationStack {
                        RestaurantProfileView(restaurantId: restaurant)
                    }
                }
            }
        }
    }
}

#Preview {
    CollectionListView(collectionsViewModel: CollectionsViewModel())
}

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
            ProgressView()
                .onAppear {
                    print("FETCHING ITEMS")
                    Task {
                        try await collectionsViewModel.fetchItems()
                        isLoading = false
                    }
                }
        } else {
            ScrollView {
                LazyVStack(spacing: 0) {
                    // Add Item Button (if user owns the collection)
                    if collectionsViewModel.selectedCollection?.uid == Auth.auth().currentUser?.uid {
                        Button(action: {
                            showAddItem.toggle()
                        }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text("Add Item")
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(Color.secondary.opacity(0.1))
                            .cornerRadius(10)
                        }
                        .padding(.horizontal)
                        .padding(.top)
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
    CollectionListView(collectionsViewModel: CollectionsViewModel(user: DeveloperPreview.user))
}

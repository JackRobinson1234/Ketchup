//
//  RestaurantCollectionListView.swift
//  Foodi
//
//  Created by Jack Robinson on 5/7/24.
//

import SwiftUI

struct RestaurantCollectionListView: View {
    @State var isLoading = true
    @ObservedObject var viewModel: RestaurantViewModel
    @State var showCollection: Bool = false
    @State var showAddToCollection = false
    var body: some View {
        
        VStack{
            if isLoading {
                // Loading screen
                ProgressView("Loading...")
                    .toolbar(.hidden, for: .tabBar)
                    .onAppear {
                        Task {
                            try await viewModel.fetchRestaurantCollections()
                            isLoading = false
                        }
                    }
            } else {
                VStack {
                    Divider()
                    Button{
                        showAddToCollection.toggle()
                    } label: {
                        HStack{
                            Image(systemName: "plus")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 30)
                                .foregroundStyle(.blue.opacity(1))
                                .padding(.horizontal)
                            VStack(alignment: .leading){
                                
                                Text("Add \(viewModel.restaurant?.name ?? "") to your collection")
                                    .font(.custom("MuseoSansRounded-300", size: 16))
                                    .foregroundStyle(.primary)
                                    .multilineTextAlignment(.leading)
                            }
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.primary)
                                .padding(.horizontal)
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical)
                    Divider()
                    //MARK: CollectionsList
                    if !viewModel.collections.isEmpty {
                        // if post isn't passed in, then go to the selected collection
                        ForEach(viewModel.collections) { collection in
                            Button{
                                viewModel.collectionsViewModel.updateSelectedCollection(collection: collection)
                                showCollection.toggle()
                            } label: {
                                CollectionListCell(collection: collection)
                            }
                            Divider()
                        }
                    } else {
                        if let restaurant = viewModel.restaurant {
                            Text("\(restaurant.name) is not listed in any collections")
                                .font(.custom("MuseoSansRounded-300", size: 16))
                                .padding()
                        }
                    }
                }
                .sheet(isPresented: $showCollection) {
                    CollectionView(collectionsViewModel: viewModel.collectionsViewModel)
                }
                
                .sheet(isPresented: $showAddToCollection) {
                    if let user = AuthService.shared.userSession{
                        AddItemCollectionList(user: user, restaurant: viewModel.restaurant)
                            .onDisappear {
                                Task {
                                    try await viewModel.fetchRestaurantCollections()
                                    isLoading = false
                                }
                            }
                    }
                }
            }
        }
    }
}
#Preview {
    RestaurantCollectionListView(viewModel: RestaurantViewModel(restaurantId: ""))
}

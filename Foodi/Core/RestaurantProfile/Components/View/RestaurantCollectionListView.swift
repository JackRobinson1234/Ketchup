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
                ScrollView{
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
                                .font(.subheadline)
                                .padding()
                        }
                    }
                }
                .sheet(isPresented: $showCollection) {
                    CollectionView(collectionsViewModel: viewModel.collectionsViewModel)}
                
            }
        }
    }
}
#Preview {
    RestaurantCollectionListView(viewModel: RestaurantViewModel(restaurantId: ""))
}

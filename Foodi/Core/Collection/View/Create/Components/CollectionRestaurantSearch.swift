//
//  CollectionRestaurantSearch.swift
//  Foodi
//
//  Created by Jack Robinson on 4/15/24.
//

import SwiftUI
import InstantSearchSwiftUI
struct CollectionRestaurantSearch: View {
    @StateObject var viewModel: RestaurantListViewModel
    @Environment(\.dismiss) var dismiss
    @ObservedObject var collectionsViewModel: CollectionsViewModel
    var debouncer = Debouncer(delay: 1.0)
    
    init(restaurantService: RestaurantService, collectionsViewModel: CollectionsViewModel) {
        self._viewModel = StateObject(wrappedValue: RestaurantListViewModel())
        self.collectionsViewModel = collectionsViewModel
    }
    
    var body: some View {
        InfiniteList(viewModel.hits, itemView: { hit in
            Button{
                let restaurant = hit.object
                collectionsViewModel.restaurant = restaurant
                if let item = collectionsViewModel.convertRestaurantToCollectionItem() {
                    Task{
                        try await collectionsViewModel.addItemToCollection(collectionItem: item)
                        dismiss()
                    }
                }
            } label :{
                RestaurantCell(restaurant: hit.object)
                    .padding(.leading)
            }
            Divider()
        }, noResults: {
            Text("No results found")
        })
        .navigationTitle("Add to Collection")
        .searchable(text: $viewModel.searchQuery,
                    prompt: "Search")
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Text("Cancel")
                }
            }
        }
        .toolbar(.hidden, for: .tabBar)
        .navigationBarBackButtonHidden()
        .onChange(of: viewModel.searchQuery) {
            debouncer.schedule {
                viewModel.notifyQueryChanged()
            }
        }
    }
}

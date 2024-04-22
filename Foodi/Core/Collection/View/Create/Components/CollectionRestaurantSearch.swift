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
    
    init(restaurantService: RestaurantService, collectionsViewModel: CollectionsViewModel) {
        self._viewModel = StateObject(wrappedValue: RestaurantListViewModel())
        self.collectionsViewModel = collectionsViewModel
    }
    
    var body: some View {
        InfiniteList(viewModel.hits, itemView: { hit in
            Button{
                let restaurant = hit.object
                let name = restaurant.name
                let id = restaurant.id
                let restaurantProfileImageUrl = restaurant.profileImageUrl ?? nil
                let city = restaurant.city ?? nil
                let state = restaurant.state ?? nil
                let geoPoint = restaurant.geoPoint ?? nil
                let newItem = CollectionItem(id: id, postType: "restaurant", name: name, image: restaurantProfileImageUrl, city: city, state: state, geoPoint: geoPoint)
                Task{
                    collectionsViewModel.addItemToCollection(item: newItem)
                    dismiss()
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
    }
}

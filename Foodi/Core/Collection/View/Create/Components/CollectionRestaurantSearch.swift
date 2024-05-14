//
//  CollectionRestaurantSearch.swift
//  Foodi
//
//  Created by Jack Robinson on 4/15/24.
//

import SwiftUI
import InstantSearchSwiftUI
struct CollectionRestaurantSearch: View {
    @StateObject var viewModel = RestaurantListViewModel()
    @Environment(\.dismiss) var dismiss
    @ObservedObject var collectionsViewModel: CollectionsViewModel
    var debouncer = Debouncer(delay: 1.0)
    @Binding var selectedItem: CollectionItem?

    
    var body: some View {
        InfiniteList(viewModel.hits, itemView: { hit in
            Button{
                selectedItem = collectionsViewModel.convertRestaurantToCollectionItem(restaurant: hit.object)} label: {
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
        .onAppear{
            if collectionsViewModel.dismissListView {
                collectionsViewModel.dismissListView = false
                dismiss()
                
            }
        }
    }
}

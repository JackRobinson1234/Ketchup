//
//  FavoriteRestaurantSearchView.swift
//  Foodi
//
//  Created by Jack Robinson on 2/21/24.
//

import SwiftUI
import InstantSearchSwiftUI

struct FavoriteRestaurantSearchView: View {
    @StateObject var viewModel: RestaurantListViewModel
    @Binding var oldSelection: FavoriteRestaurant
    @Environment(\.dismiss) var dismiss
    @ObservedObject var editProfileViewModel: EditProfileViewModel
    var debouncer = Debouncer(delay: 1.0)
    
    init(oldSelection: Binding<FavoriteRestaurant>, editProfileViewModel: EditProfileViewModel) {
        self._viewModel = StateObject(wrappedValue: RestaurantListViewModel())
        self._oldSelection = oldSelection
        self.editProfileViewModel = editProfileViewModel
    }
    var body: some View {
        NavigationStack{
            InfiniteList(viewModel.hits, itemView: { hit in
                if !editProfileViewModel.favoritesPreview.contains(where: { $0.id == hit.object.id }) {
                    Button{
                        let restaurant = hit.object
                        let name = restaurant.name
                        let id = restaurant.id
                        let restaurantProfileImageUrl = restaurant.profileImageUrl ?? ""
                        let newSelection = FavoriteRestaurant(name: name, id: id, restaurantProfileImageUrl: restaurantProfileImageUrl)
                        if let index = editProfileViewModel.favoritesPreview.firstIndex(of: oldSelection) {
                            editProfileViewModel.favoritesPreview[index] = newSelection
                            dismiss()
                        }
                    } label: {
                        RestaurantCell(restaurant: hit.object)
                            .padding()
                    }
                    Divider()
                }
            }, noResults: {
                Text("No results found")
            })
            .navigationTitle("Select a Favorite")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $viewModel.searchQuery,
                        prompt: "Search")
            .onChange(of: viewModel.searchQuery) {
                debouncer.schedule {
                    viewModel.notifyQueryChanged()
                }
            }
            .toolbar(.hidden, for: .tabBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Text("Cancel")
                    }
                }
            }
        }
    }
}
    

/*
#Preview {
    FavoriteRestaurantSearchView()
}
*/

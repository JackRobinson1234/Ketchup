//
//  FavoriteRestaurantSearchView.swift
//  Foodi
//
//  Created by Jack Robinson on 2/21/24.
//

import SwiftUI

struct FavoriteRestaurantSearchView: View {
    @StateObject var viewModel: RestaurantListViewModel
    @State var searchText: String = ""
    @Binding var oldSelection: FavoriteRestaurant
    @Binding var favoritesPreview: [FavoriteRestaurant]
    @Environment(\.dismiss) var dismiss
    
    init(restaurantService: RestaurantService, oldSelection: Binding<FavoriteRestaurant>, favoritesPreview: Binding<[FavoriteRestaurant]>) {
        self._viewModel = StateObject(wrappedValue: RestaurantListViewModel(config: .favorites, restaurantService: restaurantService))
        self._oldSelection = oldSelection
        self._favoritesPreview = favoritesPreview
    }
    var restaurants: [Restaurant] {
        return searchText.isEmpty ? viewModel.restaurants : viewModel.filteredRestaurants(searchText)
    }
    var body: some View {
        NavigationStack{
            ScrollView {
                VStack{
                    ForEach(restaurants) { restaurant in
                        Button{
                            let name = restaurant.name
                            let id = restaurant.id
                            let restaurantProfileImageUrl = restaurant.profileImageUrl ?? ""
                            let newSelection = FavoriteRestaurant(name: name, id: id, restaurantProfileImageUrl: restaurantProfileImageUrl)
                            if let index = favoritesPreview.firstIndex(of: oldSelection) {
                                favoritesPreview[index] = newSelection
                            dismiss()
                            }
                        } label :{
                            RestaurantCell(restaurant: restaurant)
                                .padding(.leading)
                        }
                    }
                }
            }
            .navigationTitle("Select a Favorite")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, placement: .navigationBarDrawer)
            .navigationBarBackButtonHidden()
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
            
        }
    }
}

/*
#Preview {
    FavoriteRestaurantSearchView()
}
*/

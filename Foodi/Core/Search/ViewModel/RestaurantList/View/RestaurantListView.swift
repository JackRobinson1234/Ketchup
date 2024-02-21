//
//  RestaurantListView.swift
//  Foodi
//
//  Created by Jack Robinson on 2/1/24.
//

import SwiftUI

struct RestaurantListView: View {
    @StateObject var viewModel: RestaurantListViewModel
    private let config: RestaurantListConfig
    @State private var searchText = ""
    private let restaurantService: RestaurantService
    @Binding var oldSelection: FavoriteRestaurant?
    @Binding var favoritesPreview: [FavoriteRestaurant]?
    @Environment(\.dismiss) var dismiss
    
    
    init(config: RestaurantListConfig, restaurantService: RestaurantService, userService: UserService, oldSelection: Binding<FavoriteRestaurant?> = .constant(nil), favoritesPreview: Binding<[FavoriteRestaurant]?> = .constant(nil)) {
        self.config = config
        self.restaurantService = restaurantService
        self._viewModel = StateObject(wrappedValue: RestaurantListViewModel(config: config, restaurantService: restaurantService))
        self._oldSelection = oldSelection
        self._favoritesPreview = favoritesPreview
    }
    
    var restaurants: [Restaurant] {
        return searchText.isEmpty ? viewModel.restaurants : viewModel.filteredRestaurants(searchText)
    }
    var body: some View {
        
                    switch config {
                    case .upload, .restaurants:
                        ScrollView {
                            LazyVStack {
                        ForEach(restaurants) { restaurant in
                            NavigationLink(value: restaurant) {
                                RestaurantCell(restaurant: restaurant)
                                    .padding(.leading)
                                    .onAppear {
                                        if restaurant.id == restaurants.last?.id ?? "" {
                                        }
                                    }
                            }
                        }
                        
                        .padding(.top)
                        
                    }
                    .navigationTitle(config.navigationTitle)
                    .navigationBarTitleDisplayMode(.inline)
                    .searchable(text: $searchText, placement: .navigationBarDrawer)
                        
            }
                        
                    case .favorites:
                        Text("testing")
                        /*ScrollView {
                            LazyVStack {
                                ForEach(restaurants) { restaurant in
                                    Button{
                                        let name = restaurant.name
                                        let id = restaurant.id
                                        let restaurantProfileImageUrl = restaurant.profileImageUrl ?? ""
                                        let newSelection = FavoriteRestaurant(name: name, id: id, restaurantProfileImageUrl: restaurantProfileImageUrl)
                                        if var favoritesPreview{
                                            if let oldSelection{
                                                if let index = favoritesPreview.firstIndex(of: oldSelection) {
                                                    favoritesPreview[index] = newSelection
                                                    
                                                }
                                            }
                                        }
                                    } label :{
                                        RestaurantCell(restaurant: restaurant)
                                            .padding(.leading)
                                    }
                                }
                            }
                        }
                        .navigationTitle(config.navigationTitle)
                        .navigationBarTitleDisplayMode(.inline)
                        .searchable(text: $searchText, placement: .navigationBarDrawer)
                        navigationBarBackButtonHidden()
                        .toolbar {
                            ToolbarItem(placement: .topBarLeading) {
                                Button {
                                    dismiss()
                                } label: {
                                    Text("Cancel")
                                }
                            }
                        }
                        .toolbar(.hidden, for: .tabBar)*/
                        
        }
    }
}


#Preview {
    RestaurantListView(config:.restaurants, restaurantService: RestaurantService(), userService: UserService())
}

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
    
    init(config: RestaurantListConfig, restaurantService: RestaurantService, userService: UserService) {
        self.config = config
        self.restaurantService = restaurantService
        self._viewModel = StateObject(wrappedValue: RestaurantListViewModel(config: config, restaurantService: restaurantService))
    }
    
    var restaurants: [Restaurant] {
        return searchText.isEmpty ? viewModel.restaurants : viewModel.filteredRestaurants(searchText)
    }
    var body: some View {
        
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
                .navigationDestination(for: Restaurant.self) { restaurant in
                    RestaurantProfileView()}
                .searchable(text: $searchText, placement: .navigationBarDrawer)
        }
    }
}


#Preview {
    RestaurantListView(config:.restaurants, restaurantService: RestaurantService(), userService: UserService())
}

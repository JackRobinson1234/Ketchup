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
    @State var isLoading: Bool = true
    
    
    init(config: RestaurantListConfig, restaurantService: RestaurantService, userService: UserService, oldSelection: Binding<FavoriteRestaurant?> = .constant(nil), favoritesPreview: Binding<[FavoriteRestaurant]?> = .constant(nil)) {
        self.config = config
        self.restaurantService = restaurantService
        self._viewModel = StateObject(wrappedValue: RestaurantListViewModel( restaurantService: restaurantService))
        self._oldSelection = oldSelection
        self._favoritesPreview = favoritesPreview
    }
    
    var body: some View {
        switch config {
            case .upload, .restaurants:
            if isLoading {
                // Loading screen
                ScrollView{
                    ProgressView("Loading...")
                        .onAppear {
                            Task {
                                try await viewModel.fetchRestaurants()
                                isLoading = false
                            }
                        }
                        .navigationTitle(config.navigationTitle)
                        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always))
                    
                }
            }
            else{
                ScrollView {
                    LazyVStack {
                        ForEach(viewModel.restaurants) { restaurant in
                            NavigationLink(value: restaurant) {
                                RestaurantCell(restaurant: restaurant)
                                    .padding(.leading)
                                
                            }
                            
                        }
                        
                        .padding(.top)
                        
                    }
                }
                    .navigationTitle(config.navigationTitle)
                    .searchable(text: $searchText, placement: .navigationBarDrawer)
                    
                
            }
                
                        
        }
    }
}


#Preview {
    RestaurantListView(config:.restaurants, restaurantService: RestaurantService(), userService: UserService())
}

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
    @Environment(\.dismiss) var dismiss
    @ObservedObject var editProfileViewModel: EditProfileViewModel
    @State var isLoading: Bool = true
    var user: User {
        return editProfileViewModel.user
    }
    
    init(restaurantService: RestaurantService, oldSelection: Binding<FavoriteRestaurant>, editProfileViewModel: EditProfileViewModel) {
        self._viewModel = StateObject(wrappedValue: RestaurantListViewModel(restaurantService: restaurantService))
        
        self._oldSelection = oldSelection
        self.editProfileViewModel = editProfileViewModel
    }
    var restaurants: [Restaurant] {
        return searchText.isEmpty ? viewModel.restaurants : viewModel.filteredRestaurants(searchText)
    }
    var body: some View {
        if isLoading {
            // Loading screen
            NavigationStack{
                ScrollView{
                    ProgressView("Loading...")
                        .onAppear {
                            Task {
                                try await viewModel.fetchRestaurants()
                                isLoading = false
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
        } else {
                NavigationStack{
                    ScrollView {
                        VStack{
                            ForEach(restaurants) { restaurant in
                                Button{
                                    let name = restaurant.name
                                    let id = restaurant.id
                                    let restaurantProfileImageUrl = restaurant.profileImageUrl ?? ""
                                    let newSelection = FavoriteRestaurant(name: name, id: id, restaurantProfileImageUrl: restaurantProfileImageUrl)
                                    if let index = editProfileViewModel.favoritesPreview.firstIndex(of: oldSelection) {
                                        editProfileViewModel.favoritesPreview[index] = newSelection
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
    }
    

/*
#Preview {
    FavoriteRestaurantSearchView()
}
*/

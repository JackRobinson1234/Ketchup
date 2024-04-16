//
//  CollectionRestaurantSearch.swift
//  Foodi
//
//  Created by Jack Robinson on 4/15/24.
//

import SwiftUI

struct CollectionRestaurantSearch: View {
    @StateObject var restaurantListViewModel: RestaurantListViewModel
    @State var searchText: String = ""
    @Environment(\.dismiss) var dismiss
    @ObservedObject var collectionsViewModel: CollectionsViewModel
    @State var isLoading: Bool = true
    init(restaurantService: RestaurantService, collectionsViewModel: CollectionsViewModel) {
        self._restaurantListViewModel = StateObject(wrappedValue: RestaurantListViewModel(restaurantService: restaurantService))
        
        self.collectionsViewModel = collectionsViewModel
    }
    var restaurants: [Restaurant] {
        return searchText.isEmpty ? restaurantListViewModel.restaurants : restaurantListViewModel.filteredRestaurants(searchText)
    }
    var body: some View {
        if isLoading {
            // Loading screen
                ScrollView{
                    ProgressView("Loading...")
                        .onAppear {
                            Task {
                                try await restaurantListViewModel.fetchRestaurants()
                                isLoading = false
                            }
                        }
                        .navigationTitle("Add to Collection")
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
        } else {
                    ScrollView {
                        VStack{
                            ForEach(restaurants) { restaurant in
                                Button{
                                    let name = restaurant.name
                                    let id = restaurant.id
                                    let restaurantProfileImageUrl = restaurant.profileImageUrl ?? nil
                                    let city = restaurant.city ?? nil
                                    let state = restaurant.state ?? nil
                                    let geoPoint = restaurant.geoPoint ?? nil
                                    let newItem = CollectionItem(id: id, postType: "restaurant", name: name, image: restaurantProfileImageUrl, notes: "", city: city, state: state, geoPoint: geoPoint)
                                    Task{
                                        collectionsViewModel.addItemToCollection(item: newItem)
                                        dismiss()
                                    }
                                } label :{
                                    RestaurantCell(restaurant: restaurant)
                                        .padding(.leading)
                                }
                            }
                        }
                    }
                    .navigationTitle("Add to Collection")
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

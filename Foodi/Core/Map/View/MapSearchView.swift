//
//  MapSearchView.swift
//  Foodi
//
//  Created by Jack Robinson on 2/23/24.
//

import SwiftUI

struct MapSearchView: View {
    @StateObject var viewModel: RestaurantListViewModel
    @State var searchText: String = ""
    @Environment(\.dismiss) var dismiss
    @ObservedObject var mapViewModel: MapViewModel
    @Binding var inSearchView: Bool


    
    init(restaurantService: RestaurantService, mapViewModel: MapViewModel, inSearchView: Binding<Bool>) {
        self._viewModel = StateObject(wrappedValue: RestaurantListViewModel(restaurantService: restaurantService))
        self.mapViewModel = mapViewModel
        self._inSearchView = inSearchView
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
                            mapViewModel.searchPreview = [restaurant]
                            dismiss()
                            } label :{
                            RestaurantCell(restaurant: restaurant)
                                .padding(.leading)
                        }
                    }
                }
            }
            .navigationTitle("Select for a Restaurant")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, placement: .navigationBarDrawer)
            .navigationBarBackButtonHidden()
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        inSearchView = false
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
    MapSearchView()
}*/

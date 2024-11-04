//
//  MapFiltersView.swift
//  Foodi
//
//  Created by Jack Robinson on 4/9/24.
//

import SwiftUI

struct MapFiltersView: View {
    @Environment(\.dismiss) var dismiss
    @State private var selectedOption: MapFiltersViewOptions = .cuisine
    @State private var cuisineText = ""
    @ObservedObject var mapViewModel: MapViewModel
    @ObservedObject var followingPostsMapViewModel: FollowingPostsMapViewModel
    @State var selectedPrice: [String] = []
    @State var selectedCuisines: [String] = []
    @Binding var showFollowingPosts: Bool
    init(mapViewModel: MapViewModel,followingPostsMapViewModel: FollowingPostsMapViewModel, showFollowingPosts: Binding<Bool> ) {
        self.mapViewModel = mapViewModel
        self.followingPostsMapViewModel = followingPostsMapViewModel
        _selectedPrice = State(initialValue: mapViewModel.selectedPrice)
        _selectedCuisines = State(initialValue: mapViewModel.selectedCuisines)
        self._showFollowingPosts = showFollowingPosts
    }
    
    var body: some View {
        NavigationStack {
            //MARK: Cuisine
            VStack{
                Button{
                    mapViewModel.clearFilters()
                } label: {
                    Text("Remove all filters")
                        .foregroundStyle(Color("Colors/AccentColor"))
                }
                
                if selectedOption == .cuisine {
                    VStack(alignment: .leading){
                        MapCuisineFilter(selectedCuisines: $selectedCuisines)
                    }
                    .modifier(CollapsibleFilterViewModifier(frame: 260))
                    .onTapGesture(count:2){
                        withAnimation(.snappy){ selectedOption = .noneSelected}}
                }
                else {
                    CollapsedPickerView(title: "Cuisine", emptyDescription: "Filter by Cuisine", count: selectedCuisines.count, singularDescription: "Cuisine Selected", pluralDescription: "Cuisines Selected")
                        .onTapGesture{
                            withAnimation(.snappy){ selectedOption = .cuisine}
                        }
                }
            }
            
            //MARK: Price
            VStack{
                if selectedOption == .price {
                    VStack(alignment: .leading){
                        MapPriceFilter(selectedPrice: $selectedPrice)
                    }
                    .modifier(CollapsibleFilterViewModifier(frame: 210))
                    .onTapGesture(count:2){
                        withAnimation(.snappy){ selectedOption = .noneSelected}}
                }
                else {
                    /// "Filter Price" if no options selected
                    CollapsedPickerView(title: "Price", emptyDescription: "Filter by Price", count: selectedPrice.count, singularDescription: "Price Selected", pluralDescription: "Prices Selected")
                        .onTapGesture{
                            withAnimation(.snappy){ selectedOption = .price}
                        }
                }
            }
            //MARK: Dietary Restrictions
            
            Spacer()
            //MARK: Navigation Title
                .navigationTitle("Add Filters")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark")
                                .imageScale(.small)
                                .foregroundColor(.black)
                                .padding(6)
                                .overlay(
                                    Circle()
                                        .stroke(lineWidth: 1.0)
                                        .foregroundColor(.gray)
                                )
                        }
                    }
                    //MARK: Save Button
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            saveFilters()
                            dismiss()
                        } label: {
                            Text("Save")
                                .foregroundColor(.blue)
                                .padding(6)
                        }
                    }
                }
        }
    }
    //MARK: saveFilters
    private func saveFilters() {
        mapViewModel.selectedPrice = selectedPrice
        followingPostsMapViewModel.selectedPrice = selectedPrice
        mapViewModel.selectedCuisines = selectedCuisines
        followingPostsMapViewModel.selectedCuisines = selectedCuisines
        if showFollowingPosts{
            Task {
                await  followingPostsMapViewModel.fetchFollowingPosts()
            }
        } else {
            Task {
                await mapViewModel.fetchFilteredClusters()
            }
        }
    }
}



//MARK: Filter Options Enum
enum MapFiltersViewOptions{
    case cuisine
    case price
    case noneSelected
}

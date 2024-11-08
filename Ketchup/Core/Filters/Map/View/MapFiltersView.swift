//
//  MapFiltersView.swift
//  Foodi
//
//  Created by Jack Robinson on 4/9/24.
//

import SwiftUI

//struct MapFiltersView: View {
//    @Environment(\.dismiss) var dismiss
//    @State private var selectedOption: MapFiltersViewOptions = .cuisine
//    @State private var cuisineText = ""
//    @ObservedObject var mapViewModel: MapViewModel
//    @ObservedObject var followingPostsMapViewModel: FollowingPostsMapViewModel
//    @State var selectedPrice: [String] = []
//    @State var selectedCuisines: [String] = []
//    @Binding var showFollowingPosts: Bool
//    init(mapViewModel: MapViewModel,followingPostsMapViewModel: FollowingPostsMapViewModel, showFollowingPosts: Binding<Bool> ) {
//        self.mapViewModel = mapViewModel
//        self.followingPostsMapViewModel = followingPostsMapViewModel
//        _selectedPrice = State(initialValue: mapViewModel.selectedPrice)
//        _selectedCuisines = State(initialValue: mapViewModel.selectedCuisines)
//        self._showFollowingPosts = showFollowingPosts
//    }
//    
//    var body: some View {
//        NavigationStack {
//            //MARK: Cuisine
//            VStack{
//                Button{
//                    mapViewModel.clearFilters()
//                } label: {
//                    Text("Remove all filters")
//                        .foregroundStyle(Color("Colors/AccentColor"))
//                }
//                
//                if selectedOption == .cuisine {
//                    VStack(alignment: .leading){
//                        MapCuisineFilter(selectedCuisines: $selectedCuisines)
//                    }
//                    .modifier(CollapsibleFilterViewModifier(frame: 260))
//                    .onTapGesture(count:2){
//                        withAnimation(.snappy){ selectedOption = .noneSelected}}
//                }
//                else {
//                    CollapsedPickerView(title: "Cuisine", emptyDescription: "Filter by Cuisine", count: selectedCuisines.count, singularDescription: "Cuisine Selected", pluralDescription: "Cuisines Selected")
//                        .onTapGesture{
//                            withAnimation(.snappy){ selectedOption = .cuisine}
//                        }
//                }
//            }
//            
//            //MARK: Price
//            VStack{
//                if selectedOption == .price {
//                    VStack(alignment: .leading){
//                        MapPriceFilter(selectedPrice: $selectedPrice)
//                    }
//                    .modifier(CollapsibleFilterViewModifier(frame: 210))
//                    .onTapGesture(count:2){
//                        withAnimation(.snappy){ selectedOption = .noneSelected}}
//                }
//                else {
//                    /// "Filter Price" if no options selected
//                    CollapsedPickerView(title: "Price", emptyDescription: "Filter by Price", count: selectedPrice.count, singularDescription: "Price Selected", pluralDescription: "Prices Selected")
//                        .onTapGesture{
//                            withAnimation(.snappy){ selectedOption = .price}
//                        }
//                }
//            }
//            //MARK: Dietary Restrictions
//            
//            Spacer()
//            //MARK: Navigation Title
//                .navigationTitle("Add Filters")
//                .navigationBarTitleDisplayMode(.inline)
//                .toolbar {
//                    ToolbarItem(placement: .topBarLeading) {
//                        Button {
//                            dismiss()
//                        } label: {
//                            Image(systemName: "xmark")
//                                .imageScale(.small)
//                                .foregroundColor(.black)
//                                .padding(6)
//                                .overlay(
//                                    Circle()
//                                        .stroke(lineWidth: 1.0)
//                                        .foregroundColor(.gray)
//                                )
//                        }
//                    }
//                    //MARK: Save Button
//                    ToolbarItem(placement: .topBarTrailing) {
//                        Button {
//                            saveFilters()
//                            dismiss()
//                        } label: {
//                            Text("Save")
//                                .foregroundColor(.blue)
//                                .padding(6)
//                        }
//                    }
//                }
//        }
//    }
//    //MARK: saveFilters
//    private func saveFilters() {
//        mapViewModel.selectedPrice = selectedPrice
//        followingPostsMapViewModel.selectedPrice = selectedPrice
//        mapViewModel.selectedCuisines = selectedCuisines
//        followingPostsMapViewModel.selectedCuisines = selectedCuisines
//        if showFollowingPosts{
//            Task {
//                await  followingPostsMapViewModel.fetchFollowingPosts()
//            }
//        } else {
//            Task {
//                await mapViewModel.fetchFilteredClusters()
//            }
//        }
//    }
//}
//
//
//
////MARK: Filter Options Enum
//enum MapFiltersViewOptions{
//    case cuisine
//    case price
//    case noneSelected
//}
struct MapFiltersView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var mapViewModel: MapViewModel
    @ObservedObject var followingPostsMapViewModel: FollowingPostsMapViewModel
    @Binding var showFollowingPosts: Bool
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // View Type Selection
                    VStack(alignment: .leading, spacing: 12) {
                        Text("View")
                            .font(.custom("MuseoSansRounded-700", size: 16))
                        
                        CustomToggle(showFollowingPosts: $showFollowingPosts) {
                            // Toggle action here if needed
                        }
                    }
                    .padding(.horizontal)
                    
                    // Rating Filter
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Rating")
                            .font(.custom("MuseoSansRounded-700", size: 16))
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach([10.0, 9.0, 8.0, 7.0, 6.0, 5.0], id: \.self) { rating in
                                    FilterChip(
                                        title: "\(String(format: "%.1f", rating))+",
                                        isSelected: mapViewModel.selectedRating == rating
                                    ) {
                                        mapViewModel.selectedRating = mapViewModel.selectedRating == rating ? 0 : rating
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    // Cuisine Filter
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Cuisine")
                            .font(.custom("MuseoSansRounded-700", size: 16))
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(Cuisines.all, id: \.self) { cuisine in
                                    FilterChip(
                                        title: cuisine,
                                        isSelected: mapViewModel.selectedCuisines.contains(cuisine)
                                    ) {
                                        if mapViewModel.selectedCuisines.contains(cuisine) {
                                            mapViewModel.selectedCuisines.removeAll { $0 == cuisine }
                                        } else if mapViewModel.selectedCuisines.count < 5 {
                                            mapViewModel.selectedCuisines.append(cuisine)
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    // Price Filter
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Price")
                            .font(.custom("MuseoSansRounded-700", size: 16))
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(["$", "$$", "$$$", "$$$$"], id: \.self) { price in
                                    FilterChip(
                                        title: price,
                                        isSelected: mapViewModel.selectedPrice.contains(price)
                                    ) {
                                        if mapViewModel.selectedPrice.contains(price) {
                                            mapViewModel.selectedPrice.removeAll { $0 == price }
                                        } else {
                                            mapViewModel.selectedPrice.append(price)
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                .padding(.top, 24)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Reset") {
                        mapViewModel.selectedRating = 0
                        mapViewModel.selectedCuisines = []
                        mapViewModel.selectedPrice = []
                    }
                }
            }
        }
    }
}
struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.custom("MuseoSansRounded-500", size: 14))
                .foregroundColor(isSelected ? .white : .black)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(isSelected ? Color.red : Color.white)
                        .shadow(color: .gray.opacity(0.2), radius: 2)
                )
        }
    }
}

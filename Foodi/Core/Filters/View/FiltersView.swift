//
//  FiltersView.swift
//  Foodi
//
//  Created by Jack Robinson on 2/1/24.
//

import SwiftUI

struct FiltersView: View {
    
    @Environment(\.dismiss) var dismiss
    @State private var selectedOption: FiltersViewOptions = .postType
    @State private var locationText = ""
    @State private var cuisineText = ""
    @ObservedObject var filtersViewModel: FiltersViewModel

    
    
    init(filtersViewModel: FiltersViewModel) {
            self.filtersViewModel = filtersViewModel
        }
    
    
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading){
                if !locationText.isEmpty {
                    Button("Clear") {
                        locationText = ""
                    }
                    .foregroundStyle(.black)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                }
            }
            .padding()
            
            
            //MARK: Post Type
            VStack {
                if selectedOption == .postType {
                    VStack(alignment: .leading){
                        PostTypeFilter(filtersViewModel: filtersViewModel)
                    }
                    .modifier(CollapsibleFilterViewModifier(frame: 140))
                    .onTapGesture(count:2){
                        withAnimation(.snappy){ selectedOption = .noneSelected}
                    }
                    
                } else {
                    CollapsedPickerView(title: "Post Type", description: "Filter by Post Type")
                        .onTapGesture{
                            withAnimation(.snappy){ selectedOption = .postType}
                        }
                }
            }
            
            //MARK: Location
            VStack {
                if selectedOption == .location {
                        LocationFilter(filtersViewModel: filtersViewModel)
                    .modifier(CollapsibleFilterViewModifier())
                    .onTapGesture(count:2){
                        withAnimation(.snappy){ selectedOption = .noneSelected}
                    }
                    
                } else {
                    CollapsedPickerView(title: "Location", description: "Filter by Location")
                        .onTapGesture{
                            withAnimation(.snappy){ selectedOption = .location}
                        }
                }
                
                //MARK: Cuisine
                VStack{
                    if selectedOption == .cuisine {
                        VStack(alignment: .leading){
                            CuisineFilter(filtersViewModel: filtersViewModel)
                        }
                        .modifier(CollapsibleFilterViewModifier(frame: 260))
                        .onTapGesture(count:2){
                            withAnimation(.snappy){ selectedOption = .noneSelected}}
                    }
                    else {
                        if filtersViewModel.selectedCuisines.isEmpty {
                            CollapsedPickerView(title: "Cuisine", description: "Filter by Cuisine")
                                .onTapGesture{
                                    withAnimation(.snappy){ selectedOption = .cuisine}
                                }
                        } else if filtersViewModel.selectedCuisines.count == 1 {
                            let count = filtersViewModel.selectedCuisines.count
                            CollapsedPickerView(title: "Cuisine", description: "\(count) Filter Selected")
                                .onTapGesture{
                                    withAnimation(.snappy){ selectedOption = .cuisine}
                                }
                        } else {
                            let count = filtersViewModel.selectedCuisines.count
                            CollapsedPickerView(title: "Cuisine", description: "\(count) Filters Selected")
                                .onTapGesture{
                                    withAnimation(.snappy){ selectedOption = .cuisine}
                                }
                        }
                    }
                }
                
                
                
                //MARK: Price
                VStack{
                    if selectedOption == .price {
                        VStack(alignment: .leading){
                            PriceFilter(filtersViewModel: filtersViewModel)
                        }
                        .modifier(CollapsibleFilterViewModifier(frame: 210))
                        .onTapGesture(count:2){
                            withAnimation(.snappy){ selectedOption = .noneSelected}}
                    }
                    else {
                        /// "Filter Price" if no options selected
                        if filtersViewModel.selectedPrice.isEmpty {
                            CollapsedPickerView(title: "Price", description: "Filter by Price")
                                .onTapGesture{
                                    withAnimation(.snappy){ selectedOption = .price}
                                }
                            /// "1 filter" instead of "filter" if  1 filter is selected
                        } else if filtersViewModel.selectedPrice.count == 1 {
                            let count = filtersViewModel.selectedPrice.count
                            CollapsedPickerView(title: "Price", description: "\(count) Filter Selected")
                                .onTapGesture{
                                    withAnimation(.snappy){ selectedOption = .price}
                                }
                            /// "_ filters" instead of "filter" if more than 1 filter is selected
                        } else {
                            let count = filtersViewModel.selectedPrice.count
                            CollapsedPickerView(title: "Price", description: "\(count) Filters Selected")
                                .onTapGesture{
                                    withAnimation(.snappy){ selectedOption = .price}
                                }
                        }
                    }
                }
                //MARK: Dietary Restrictions
                
                VStack{
                    if selectedOption == .dietary {
                        VStack(alignment: .leading){
                            DietaryFilter(filtersViewModel: filtersViewModel)
                        }
                        .modifier(CollapsibleFilterViewModifier(frame: 270))
                        .onTapGesture(count:2){
                            withAnimation(.snappy){ selectedOption = .noneSelected}}
                    }
                    else {
                        /// "Filter Dietary" if no options selected
                        if filtersViewModel.selectedDietary.isEmpty {
                            CollapsedPickerView(title: "Dietary Restrictions", description: "Filter by Dietary")
                                .onTapGesture{
                                    withAnimation(.snappy){ selectedOption = .dietary}
                                }
                            /// "1 filter" instead of "filter" if  1 filter is selected
                        } else if filtersViewModel.selectedDietary.count == 1 {
                            let count = filtersViewModel.selectedDietary.count
                            CollapsedPickerView(title: "Dietary Restrictions", description: "\(count) Filter Selected")
                                .onTapGesture{
                                    withAnimation(.snappy){ selectedOption = .dietary}
                                }
                            /// "_ filters" instead of "filter" if more than 1 filter is selected
                        } else {
                            let count = filtersViewModel.selectedDietary.count
                            CollapsedPickerView(title: "Dietary Restrictions", description: "\(count) Filters Selected")
                                .onTapGesture{
                                    withAnimation(.snappy){ selectedOption = .dietary}
                                }
                        }
                    }
                }
                
                //MARK: Cooking Time
                VStack{
                    if selectedOption == .cookingTime {
                        VStack(alignment: .leading){
                            CookingTimeFilter(filtersViewModel: filtersViewModel)
                        }
                        .modifier(CollapsibleFilterViewModifier(frame: 190))
                        .onTapGesture(count:2){
                            withAnimation(.snappy){ selectedOption = .noneSelected}}
                    }
                    else {
                        /// "Filter by Time" if no options selected
                        if filtersViewModel.selectedCookingTime.isEmpty {
                            CollapsedPickerView(title: "Cooking Time", description: "Filter by Time")
                                .onTapGesture{
                                    withAnimation(.snappy){ selectedOption = .cookingTime}
                                }
                            /// "1 filter" instead of "filter" if  1 filter is selected
                        } else {
                            let count = filtersViewModel.selectedCookingTime.count
                            CollapsedPickerView(title: "Cooking Time", description: "\(count) Filter Selected")
                                .onTapGesture{
                                    withAnimation(.snappy){ selectedOption = .cookingTime}
                                }
                        }
                    }
                }
            }
                Spacer()
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
    private func saveFilters() {
            Task {
                await filtersViewModel.fetchFilteredPosts()
            }
        }
}

#Preview {
    FiltersView(filtersViewModel: FiltersViewModel(feedViewModel: FeedViewModel(postService: PostService())))
}


struct CollapsedPickerView: View {
    let title: String
    let description: String
    var height: CGFloat = 64
    var body: some View {
        VStack{
            HStack {
                Text(title)
                    .foregroundStyle(.gray)
                Spacer()
                
                Text(description)
            }
            .fontWeight(.semibold)
            .font(.subheadline)
        }
        .padding()
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding()
        .shadow(radius: 10)
        
    }
}

enum FiltersViewOptions{
    case postType
    case location
    case cuisine
    case price
    case dietary
    case cookingTime
    case noneSelected
}

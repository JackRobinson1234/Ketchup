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
                    CollapsedPickerView(title: "Post Type", description: "Filter Post Type")
                        .onTapGesture{
                            withAnimation(.snappy){ selectedOption = .postType}
                        }
                }
            }
            
            //MARK: Location
            VStack {
                if selectedOption == .location {
                    VStack(alignment: .leading){
                        Text("Filter by Location")
                            .font(.title2)
                            .fontWeight(.semibold)
                        HStack{
                            Image(systemName: "magnifyingglass")
                                .imageScale(.small)
                            TextField("Search destinations", text: $locationText)
                                .font(.subheadline)
                                .frame(height:44)
                                .padding(.horizontal)
                        }
                        .frame(height: 44)
                        .padding(.horizontal)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(lineWidth: 1.0)
                                .foregroundStyle(Color(.systemGray4))
                        )
                    }
                    .modifier(CollapsibleFilterViewModifier())
                    .onTapGesture(count:2){
                        withAnimation(.snappy){ selectedOption = .noneSelected}
                    }
                    
                } else {
                    CollapsedPickerView(title: "Location", description: "Filter Location")
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
                            CollapsedPickerView(title: "Cuisine", description: "Filter Cuisine")
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
                            CollapsedPickerView(title: "Price", description: "Filter Price")
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
    case noneSelected
}

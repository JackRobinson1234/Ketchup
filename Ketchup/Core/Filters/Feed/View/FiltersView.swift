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

    @State private var cuisineText = ""
    @ObservedObject var filtersViewModel: FiltersViewModel
    
    init(filtersViewModel: FiltersViewModel) {
        self.filtersViewModel = filtersViewModel
    }
    
    var body: some View {
        NavigationStack {
            //MARK: Post Type
            ScrollView{
                VStack {
                    Button{
                        filtersViewModel.clearFilters()
                    } label: {
                        Text("Remove all filters")
                            .foregroundStyle(Color("Colors/AccentColor"))
                    }
//                    if selectedOption == .postType {
                        VStack(alignment: .leading){
                            PostTypeFilter(filtersViewModel: filtersViewModel)
                        }
                        .modifier(CollapsibleFilterViewModifier(frame: 140))
                        .onTapGesture(count:2){
                            withAnimation(.snappy){ selectedOption = .noneSelected}
                        }
                        
//                    } else {
//                        CollapsedPickerView(title: "Post Type", emptyDescription: "Filter by Post Type", count: filtersViewModel.updateSelectedPostTypes().count, singularDescription: {
//                            if filtersViewModel.atHomeChecked {
//                                return "At Home Posts"
//                            } else {
//                                return "Restaurant Posts"
//                            }
//                        }())
//                            .onTapGesture{
//                                withAnimation(.snappy){ selectedOption = .postType}
//                            }
//                    }
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
                        CollapsedPickerView(title: "Cuisine", emptyDescription: "Filter by Cuisine", count: filtersViewModel.selectedCuisines.count, singularDescription: "Cuisine Selected", pluralDescription: "Cuisines Selected")
                            .onTapGesture{
                                withAnimation(.snappy){ selectedOption = .cuisine}
                            }
                    }
                }
                
                
                //MARK: Location
                
                VStack {
                    if selectedOption == .location {
                        VStack{
                            LocationFilter(filtersViewModel: filtersViewModel)
                        }
                        .modifier(CollapsibleFilterViewModifier(frame: 250))
                        .onTapGesture(count:2){
                            withAnimation(.snappy){ selectedOption = .noneSelected}
                        }
                        
                    } else {
                        CollapsedPickerView(title: "Restaurant Location", emptyDescription: "Filter by Location", count: filtersViewModel.selectedLocation.count, singularDescription: "Location Selected")
                            .opacity(filtersViewModel.disableRestaurantFilters ? 0.5 : 1.0)
                            .allowsHitTesting(!filtersViewModel.disableRestaurantFilters)
                            .onTapGesture{
                                withAnimation(.snappy){ selectedOption = .location}
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
                            CollapsedPickerView(title: "Restaurant Price", emptyDescription: "Filter by Price", count: filtersViewModel.selectedPrice.count, singularDescription: "Price Selected", pluralDescription: "Prices Selected")
                                .opacity(filtersViewModel.disableRestaurantFilters ? 0.5 : 1.0)
                                .allowsHitTesting(!filtersViewModel.disableRestaurantFilters)
                                .onTapGesture{
                                    withAnimation(.snappy){ selectedOption = .price}
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
                            CollapsedPickerView(title: "At Home Dietary Restrictions", emptyDescription: "Filter by Dietary", count: filtersViewModel.selectedDietary.count, singularDescription: "Restriction Selected", pluralDescription: "Restrictions Selected")
                                .opacity(filtersViewModel.disableAtHomeFilters ? 0.5 : 1.0)
                                .allowsHitTesting(!filtersViewModel.disableAtHomeFilters)
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
                        CollapsedPickerView(title: "At Home Cooking Time", emptyDescription: "Filter by Time", count: filtersViewModel.selectedCookingTime.count, singularDescription: "Time Selected")
                            .opacity(filtersViewModel.disableAtHomeFilters ? 0.5 : 1.0)
                            .allowsHitTesting(!filtersViewModel.disableAtHomeFilters)
                            .onTapGesture{
                                withAnimation(.snappy){ selectedOption = .cookingTime}
                            }
                    }
                }
            }
            //MARK: Navigation Title
            .onChange(of: filtersViewModel.disableAtHomeFilters) {
                print("AtHome disabled: ", filtersViewModel.disableAtHomeFilters)
                print("Restaurant disabled: ",  filtersViewModel.disableRestaurantFilters)
                
            }
            .onChange(of: filtersViewModel.disableRestaurantFilters) {
                print("AtHome disabled: ",filtersViewModel.disableAtHomeFilters)
                print("Restaurant disabled: ", filtersViewModel.disableRestaurantFilters)
                
            }

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
        Task {
            await filtersViewModel.fetchFilteredPosts()
        }
    }
}

#Preview {
    FiltersView(filtersViewModel: FiltersViewModel(feedViewModel: FeedViewModel()))
}

//MARK: CollapsedPickerView
struct CollapsedPickerView: View {
    let title: String
    let emptyDescription: String
    var count: Int
    var singularDescription: String = "Filter Selected"
    var pluralDescription: String = "Filters Selected"
    
    var body: some View {
        VStack {
            HStack {
                Text(title)
                    .foregroundStyle(.gray)
                Spacer()
                if count == 0 {
                    Text(emptyDescription)
                } else if count == 1 {
                    if title != "Post Type" {
                        Text("1 \(singularDescription)")
                    } else {
                        Text(singularDescription)
                    }
                } else {
                    Text("\(count) \(pluralDescription)")
                }
            }
            .fontWeight(.semibold)
            .font(.subheadline)
        }
        .padding()
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding()
        .shadow(color: count > 0 ? Color("Colors/AccentColor") : .gray, radius: 10)
    }
}
//MARK: Filter Options Enum
enum FiltersViewOptions{
    case postType
    case location
    case cuisine
    case price
    case dietary
    case cookingTime
    case noneSelected
}

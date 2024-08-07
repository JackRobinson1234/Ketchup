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
                                .foregroundColor(.primary)
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
                    .foregroundStyle(.black)
                Spacer()
                if count == 0 {
                    Text(emptyDescription)
                        .foregroundStyle(.gray)
                } else if count == 1 {
                    if title != "Post Type" {
                        Text("1 \(singularDescription)")
                            .foregroundStyle(.black)
                    } else {
                        Text(singularDescription)
                            .foregroundStyle(.black)
                    }
                } else {
                    Text("\(count) \(pluralDescription)")
                        .foregroundStyle(.black)
                }
            }
            .fontWeight(.semibold)
            .font(.custom("MuseoSansRounded-300", size: 16))
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

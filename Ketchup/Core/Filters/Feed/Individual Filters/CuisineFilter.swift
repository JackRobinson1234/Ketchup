//
//  cuisineFilters.swift
//  Foodi
//
//  Created by Jack Robinson on 4/2/24.
//

import SwiftUI

struct CuisineFilter: View {
    @State private var filteredCuisines: [String] = cuisineCategories
    @State private var searchText = ""
    @ObservedObject var filtersViewModel: FiltersViewModel
    
    ///Maximum # of filters allowed to select
    @State private var maximumSelections: Int = 10
    
    var body: some View {
        VStack {
            //MARK: Title
            HStack{
                Text("Filter by Cuisine")
                    .font(.custom("MuseoSansRounded-300", size: 22))
                    .fontWeight(.semibold)
                    .foregroundStyle(.gray)
                Spacer()
            }
            .padding(.leading)
            //MARK: Subtitle
            HStack{
                Text("Cuisine Filters Selected (Max 10):")
                    .font(.custom("MuseoSansRounded-300", size: 10))
                    .foregroundStyle(.gray)
                Spacer()
            }
            .padding(.leading)
            //MARK: Selected Cuisines
            /// Selected cuisines from the list to be filtered by
            if !filtersViewModel.selectedCuisines.isEmpty{
                ScrollView(.horizontal){
                    HStack{
                        ForEach(filtersViewModel.selectedCuisines, id: \.self) { cuisine in
                            HStack {
                                Image(systemName: "xmark")
                                    .foregroundColor(Color("Colors/AccentColor"))
                                    .onTapGesture {
                                        withAnimation(.snappy) {
                                            filtersViewModel.selectedCuisines.removeAll(where: { $0 == cuisine })
                                        }
                                    }
                                Text(cuisine)
                                    .font(.custom("MuseoSansRounded-300", size: 10))
                                    .foregroundStyle(.gray)
                            }
                            .padding()
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .shadow(radius: 5)
                        }
                    }
                    .padding()
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            } else {
                HStack{
                    Text("No Cuisine Filters Selected")
                        .foregroundStyle(.gray)
                        .font(.custom("MuseoSansRounded-300", size: 16))
                        .bold()
                    Spacer()
                }
                .padding()
            }
            
            //MARK: Search Bar
            HStack{
                Image(systemName: "magnifyingglass")
                    .imageScale(.small)
                    .foregroundStyle(.gray)
                TextField("Search Cuisines", text: $searchText)
                    .font(.custom("MuseoSansRounded-300", size: 16))
                    .frame(height:44)
                    .padding(.horizontal)
                    .foregroundStyle(.gray)
                    .onChange(of: searchText) {oldValue, newValue in
                        filteredCuisines = filteredCuisine(newValue)
                    }
            }
            
            .frame(height: 44)
            .padding(.horizontal)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(lineWidth: 1.0)
                    .foregroundStyle(Color(.systemGray4)))
            //MARK: Selection Options
            /// If there are no selections and they haven't reached the maximum # of selections
            if !filteredCuisines.isEmpty && filtersViewModel.selectedCuisines.count < maximumSelections{
                ScrollView(.horizontal){
                    HStack{
                        ForEach(filteredCuisines, id: \.self) { cuisine in
                            Text(cuisine)
                                .foregroundStyle(.gray)
                                .font(.custom("MuseoSansRounded-300", size: 16))
                                .onTapGesture {
                                    withAnimation(.snappy) {
                                        if !filtersViewModel.selectedCuisines.contains(cuisine) {
                                            filtersViewModel.selectedCuisines.insert(cuisine, at: 0)}
                                    }
                                }
                                .padding()
                                .background(Color.white)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .shadow(radius: 5)
                        }
                    }
                    .padding()
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                /// if maximum filters are selected, display this message
            } else if filtersViewModel.selectedCuisines.count >= maximumSelections {
                Text("Maximum filters selected (max \(maximumSelections)")
                    .foregroundStyle(.gray)
                    .font(.custom("MuseoSansRounded-300", size: 16))
                    .padding()
            }
            
            /// if the search doesn't return any results
            else if filteredCuisines.isEmpty {
                Text("No cuisines matching \"\(searchText)\" found")
                    .foregroundStyle(.gray)
                    .font(.custom("MuseoSansRounded-300", size: 16))
                    .padding()
            }
            
        }
        /// updates what options should be shown when the lists change
       
        .onAppear{
            filteredCuisines = filteredCuisine(searchText)
        }
    }
    
    /// Takes in search text and returns the options that match the text
    /// - Parameter query: Search text from the search bar
    /// - Returns: Array of strings that match the query
    func filteredCuisine(_ query: String) -> [String] {
        if query.isEmpty{
            return cuisineCategories.filter { cuisine in
                !filtersViewModel.selectedCuisines.contains(cuisine)}
        } else {
            let lowercasedQuery = query.lowercased()
            let filtered = cuisineCategories.filter({
                $0.lowercased().contains(lowercasedQuery)
            }).map { $0.capitalized }
            return filtered.filter { cuisine in
                !filtersViewModel.selectedCuisines.contains(cuisine)
            }
        }
    }
}



#Preview {
    CuisineFilter(filtersViewModel: FiltersViewModel(feedViewModel: FeedViewModel()))
}

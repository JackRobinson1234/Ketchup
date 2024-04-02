//
//  cuisineFilters.swift
//  Foodi
//
//  Created by Jack Robinson on 4/2/24.
//

import SwiftUI

struct cuisineFilters: View {
    @State private var filteredCuisines: [String] = cuisineCategories
    @State private var searchText = ""
    @Binding var selectedCuisines: [String]
    
    
    var body: some View {
        VStack {
            /// Title
            HStack{
                Text("Filter by Cuisine")
                    .font(.title2)
                    .fontWeight(.semibold)
                Spacer()
            }
            .padding(.leading)
            
            /// Selected cuisines from the list to be filtered by
            if !selectedCuisines.isEmpty{
                ScrollView(.horizontal){
                    HStack{
                        ForEach(selectedCuisines, id: \.self) { cuisine in
                            HStack {
                                Image(systemName: "xmark")
                                    .foregroundColor(.red)
                                    .onTapGesture {
                                        withAnimation(.snappy) {
                                            selectedCuisines.removeAll(where: { $0 == cuisine })
                                        }
                                    }
                                Text(cuisine)
                                    .font(.caption)
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
                        .font(.subheadline)
                    Spacer()
                }
                .padding()
            }
            
            /// Search Bar
            HStack{
                Image(systemName: "magnifyingglass")
                    .imageScale(.small)
                TextField("Search Cuisines", text: $searchText)
                    .font(.subheadline)
                    .frame(height:44)
                    .padding(.horizontal)
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
            
            /// Selectable cuisine filter options
            if !filteredCuisines.isEmpty{
                ScrollView(.horizontal){
                    HStack{
                        ForEach(filteredCuisines, id: \.self) { cuisine in
                            Text(cuisine)
                                .font(.subheadline)
                                .onTapGesture {
                                    withAnimation(.snappy) {
                                        if !selectedCuisines.contains(cuisine) {
                                            selectedCuisines.insert(cuisine, at: 0)}
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
            }
            else {
                Text("No cuisines matching \"\(searchText)\" found")
                    .font(.subheadline)
            }
            
        }
        /// updates what options should be shown when the lists change
        .onChange(of: selectedCuisines) {oldValue, newValue in
            filteredCuisines = filteredCuisine(searchText)
        }
    }
    func filteredCuisine(_ query: String) -> [String] {
        if query.isEmpty{
            return cuisineCategories.filter { cuisine in
                !selectedCuisines.contains(cuisine)}
        } else {
            let lowercasedQuery = query.lowercased()
            let filtered = cuisineCategories.filter({
                $0.lowercased().contains(lowercasedQuery)
            }).map { $0.capitalized }
            return filtered.filter { cuisine in
                !selectedCuisines.contains(cuisine)
            }
        }
    }
}



#Preview {
    cuisineFilters(selectedCuisines: .constant([""]))
}

//
//  cuisineFilters.swift
//  Foodi
//
//  Created by Jack Robinson on 4/2/24.
//

import SwiftUI

struct cuisineFilters: View {
    @State private var filteredCuisines: [String] = cuisineCategories.map { $0.capitalized }
    @State private var searchText = ""
    
    
    var body: some View {
        VStack {
            HStack{
                Image(systemName: "magnifyingglass")
                    .imageScale(.small)
                TextField("Search destinations", text: $searchText)
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
                ScrollView(.horizontal){
                    HStack{
                        ForEach(filteredCuisines, id: \.self) { cuisine in
                            Text(cuisine)
                                .onTapGesture {
                                    // Handle selection
                                    print("Selected Cuisine: \(cuisine)")
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
            }
    }


func filteredCuisine(_ query: String) -> [String] {
    let lowercasedQuery = query.lowercased()
    return cuisineCategories.filter({
        $0.lowercased().contains(lowercasedQuery)
    }).map { $0.capitalized }
}
#Preview {
    cuisineFilters()
}

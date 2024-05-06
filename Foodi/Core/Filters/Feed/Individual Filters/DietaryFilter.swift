//
//  DietaryFilter.swift
//  Foodi
//
//  Created by Jack Robinson on 4/4/24.
//

import SwiftUI

struct DietaryFilter: View {
    @State private var filteredDietary: [String] = dietaryCategories
    @State private var searchText = ""
    @ObservedObject var filtersViewModel: FiltersViewModel
    
    ///Maximum # of filters allowed to select
    @State private var maximumSelections: Int = 10
    
    
    var body: some View {
        VStack {
            /// Title
            HStack{
                Text("Filter by Dietary Restrictions")
                    .font(.title2)
                    .fontWeight(.semibold)
                Spacer()
            }
            .padding(.leading)
            
            HStack{
                Text("Dietary Restriction Filters Selected (Max 10):")
                    .font(.caption)
                Spacer()
            }
            .padding(.leading)
            //MARK: Selected Dietary
            /// Selected dietaries  from the list to be filtered by
            if !filtersViewModel.selectedDietary.isEmpty{
                ScrollView(.horizontal){
                    HStack{
                        ForEach(filtersViewModel.selectedDietary, id: \.self) { dietary in
                            HStack {
                                Image(systemName: "xmark")
                                    .foregroundColor(.red)
                                    .onTapGesture {
                                        withAnimation(.snappy) {
                                            filtersViewModel.selectedDietary.removeAll(where: { $0 == dietary })
                                        }
                                    }
                                Text(dietary)
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
                    Text("No Dietary Filters Selected")
                        .font(.subheadline)
                        .bold()
                    Spacer()
                }
                .padding()
            }
            
            //MARK: Search Bar
            HStack{
                Image(systemName: "magnifyingglass")
                    .imageScale(.small)
                TextField("Search Dietary", text: $searchText)
                    .font(.subheadline)
                    .frame(height:44)
                    .padding(.horizontal)
                    .onChange(of: searchText) {oldValue, newValue in
                        filteredDietary = filteredDietary(newValue)
                    }
            }
            
            .frame(height: 44)
            .padding(.horizontal)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(lineWidth: 1.0)
                    .foregroundStyle(Color(.systemGray4)))
            //MARK: Dietary options
            /// If there are no selections and they haven't reached the maximum # of selections
            if !filteredDietary.isEmpty && filtersViewModel.selectedDietary.count < maximumSelections {
                ScrollView(.horizontal){
                    HStack{
                        ForEach(filteredDietary, id: \.self) { dietary in
                            Text(dietary)
                                .font(.subheadline)
                                .onTapGesture {
                                    withAnimation(.snappy) {
                                        if !filtersViewModel.selectedDietary.contains(dietary) {
                                            filtersViewModel.selectedDietary.insert(dietary, at: 0)}
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
            } else if filtersViewModel.selectedDietary.count >= maximumSelections {
                Text("Maximum filters selected (max \(maximumSelections)")
                    .font(.subheadline)
                    .padding()
            }
            
            /// if the search doesn't return any results
            else if filteredDietary.isEmpty {
                Text("No Dietary Restrictions matching \"\(searchText)\" found")
                    .font(.subheadline)
                    .padding()
            }
            
        }
        /// updates what options should be shown when the lists change
        .onChange(of: filtersViewModel.selectedDietary) {oldValue, newValue in
            filteredDietary = filteredDietary(searchText)
        }
        .onAppear{
            filteredDietary = filteredDietary(searchText)
        }
    }
    func filteredDietary(_ query: String) -> [String] {
        if query.isEmpty{
            return dietaryCategories.filter { dietary in
                !filtersViewModel.selectedDietary.contains(dietary)}
        } else {
            let lowercasedQuery = query.lowercased()
            let filtered = dietaryCategories.filter({
                $0.lowercased().contains(lowercasedQuery)
            }).map { $0.capitalized }
            return filtered.filter { dietary in
                !filtersViewModel.selectedDietary.contains(dietary)
            }
        }
    }
}

#Preview {
    DietaryFilter(filtersViewModel: FiltersViewModel(feedViewModel: FeedViewModel()))
}

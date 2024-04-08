//
//  CookingTime.swift
//  Foodi
//
//  Created by Jack Robinson on 4/5/24.
//

import SwiftUI

struct CookingTimeFilter: View {
    @ObservedObject var filtersViewModel: FiltersViewModel
    @State private var filteredCookingTime: [String] = []
    
    var body: some View {
        VStack {
            /// Title
            HStack{
                Text("Filter by Cooking Time")
                    .font(.title2)
                    .fontWeight(.semibold)
                Spacer()
            }
            .padding(.leading)
            HStack{
                Text("Cooking Time Filter Selected (Max 1):")
                    .font(.caption)
                Spacer()
            }
            .padding(.leading)
            
            //MARK: Selected prices
            /// Selected Prices from the list that have been selected
            if !filtersViewModel.selectedCookingTime.isEmpty {
                HStack{
                    HStack {
                        Image(systemName: "xmark")
                            .foregroundColor(.red)
                            .onTapGesture {
                                withAnimation(.snappy) {
                                    filtersViewModel.selectedCookingTime.removeAll()
                                }
                            }
                        Text("< \(String(filtersViewModel.selectedCookingTime.first ?? 0)) minutes")
                            .font(.caption)
                    }
                    .padding()
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .shadow(radius: 5)
                    Spacer()
                }
                .padding()
            }
            else {
                HStack{
                    Text("No Cooking Time Filter Selected")
                        .font(.subheadline)
                        .bold()
                    Spacer()
                }
                .padding()
            }
            //MARK: Price Options
            /// If there are still price options available
            if filtersViewModel.selectedCookingTime.isEmpty {
                ScrollView(.horizontal){
                    HStack{
                        ForEach(cookingTimeCategories, id: \.self) { cookingTime in
                            Text("< \(cookingTime) minutes")
                                .font(.subheadline)
                                .onTapGesture {
                                    withAnimation(.snappy) {
                                        filtersViewModel.selectedCookingTime.insert(cookingTime, at: 0)}
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
}

#Preview {
    CookingTimeFilter(filtersViewModel: FiltersViewModel(feedViewModel: FeedViewModel(postService: PostService())))
}

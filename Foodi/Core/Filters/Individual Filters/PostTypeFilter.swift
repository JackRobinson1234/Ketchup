//
//  PostTypeFilter.swift
//  Foodi
//
//  Created by Jack Robinson on 4/3/24.
//

import SwiftUI

struct PostTypeFilter: View {
    @ObservedObject var filtersViewModel: FiltersViewModel
    
    var body: some View {
        //MARK: Check Boxes
        VStack(alignment: .leading) {
            HStack{
                VStack (alignment: .leading) {
                    Text("Filter by Post Type")
                        .font(.title2)
                        .fontWeight(.semibold)
                    Text("At least one post type must be selected")
                        .font(.caption)
                }
                Spacer()
            }
            Toggle("Restaurant Posts", isOn: $filtersViewModel.restaurantChecked)
            Toggle("At Home Posts", isOn: $filtersViewModel.atHomeChecked)
        }
        .padding(.horizontal)
        .cornerRadius(8)
        .padding(.vertical, 8)
        
        ///Ensure that only one toggle is selected when the user clicks
        .onChange(of: [filtersViewModel.atHomeChecked]) {
            oneToggleSelected(lastChanged: "atHome")
                }
        .onChange(of: [filtersViewModel.restaurantChecked]) {
            oneToggleSelected(lastChanged: "restaurant")
                }
    }
    /// Ensures that there is at least one toggle selected
    /// - Parameter lastChanged: last parameter that got toggled
    
    private func oneToggleSelected(lastChanged: String) {
        if !filtersViewModel.restaurantChecked && !filtersViewModel.atHomeChecked {
            if lastChanged == "restaurant" {
                filtersViewModel.atHomeChecked = true
            } else if lastChanged == "atHome" {
                filtersViewModel.restaurantChecked = true
            }
        }
    }
}

#Preview {
    PostTypeFilter(filtersViewModel: FiltersViewModel(feedViewModel: FeedViewModel(postService: PostService())))
}

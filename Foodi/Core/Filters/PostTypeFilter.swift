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
            Toggle("Brand Posts", isOn: $filtersViewModel.brandChecked)
            Toggle("Recipe Posts", isOn: $filtersViewModel.recipeChecked)
        }
        .padding(.horizontal)
        .cornerRadius(8)
        .padding(.vertical, 8)
        .onChange(of: [filtersViewModel.restaurantChecked, filtersViewModel.brandChecked, filtersViewModel.recipeChecked]) {
                    oneToggleSelected()
                }
    }
    ///Ensures that there is at least one toggle selected
    private func oneToggleSelected() {
        if !filtersViewModel.restaurantChecked && !filtersViewModel.brandChecked && !filtersViewModel.recipeChecked {
                    // If none of the toggles are selected, you can handle this situation here
                    // For example, you can set one of the toggles to true by default
                    filtersViewModel.restaurantChecked = true
        }
    }
}

#Preview {
    PostTypeFilter(filtersViewModel: FiltersViewModel(feedViewModel: FeedViewModel(postService: PostService())))
}

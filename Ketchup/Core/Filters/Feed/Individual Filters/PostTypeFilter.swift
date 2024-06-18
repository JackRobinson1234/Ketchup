//
//  PostTypeFilter.swift
//  Foodi
//
//  Created by Jack Robinson on 4/3/24.
//

import SwiftUI

//struct PostTypeFilter: View {
//    @ObservedObject var filtersViewModel: FiltersViewModel
//    
//    var body: some View {
//        //MARK: Check Boxes
//        VStack(alignment: .leading) {
//            HStack{
//                VStack (alignment: .leading) {
//                    Text("Filter by Post Type")
//                        .font(.title2)
//                        .fontWeight(.semibold)
//                        .foregroundStyle(.gray)
//                    Text("At least one post type must be selected")
//                        .font(.caption)
//                        .foregroundStyle(.gray)
//                }
//                Spacer()
//            }
//            Toggle("Restaurant Posts", isOn: $filtersViewModel.restaurantChecked)
//                .foregroundStyle(.gray)
//            Toggle("At Home Posts", isOn: $filtersViewModel.atHomeChecked)
//                .foregroundStyle(.gray)
//        }
//        .padding(.horizontal)
//        .cornerRadius(8)
//        .padding(.vertical, 8)
//        
//        ///Ensure that only one toggle is selected when the user clicks
//        .onChange(of: [filtersViewModel.atHomeChecked]) {
//            oneToggleSelected(lastChanged: .cooking)
//            filtersViewModel.disableFilters()
//                }
//        .onChange(of: [filtersViewModel.restaurantChecked]) {
//            oneToggleSelected(lastChanged: .dining)
//            filtersViewModel.disableFilters()
//                }
//    }
//    /// Ensures that there is at least one toggle selected
//    /// - Parameter lastChanged: last parameter that got toggled
//    
//    private func oneToggleSelected(lastChanged: PostType) {
//        if !filtersViewModel.restaurantChecked && !filtersViewModel.atHomeChecked {
//            if lastChanged == .dining {
//                filtersViewModel.atHomeChecked = true
//            } else if lastChanged == .cooking {
//                filtersViewModel.restaurantChecked = true
//            }
//        }
//    }
//}
//
//#Preview {
//    PostTypeFilter(filtersViewModel: FiltersViewModel(feedViewModel: FeedViewModel()))
//}

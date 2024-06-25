//
//  RestaurantListView.swift
//  Foodi
//
//  Created by Jack Robinson on 2/1/24.
//

import SwiftUI
import InstantSearchSwiftUI

struct RestaurantListView: View {
    @ObservedObject var viewModel: SearchViewModel
    @Environment(\.dismiss) var dismiss
    var debouncer = Debouncer(delay: 1.0)
    
    var body: some View {
        
            InfiniteList(viewModel.restaurantHits, itemView: { hit in
                NavigationLink(value: hit.object) {
                    RestaurantCell(restaurant: hit.object)
                        .padding()
                }
                Divider()
            }, noResults: {
                Text("No results found")
                    .foregroundStyle(.primary)
            })
        }
    
}


//#Preview {
//    RestaurantListView()
//}

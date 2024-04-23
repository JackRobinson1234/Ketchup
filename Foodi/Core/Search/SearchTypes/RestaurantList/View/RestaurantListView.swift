//
//  RestaurantListView.swift
//  Foodi
//
//  Created by Jack Robinson on 2/1/24.
//

import SwiftUI
import InstantSearchSwiftUI

struct RestaurantListView: View {
    @StateObject var viewModel: RestaurantListViewModel
    private let config: RestaurantListConfig
    @Environment(\.dismiss) var dismiss
    var debouncer = Debouncer(delay: 1.0)
    
    
    init(config: RestaurantListConfig) {
        self.config = config
        self._viewModel = StateObject(wrappedValue: RestaurantListViewModel())}
    
    var body: some View {
        switch config {
        case .upload, .restaurants:
            InfiniteList(viewModel.hits, itemView: { hit in
                NavigationLink(value: hit.object) {
                    RestaurantCell(restaurant: hit.object)
                        .padding()
                }
                Divider()
            }, noResults: {
                Text("No results found")
            })
            .navigationTitle("Explore")
            .searchable(text: $viewModel.searchQuery,
                        prompt: "Search")
            .onChange(of: viewModel.searchQuery) {
                debouncer.schedule {
                    viewModel.notifyQueryChanged()
                }
            }
            
        }
    }
}


#Preview {
    RestaurantListView(config: .restaurants)
}

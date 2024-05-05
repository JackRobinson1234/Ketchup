//
//  CollectionsSearchListView.swift
//  Foodi
//
//  Created by Jack Robinson on 4/22/24.
//

import SwiftUI
import InstantSearchSwiftUI

struct CollectionsSearchListView: View {
    @StateObject var viewModel: CollectionListSearchViewModel
    var debouncer = Debouncer(delay: 1.0)

    init() {
        self._viewModel = StateObject(wrappedValue: CollectionListSearchViewModel())
    }

    var body: some View {
        InfiniteList(viewModel.hits, itemView: { hit in
            //NavigationLink(value: hit.object) {
            CollectionListCell(collection: hit.object)
                .padding()

            Divider()
        }, noResults: {
            Text("No results found")
        })
        .navigationTitle("Explore")
        .searchable(text: $viewModel.searchQuery, prompt: "Search")
        .onChange(of: viewModel.searchQuery) {
            debouncer.schedule {
                viewModel.notifyQueryChanged()
            }
        }
    }
}

#Preview {
    CollectionsSearchListView()
}

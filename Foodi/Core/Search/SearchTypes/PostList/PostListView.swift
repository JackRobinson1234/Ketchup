//
//  PostListView.swift
//  Foodi
//
//  Created by Jack Robinson on 2/1/24.
//

import SwiftUI
import InstantSearchSwiftUI
//DEBUG
struct PostListView: View {
    @StateObject var viewModel: PostListViewModel
    var debouncer = Debouncer(delay: 1.0)
    
    init() {
        self._viewModel = StateObject(wrappedValue: PostListViewModel())
    }
    
    var body: some View {
        InfiniteList(viewModel.hits, itemView: { hit in
            //NavigationLink(value: Post.object) {
                PostListCell(post: hit.object)
                    .padding()
            //}
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

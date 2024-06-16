//
//  UserListVIew.swift
//  Foodi
//
//  Created by Jack Robinson on 2/1/24.
//

import SwiftUI
import InstantSearchSwiftUI

struct UserListView: View {
    @StateObject var viewModel: UserListViewModel
    var debouncer = Debouncer(delay: 1.0)
    
    init() {
        self._viewModel = StateObject(wrappedValue: UserListViewModel())
    }
    
    
    var body: some View {
        InfiniteList(viewModel.hits, itemView: { hit in
            NavigationLink(value: hit.object) {
                UserCell(user: hit.object)
                    .padding()
            }
            Divider()
        }, noResults: {
            Text("No results found")
                .foregroundStyle(.primary)
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

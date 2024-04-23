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
        })
        .navigationTitle("Explore")
        .searchable(text: $viewModel.searchQuery,
                    prompt: "Search")
    }
}

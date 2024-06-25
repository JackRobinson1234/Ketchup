//
//  UserListVIew.swift
//  Foodi
//
//  Created by Jack Robinson on 2/1/24.
//

import SwiftUI
import InstantSearchSwiftUI

struct UserListView: View {
    @ObservedObject var viewModel: SearchViewModel
    var debouncer = Debouncer(delay: 1.0)
    
    
    var body: some View {
        
            InfiniteList(viewModel.userHits, itemView: { hit in
                NavigationLink(value: hit.object) {
                    UserCell(user: hit.object)
                        .padding()
                }
                Divider()
            }, noResults: {
                Text("No results found")
                    .foregroundStyle(.primary)
            })
        
    }
}

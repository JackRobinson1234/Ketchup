//
//  CollectionsSearchListView.swift
//  Foodi
//
//  Created by Jack Robinson on 4/22/24.
//

import SwiftUI
import InstantSearchSwiftUI

struct CollectionsSearchListView: View {
    @StateObject var viewModel = CollectionListSearchViewModel()
    var debouncer = Debouncer(delay: 1.0)
    @State var showCollection = false
    @State var selectedCollection: Collection? = nil
    @StateObject var collectionsViewModel = CollectionsViewModel(user: AuthService.shared.userSession!)

   
    var body: some View {
        ScrollView{
            InfiniteList(viewModel.hits, itemView: { hit in
                Button{
                    collectionsViewModel.selectedCollection = hit.object
                    showCollection = true
                } label: {
                    CollectionListCell(collection: hit.object)
                        .padding()
                }
                    
                
                Divider()
            }, noResults: {
                Text("No results found")
                    .foregroundStyle(.primary)
            })
            .navigationTitle("Explore")
            .searchable(text: $viewModel.searchQuery, prompt: "Search")
            .onChange(of: viewModel.searchQuery) {
                debouncer.schedule {
                    viewModel.notifyQueryChanged()
                }
            }
            .sheet(isPresented: $showCollection) {
                    CollectionView(collectionsViewModel: collectionsViewModel)
            }
        }
    }
}

#Preview {
    CollectionsSearchListView(viewModel: CollectionListSearchViewModel())
}

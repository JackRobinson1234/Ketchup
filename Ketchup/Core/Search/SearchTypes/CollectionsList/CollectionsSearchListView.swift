//
//  CollectionsSearchListView.swift
//  Foodi
//
//  Created by Jack Robinson on 4/22/24.
//

import SwiftUI
import InstantSearchSwiftUI

struct CollectionsSearchListView: View {
    @ObservedObject var viewModel: SearchViewModel
    var debouncer = Debouncer(delay: 1.0)
    @State var showCollection = false
    @State var selectedCollection: Collection? = nil
    @StateObject var collectionsViewModel = CollectionsViewModel()

   
    var body: some View {
            InfiniteList(viewModel.collectionHits, itemView: { hit in
                Button{
                    collectionsViewModel.selectedCollection = hit.object
                    showCollection = true
                } label: {
                    CollectionListCell(collection: hit.object, collectionsViewModel: collectionsViewModel)
                        .padding()
                }
                    
                
                Divider()
            }, noResults: {
                Text("No results found")
                    .foregroundStyle(.black)
            })
            .sheet(isPresented: $showCollection) {
                    CollectionView(collectionsViewModel: collectionsViewModel)
            }
    }
}

//#Preview {
//    CollectionsSearchListView(viewModel: CollectionListSearchViewModel())
//}

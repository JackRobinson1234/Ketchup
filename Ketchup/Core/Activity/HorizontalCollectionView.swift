//
//  HorizontalCollectionView.swift
//  Ketchup
//
//  Created by Jack Robinson on 7/13/24.
//

import SwiftUI

struct HorizontalCollectionScrollView: View {
    @StateObject private var viewModel = HorizontalCollectionViewModel()
    @StateObject var collectionsViewModel
    var body: some View {
        VStack{
            Text("Explore Collections")
                .font(.custom("MuseoSansRounded-300", size: 10))
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 10) {
                    ForEach(viewModel.collections) { collection in
                        VStack {
                            CollageImage(collection: collection, width: 150)
                            Text(collection.name)
                                .font(.custom("MuseoSansRounded-300", size: 14))
                                .lineLimit(2)
                            Text(("by \(collection.username)"))
                        }
                        .frame(width: 150)
                        .onAppear {
                            if collection == viewModel.collections.last {
                                viewModel.loadMore()
                            }
                        }
                    }
                    if viewModel.isLoading {
                        ProgressView()
                    }
                }
                .padding()
            }
            .task {
                viewModel.loadInitialCollections()
            }
        }
    }
}

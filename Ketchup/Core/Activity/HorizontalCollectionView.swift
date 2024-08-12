//
//  HorizontalCollectionView.swift
//  Ketchup
//
//  Created by Jack Robinson on 7/13/24.
//

import SwiftUI

struct HorizontalCollectionScrollView: View {
    @StateObject var viewModel = CollectionsViewModel()
    @State var showCollection: Bool = false
    @State var searchCollections: Bool = false
    @State var showSearchView: Bool = false
    var body: some View {
        VStack{
            HStack(alignment: .top){
                
                Text("Explore Collections")
                    .font(.custom("MuseoSansRounded-700", size: 25))
                Spacer()
                Button{
                    showSearchView.toggle()
                } label : {
                    VStack{
                        Image(systemName: "magnifyingglass")
                            .resizable()
                            .scaledToFit()
                            
                        Text("Search")
                            .font(.custom("MuseoSansRounded-300", size: 12))
                    }
                    .frame(height: 40)
                    .foregroundStyle(.gray)
                }
            }
            .padding(.horizontal)
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(alignment: .top, spacing: 20) {
                    
                    ForEach(viewModel.collections) { collection in
                        VStack {
                            Button{
                                viewModel.updateSelectedCollection(collection: collection)
                                showCollection.toggle()
                            } label: {
                                VStack{
                                    if let cover = collection.coverImageUrl {
                                        CollageImage(tempImageUrls: [cover], width: 160)
                                    } else if let tempImageUrls = collection.tempImageUrls {
                                        CollageImage(tempImageUrls: tempImageUrls, width: 160)
                                    }
                                    Text(collection.name)
                                        .font(.custom("MuseoSansRounded-700", size: 14))
                                        .lineLimit(2)
                                        .foregroundStyle(.black)
                                    Text(("by @\(collection.username)"))
                                        .font(.custom("MuseoSansRounded-300", size: 12))
                                        .foregroundStyle(.black)
                                }
                                .frame(width: 160)
                            }
                        }
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
                .padding(.horizontal)
            }
            .task {
                viewModel.loadInitialCollections()
            }
            .fullScreenCover(isPresented: $showCollection) {CollectionView(collectionsViewModel: viewModel)}
            .fullScreenCover(isPresented: $showSearchView) {
                SearchView(initialSearchConfig: .collections)
            }
        }
    }
}

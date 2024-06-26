//
//  PostListView.swift
//  Foodi
//
//  Created by Jack Robinson on 2/1/24.
//
import InstantSearch
import InstantSearchCore
import SwiftUI
import InstantSearchSwiftUI
//DEBUG
struct PostListView: View {
    @StateObject var viewModel: PostListViewModel
    var debouncer = Debouncer(delay: 1.0)
    private var filterState = FilterState()
    @State private var selectedPost: Post?
    init() {
        self._viewModel = StateObject(wrappedValue: PostListViewModel())
    }
    
    var body: some View {
            
            //MARK: Search Results
            InfiniteList(viewModel.hits, itemView: { hit in
                //NavigationLink(value: Post.object) {
                Button{selectedPost = hit.object} label: {
                    PostListCell(post: hit.object)
                        .padding()
                }
                //}
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
            .sheet(item: $selectedPost) { post in
                let feedViewModel = FeedViewModel(posts: [post])
                FeedView(viewModel: feedViewModel, hideFeedOptions: true)
                    .onDisappear {
                        //player.replaceCurrentItem(with: nil)
                    }
            }
        
    }
        
}

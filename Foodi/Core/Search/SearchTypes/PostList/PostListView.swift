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
    @State var isDropdownExpanded = false
    private var filterState = FilterState()
    init() {
        self._viewModel = StateObject(wrappedValue: PostListViewModel())
    }
    
    var body: some View {
            
            //MARK: Search Results
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
/*
//MARK: DropdownMenuView
struct DropdownMenuView: View {
    @ObservedObject var viewModel: PostListViewModel
    @Binding var isDropdownExpanded: Bool
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Button(action: {
                viewModel.showAtHomePosts.toggle()
                if !viewModel.showAtHomePosts && !viewModel.showRestaurantPosts {
                    // Switch to the other option if both are unchecked
                    viewModel.showRestaurantPosts.toggle()
                }
            }) {
                HStack {
                    Text("At Home")
                    Spacer()
                    if viewModel.showAtHomePosts {
                        Image(systemName: "checkmark")
                    }
                }
            }
            .padding(.horizontal)
            
            Button(action: {
                viewModel.showRestaurantPosts.toggle()
                if !viewModel.showAtHomePosts && !viewModel.showRestaurantPosts {
                    // Switch to the other option if both are unchecked
                    viewModel.showAtHomePosts.toggle()
                }
            }) {
                HStack {
                    
                    Text("Restaurant")
                    Spacer()
                    if viewModel.showRestaurantPosts {
                        Image(systemName: "checkmark")
                    }
                }
            }
            .padding(.horizontal)
        }
        .cornerRadius(8)
        .shadow(radius: 5)
        .padding(.horizontal)
        .animation(.easeInOut, value: isDropdownExpanded)
    }
}
*/

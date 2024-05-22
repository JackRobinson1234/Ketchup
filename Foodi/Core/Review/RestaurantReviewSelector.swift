//
//  RestaurantReviewSelector.swift
//  Foodi
//
//  Created by Jack Robinson on 5/21/24.
//

import SwiftUI
import InstantSearchSwiftUI

struct RestaurantReviewSelector: View {
    @StateObject var viewModel = RestaurantListViewModel()
    @Environment(\.dismiss) var dismiss
    @ObservedObject var reviewsViewModel: ReviewsViewModel
    var debouncer = Debouncer(delay: 1.0)
    @State var selectedItem: CollectionItem?

    
    var body: some View {
        NavigationStack{
            InfiniteList(viewModel.hits, itemView: { hit in
                    NavigationLink(value: hit.object) {
                        RestaurantCell(restaurant: hit.object)
                            .padding(.leading)
                    }
                Divider()
            }, noResults: {
                Text("No results found")
            })
            
            .navigationDestination(for: Restaurant.self) { restaurant in
                CreateReviewView(viewModel: reviewsViewModel, restaurant: restaurant)
            }
            .navigationTitle("Write a Review")
            .searchable(text: $viewModel.searchQuery,
                        prompt: "Search")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Text("Cancel")
                    }
                }
            }
            .toolbar(.hidden, for: .tabBar)
            .navigationBarBackButtonHidden()
            .onChange(of: viewModel.searchQuery) {
                debouncer.schedule {
                    viewModel.notifyQueryChanged()
                }
            }
           
        }
//        .onAppear{
//            if collectionsViewModel.dismissListView {
//                collectionsViewModel.dismissListView = false
//                dismiss()
//                
//            }
//        }
    }
}

//#Preview {
//    RestaurantReviewSelector()
//}

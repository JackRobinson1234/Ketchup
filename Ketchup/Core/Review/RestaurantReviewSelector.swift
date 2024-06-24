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
    @State var createRestaurantView = false
    @State var dismissSearchView: Bool = false
   
    

    
    var body: some View {
        NavigationStack{
            VStack{
                Button{
                    createRestaurantView.toggle()
                } label: {
                    VStack{
                        Text("Can't find the restaurant you're looking for?")
                            .foregroundStyle(.gray)
                            .font(.custom("MuseoSansRounded-300", size: 10))
                        Text("Request a Restaurant")
                            .foregroundStyle(Color("Colors/AccentColor"))
                            .font(.custom("MuseoSansRounded-300", size: 10))
                    }
                }
                InfiniteList(viewModel.hits, itemView: { hit in
                    //NavigationLink(value: hit.object) {
                    Button{
                        reviewsViewModel.restaurantRequest = nil
                        reviewsViewModel.selectedRestaurant = hit.object
                        dismiss()
                    } label: {
                        RestaurantCell(restaurant: hit.object)
                            .padding(.leading)
                    }
                    Divider()
                }, noResults: {
                    Text("No results found")
                })
            }
//            .navigationDestination(for: Restaurant.self) { restaurant in
//                UploadWrittenReviewView(reviewViewModel: reviewsViewModel, restaurant: restaurant, setRestaurant: true)
//            }
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
            .fullScreenCover(isPresented: $createRestaurantView) {
                ReviewCreateRestaurantView(reviewsViewModel: reviewsViewModel, dismissListView: $dismissSearchView)
                    .onDisappear{
                        if dismissSearchView{
                            dismiss()
                        
                    }
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

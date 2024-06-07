//
//  ReviewListView.swift
//  Foodi
//
//  Created by Jack Robinson on 5/20/24.
//

import SwiftUI

struct ReviewListView: View {
    @ObservedObject var viewModel: ReviewsViewModel
    @State var showAddReview: Bool = false
    @State var showRestaurantSelector: Bool = false
    
    var body: some View {
        VStack{
            if viewModel.isLoading {
                ProgressView("Loading...")
                    .toolbar(.hidden, for: .tabBar)
                    .onAppear{
                        Task{
                            try await viewModel.fetchReviews()
                        }
                        viewModel.isLoading = false
                    }
            }
            else{
                //MARK: Add Collection Button
                    LazyVStack(alignment: .leading){
                        if let restaurant = viewModel.selectedRestaurant{
                            Button{
                                showAddReview.toggle()
                            } label: {
                                CreateReviewButton()
                            }
                            .padding(.vertical)
                        } else if let user = viewModel.selectedUser, user.isCurrentUser {
                            Button{
                                showRestaurantSelector.toggle()
                            } label: {
                                CreateReviewButton()
                            }
                        }
                        Divider()
                        if !viewModel.reviews.isEmpty {
                            ForEach(viewModel.reviews) { review in
                                ReviewCell(review: review, viewModel: viewModel)
                                Divider()
                            }
                        } else {
                            HStack{
                                Spacer()
                                Text("No reviews yet!")
                                    .font(.subheadline)
                                    .foregroundStyle(.gray)
                                Spacer()
                            }
                    }
                }
            }
        }
        .sheet(isPresented: $showAddReview) {
            NavigationStack{
                CreateReviewView(viewModel: viewModel)
            }
        }
        .sheet(isPresented: $showRestaurantSelector) {
            RestaurantReviewSelector(reviewsViewModel: viewModel)
                .onDisappear{
                    viewModel.selectedRestaurant = nil
                }
        }
    }
}

#Preview {
    ReviewListView(viewModel: ReviewsViewModel())
}

struct CreateReviewButton: View {
    var body: some View {
        HStack{
            Image(systemName: "plus")
                .resizable()
                .scaledToFit()
                .frame(width: 20)
                .foregroundStyle(.blue.opacity(1))
                .padding(.horizontal)
            VStack(alignment: .leading){
                Text("Add a New Review")
                    .font(.subheadline)
                    .foregroundStyle(.black)
            }
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundStyle(.black)
                .padding(.horizontal)
        }
        .padding(.horizontal)
    }
}

#Preview {
    CreateReviewButton()
}

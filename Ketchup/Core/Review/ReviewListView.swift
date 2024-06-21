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
                //MARK: Add REVIEW Button
                    LazyVStack(alignment: .leading){
                        
                        if viewModel.selectedRestaurant != nil{
                            Divider()
                            Button{
                                showAddReview.toggle()
                            } label: {
                                CreateReviewButton()
                            }
                            .padding(.vertical)
                        } else if let user = viewModel.selectedUser, user.isCurrentUser {
                            Divider()
                            Button{
    
                                showRestaurantSelector.toggle()
                            } label: {
                                CreateReviewButton()
                            }
                            .padding(.vertical)
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
        .fullScreenCover(isPresented: $showAddReview) {
            NavigationStack{
                UploadWrittenReviewView(reviewViewModel: viewModel, setRestaurant: true)
                    .toolbar {
                        ToolbarItemGroup(placement: .keyboard) {
                            Spacer()
                            Button("Done") {
                                dismissKeyboard()
                            }
                        }
                    }
            }
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        dismissKeyboard()
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $showRestaurantSelector) {
            NavigationStack{
                UploadWrittenReviewView(reviewViewModel: viewModel)
                    .toolbar {
                        ToolbarItemGroup(placement: .keyboard) {
                            Spacer()
                            Button("Done") {
                                dismissKeyboard()
                            }
                        }
                    }
                
            }
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        dismissKeyboard()
                    }
                }
            }
            
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
                .foregroundStyle(Color("Colors/AccentColor"))
                .padding(.horizontal)
            VStack(alignment: .leading){
                Text("Create a New Review")
                    .font(.subheadline)
                    .foregroundStyle(.primary)
            }
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundStyle(.primary)
                .padding(.horizontal)
        }
        .padding(.horizontal)
    }
}

#Preview {
    CreateReviewButton()
}

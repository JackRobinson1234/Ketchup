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

    var body: some View {
        VStack{
            if viewModel.isLoading {
                ProgressView("Loading...")
                    .toolbar(.hidden, for: .tabBar)
            }
            else{
                //MARK: Add Collection Button
                VStack{
                    Button{
                        showAddReview.toggle()
                    } label: {
                        CreateReviewButton()
                    }
                    .padding(.vertical)
                    Divider()
                }
            }
        }
        
        .sheet(isPresented: $showAddReview) {
            if let restaurant = viewModel.selectedRestaurant {
                CreateReviewView(restaurant: restaurant)}
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

//
//  RestaurantProfileView.swift
//  Foodi
//
//  Created by Jack Robinson on 2/2/24.
//

import SwiftUI

struct RestaurantProfileView: View {
    @Environment(\.dismiss) var dismiss
    @State var currentSection: Section
    @StateObject var viewModel: RestaurantViewModel
    @State private var isLoading = true
    private let restaurantService = RestaurantService()
    private let restaurantId: String
    private let restaurant: Restaurant?
    @State var showAddToCollection = false
    @State var user: User? = nil
    
    init(restaurantId: String, currentSection: Section = .posts, restaurant: Restaurant? = nil) {
        self.restaurantId = restaurantId
        let restaurantViewModel = RestaurantViewModel(restaurantId: restaurantId,
                                                      restaurantService: RestaurantService(),
                                                      postService: PostService())
        
        self._viewModel = StateObject(wrappedValue: restaurantViewModel)
        self._currentSection = State(initialValue: currentSection)
        self.restaurant = restaurant
    }
    
    
    var body: some View {
        if isLoading {
            // Loading screen
            ProgressView("Loading...")
                .onAppear {
                    Task {
                        viewModel.restaurant = restaurant
                        try await viewModel.fetchRestaurant(id: restaurantId)
                        isLoading = false
                    }
                }
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "chevron.left")
                                .foregroundStyle(.white)
                                .background(
                                    Circle()
                                        .fill(Color.gray.opacity(0.5)) // Adjust the opacity as needed
                                        .frame(width: 30, height: 30) // Adjust the size as needed
                                )
                        }
                    }
                }
        } else {
            VStack{
                if viewModel.restaurant != nil {
                    RestaurantProfileHeaderView(currentSection: $currentSection, viewModel: viewModel)
                }
            }
            .overlay(alignment: .topTrailing) {
                Button{
                    Task{
                        try await self.user = UserService().fetchCurrentUser()
                        if user != nil{
                            showAddToCollection.toggle()
                        }
                    }
                } label: {
                    Image(systemName: "folder.badge.plus")
                        .resizable()
                        .scaledToFill()
                        .foregroundStyle(.black)
                        .frame(width: 30, height: 30)
            }
                .padding(20)
            }

            .navigationBarBackButtonHidden()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .tabBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .foregroundStyle(.white)
                            .background(
                                Circle()
                                    .fill(Color.gray.opacity(0.5)) // Adjust the opacity as needed
                                    .frame(width: 30, height: 30) // Adjust the size as needed
                            )
                    }
                }
            }
            
            .sheet(isPresented: $showAddToCollection) {
                if let user {
                    AddItemCollectionList(user: user, restaurant: viewModel.restaurant)
                }
            }
        }
    }
}
/*
#Preview {
    RestaurantProfileView(restaurantId: DeveloperPreview.restaurants[0].id)
}
*/

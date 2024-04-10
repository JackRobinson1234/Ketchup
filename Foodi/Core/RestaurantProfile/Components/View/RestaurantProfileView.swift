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
                        await viewModel.fetchRestaurant(id: restaurantId)
                        isLoading = false
                    }
                }
        } else{
            
            VStack{
                if let restaurant = viewModel.restaurant{
                    RestaurantProfileHeaderView( restaurant: restaurant, currentSection: $currentSection, posts: viewModel.posts)
                }
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
                            .padding()
                    }
                }
            }
            
            .overlay(alignment: .bottom) {
                CTAButtonOverlay()
                
            }
        }
    }
}
/*
#Preview {
    RestaurantProfileView(restaurantId: DeveloperPreview.restaurants[0].id)
}
*/

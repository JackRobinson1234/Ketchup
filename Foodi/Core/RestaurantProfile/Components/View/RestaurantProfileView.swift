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
    private let restaurantService = RestaurantService()
    
    
    init(restaurant: String, currentSection: Section = .posts) {
        let restaurantViewModel = RestaurantViewModel(restaurantId: restaurant,
                                                      restaurantService: RestaurantService(),
                                                      postService: PostService())
        
        self._viewModel = StateObject(wrappedValue: restaurantViewModel)
        self._currentSection = State(initialValue: currentSection)
    }
    
 
    var body: some View {
        
        VStack{
            RestaurantProfileHeaderView(viewModel: viewModel, currentSection: $currentSection)
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
                }
            }
        }
        
        .overlay(alignment: .bottom) {
            CTAButtonOverlay()
    
        }
    }
}

#Preview {
    RestaurantProfileView(restaurant: DeveloperPreview.restaurants[0])
}

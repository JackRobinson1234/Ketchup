//
//  RestaurantProfileView.swift
//  Foodi
//
//  Created by Jack Robinson on 2/2/24.
//

import SwiftUI

struct RestaurantProfileView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject var viewModel: RestaurantViewModel
    @State private var isLoading = true
    private let restaurantId: String
    private let restaurant: Restaurant?
    @State var dragDirection = "left"
    @State var isDragging = false
    @State private var scrollPosition: String?
    @State private var scrollTarget: String?
    
    init(restaurantId: String, restaurant: Restaurant? = nil) {
        self.restaurantId = restaurantId
        let restaurantViewModel = RestaurantViewModel(restaurantId: restaurantId)
        self._viewModel = StateObject(wrappedValue: restaurantViewModel)
        self.restaurant = restaurant
    }
    var drag: some Gesture {
        DragGesture(minimumDistance: 50)
            .onChanged { _ in self.isDragging = true }
            .onEnded { endedGesture in
                if (endedGesture.location.x - endedGesture.startLocation.x) > 0 {
                    self.dragDirection = "left"
                    if viewModel.currentSection == .posts {
                        dismiss()
                    } else if viewModel.currentSection == .collections{
                        viewModel.currentSection = .posts
                    }
                } else {
                    self.dragDirection = "right"
                    if viewModel.currentSection == .posts {
                        viewModel.currentSection = .collections
                        
                    }
                    self.isDragging = false
                }
            }
    }
    
    var body: some View {
        if isLoading {
            ProgressView("Loading...")
                .gesture(drag)
                .onAppear {
                    Task {
                        do {
                            viewModel.restaurant = restaurant
                            try await viewModel.fetchRestaurant(id: restaurantId)
                        } catch {
                            print("DEBUG: Failed to fetch restaurant with error: \(error.localizedDescription)")
                        }
                        isLoading = false
                    }
                }
                .toolbar(.hidden)
                .navigationBarBackButtonHidden()
                .ignoresSafeArea(edges: .top)
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
            if viewModel.restaurant != nil {
                ScrollViewReader{ scrollProxy in
                    ScrollView{
                        VStack{
                            if viewModel.restaurant != nil {
                                RestaurantProfileHeaderView(viewModel: viewModel, scrollPosition: $scrollPosition,
                                                            scrollTarget: $scrollTarget)
                            } else {
                                
                            }
                        }
                        
                    }
                    .scrollPosition(id: $scrollPosition)
                    .onChange(of: scrollTarget) {
                        scrollPosition = scrollTarget
                        scrollProxy.scrollTo(scrollTarget, anchor: .center)
                    }
                }
                .gesture(drag)
                .ignoresSafeArea(edges: .top)
                .navigationBarBackButtonHidden()
                .toolbar(.hidden, for: .tabBar)
                .toolbar(.hidden)
                .onAppear{
                    LocationManager.shared.requestLocation()
                }
            } else {
                VStack{
                    Text("Profile Under Construction")
                        .modifier(BackButtonModifier())
                        .navigationBarBackButtonHidden()
                }
                .gesture(drag)
                
            }
        }
    }
}

#Preview {
    RestaurantProfileView(restaurantId: DeveloperPreview.restaurants[0].id)
}


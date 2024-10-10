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
    @StateObject var feedViewModel = FeedViewModel(showBookmarks: false)
    init(restaurantId: String, restaurant: Restaurant? = nil) {
        self.restaurantId = restaurantId
        let restaurantViewModel = RestaurantViewModel(restaurantId: restaurantId)
        self._viewModel = StateObject(wrappedValue: restaurantViewModel)
        self.restaurant = restaurant
    }
    var drag: some Gesture {
        DragGesture(minimumDistance: 15)
            .onChanged { _ in self.isDragging = true }
            .onEnded { endedGesture in
                if (endedGesture.location.x - endedGesture.startLocation.x) > 0 {
                    self.dragDirection = "left"
                    if viewModel.currentSection == .posts {
                        dismiss()
                    } else if viewModel.currentSection == .collections{
                        viewModel.currentSection = .stats
                    }  else if viewModel.currentSection == .stats{
                        viewModel.currentSection = .posts
                    }
                    
                } else {
                    self.dragDirection = "right"
                    if viewModel.currentSection == .posts {
                        viewModel.currentSection = .stats
                    }  else if viewModel.currentSection == .stats {
                        viewModel.currentSection = .collections
                    }
                    self.isDragging = false
                }
            }
    }
    
    var body: some View {
        if isLoading {
            FastCrossfadeFoodImageView()
                .gesture(drag)
                .onAppear {
                    Task {
                        do {
                            viewModel.restaurant = restaurant
                            try await viewModel.fetchRestaurant(id: restaurantId)
                            await viewModel.fetchFriendsWhoPosted()
                            if let restaurant = viewModel.restaurant{
                                try await feedViewModel.fetchRestaurantPosts(restaurant: restaurant, friendIds: viewModel.friendsWhoPosted.map { $0.id })
                                viewModel.calculateRatings(from: restaurant.ratingStats)
                            }
                           
                            
                        } catch {
                            ////print("DEBUG: Failed to fetch restaurant with error: \(error.localizedDescription)")
                        }
                        isLoading = false
                    }
                }
                .navigationBarBackButtonHidden()
                .ignoresSafeArea(edges: .top)
                .modifier(BackButtonModifier())
            
        } else {
            if let restaurant = viewModel.restaurant {
                ScrollViewReader{ scrollProxy in
                    ScrollView(showsIndicators: false){
                        VStack{
                            if viewModel.restaurant != nil {
                                RestaurantProfileHeaderView(feedViewModel: feedViewModel, viewModel: viewModel, scrollPosition: $scrollPosition, scrollTarget: $scrollTarget)
                                    .onAppear{
                                        Task{
                                            viewModel.isLoadingSimilarRestaurants = true
                                            await viewModel.fetchSimilarRestaurants()
                                            viewModel.isLoadingSimilarRestaurants = false
                                        }
                                    }
                            } else {
                                
                            }
                        }
                    }
                    
                    .onChange(of: viewModel.scrollTarget) { newTarget in
                                        ////print("DEBUG: scrollTarget changed to \(String(describing: newTarget))")
                                        scrollPosition = viewModel.scrollTarget
                                        
                                        if let target = viewModel.scrollTarget {
                                            ////print("DEBUG: Attempting to scroll to \(target)")
                                            withAnimation {
                                                scrollProxy.scrollTo(target, anchor: .top)
                                            }
                                            ////print("DEBUG: Scroll animation triggered")
                                        } else {
                                            ////print("DEBUG: scrollTarget is nil, no scrolling performed")
                                        }
                                        
                                        DispatchQueue.main.async {
                                            ////print("DEBUG: Resetting scrollTarget to nil")
                                            viewModel.scrollTarget = nil
                                        }
                                    }
                    //.scrollPosition(id: $scrollPosition)
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
                ZStack {
                    Color.clear
                        .contentShape(Rectangle())
                        .gesture(drag)
                        .ignoresSafeArea()
                    
                    VStack(spacing: 10) {
                        Image("Skip")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 150, height: 150)
                            
                        Text("Profile Under Construction")
                            .modifier(BackButtonModifier())
                            .font(.custom("MuseoSansRounded-500", size: 16))
                            .foregroundStyle(.black)
                        
                    }
                }
                .navigationBarBackButtonHidden()
            }
        }
    }
}

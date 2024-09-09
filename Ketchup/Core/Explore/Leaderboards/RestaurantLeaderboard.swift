//
//  RestaurantLeaderboard.swift
//  Ketchup
//
//  Created by Jack Robinson on 9/9/24.
//

import SwiftUI

struct RestaurantLeaderboard: View {
    @ObservedObject var viewModel: LeaderboardViewModel
    @State private var topRestaurants: [Restaurant] = []
    @State private var isLoading = true
    @State private var selectedRestaurant: Restaurant?
    @Environment(\.dismiss) var dismiss
    @State private var canSwitchTab = true
    
    var topImage: String?
    var title: String
    var state: String?
    var city: String?

    var body: some View {
        NavigationStack {
            VStack {
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(alignment: .leading, spacing: 4) {
                        headerSection
                        timePeriodPicker
                        
                        if isLoading {
                            loadingView
                        } else {
                            restaurantList
                        }
                    }
                }
            }
            .edgesIgnoringSafeArea(.top)
            .navigationDestination(for: Restaurant.self) { restaurant in
                RestaurantProfileView(restaurantId: restaurant.id)
            }
        }
        .onAppear(perform: fetchRestaurants)
    }
    
    private var headerSection: some View {
        ZStack(alignment: .bottomLeading) {
            if let imageURL = topImage {
                if let imageURL = topImage {
                    ListingImageCarouselView(images: [imageURL])
                        .overlay(
                            LinearGradient(
                                gradient: Gradient(stops: [
                                    .init(color: Color.clear, location: 0.4),
                                    .init(color: Color.black.opacity(0.7), location: 0.8),
                                    .init(color: Color.black.opacity(0.9), location: 1.0)
                                ]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                }
            }
            
            VStack {
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.white)
                            .background(
                                Circle()
                                    .fill(Color.gray.opacity(0.5))
                                    .frame(width: 30, height: 30)
                            )
                    }
                    Spacer()
                }
                .padding(40)
                .padding(.top, 15)
                Spacer()
            }
            
            Text("Top Restaurants: \(title)")
                .font(.custom("MuseoSansRounded-300", size: 20))
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .padding([.horizontal, .bottom])
        }
        .frame(height: 200)
    }
    
    private var timePeriodPicker: some View {
        HStack(spacing: 10) {
            Spacer()
            Button(action: { switchTimePeriod(.month) }) {
                Text("Month")
                    .font(.custom("MuseoSansRounded-500", size: 18))
                    .foregroundColor(viewModel.timePeriod == .month ? Color("Colors/AccentColor") : .gray)
                    .padding(.bottom, 5)
                    .overlay(
                        Rectangle()
                            .frame(height: 2)
                            .foregroundColor(viewModel.timePeriod == .month ? Color("Colors/AccentColor") : .clear)
                            .offset(y: 12)
                    )
            }
            .disabled(viewModel.timePeriod == .month || !canSwitchTab)
            
            Button(action: { switchTimePeriod(.week) }) {
                Text("Week")
                    .font(.custom("MuseoSansRounded-500", size: 18))
                    .foregroundColor(viewModel.timePeriod == .week ? Color("Colors/AccentColor") : .gray)
                    .padding(.bottom, 5)
                    .overlay(
                        Rectangle()
                            .frame(height: 2)
                            .foregroundColor(viewModel.timePeriod == .week ? Color("Colors/AccentColor") : .clear)
                            .offset(y: 12)
                    )
            }
            .disabled(viewModel.timePeriod == .week || !canSwitchTab)
            Spacer()
        }
        .padding(.vertical)
    }
    
    private var loadingView: some View {
        FastCrossfadeFoodImageView()
    }
    
    private var restaurantList: some View {
        ForEach(Array(topRestaurants.enumerated()), id: \.element.id) { index, restaurant in
            Button(action: { selectedRestaurant = restaurant }) {
                HStack(spacing: 8) {
                    Text("\(index + 1).")
                        .font(.custom("MuseoSansRounded-700", size: 16))
                        .foregroundColor(.black)
                        .frame(width: 30)
                    
                    RestaurantCircularProfileImageView(imageUrl: restaurant.profileImageUrl ?? "", size: .medium)
                    
                    VStack(alignment: .leading) {
                        Text(restaurant.name)
                            .lineLimit(1)
                            .font(.custom("MuseoSansRounded-700", size: 14))
                            .foregroundColor(.black)
                        
                        Text("\(restaurant.city ?? ""), \(restaurant.state ?? "")")
                            .lineLimit(1)
                            .font(.custom("MuseoSansRounded-300", size: 12))
                            .foregroundColor(.gray)
                        
                        Text("Posts: \(restaurant.stats?.postCount ?? 0)")
                            .font(.custom("MuseoSansRounded-300", size: 12))
                            .foregroundColor(.gray)
                        
                        if let rating = calculateOverallRating(for: restaurant) {
                            Text("Rating: \(rating, specifier: "%.1f")")
                                .font(.custom("MuseoSansRounded-300", size: 12))
                                .foregroundColor(.gray)
                        }
                    }
                    
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }
        }
    }
    
    private func switchTimePeriod(_ period: TimePeriod) {
        guard canSwitchTab else { return }
        withAnimation(.easeInOut(duration: 0.5)) {
            viewModel.timePeriod = period
        }
        canSwitchTab = false
        fetchRestaurants()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            canSwitchTab = true
        }
    }
    
    private func fetchRestaurants() {
        isLoading = true
        Task {
            do {
                topRestaurants = try await viewModel.fetchTopRestaurants(count: 10, state: state, city: city)
                isLoading = false
            } catch {
                print("Error fetching restaurants: \(error.localizedDescription)")
                isLoading = false
            }
        }
    }
    
    private func calculateOverallRating(for restaurant: Restaurant) -> Double? {
        guard let ratingStats = restaurant.ratingStats else { return nil }
        let categories = [ratingStats.overall, ratingStats.service, ratingStats.atmosphere, ratingStats.value, ratingStats.food]
        let validCategories = categories.compactMap { $0 }
        guard !validCategories.isEmpty else { return nil }
        
        let totalSum = validCategories.reduce(0.0) { $0 + ($1.sum ?? 0) }
        let totalCount = validCategories.reduce(0) { $0 + ($1.totalCount ?? 0) }
        
        return totalCount > 0 ? totalSum / Double(totalCount) : nil
    }
}


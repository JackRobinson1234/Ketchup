//
//  RestaurantLeaderboard.swift
//  Ketchup
//
//  Created by Jack Robinson on 9/9/24.
//

import SwiftUI

struct RestaurantLeaderboard: View {
    @ObservedObject var viewModel: LeaderboardViewModel
    @State private var selectedRestaurant: Restaurant?
    @Environment(\.dismiss) var dismiss
    @State private var canSwitchTab = true
    
    var topImage: String?
    var title: String
    var state: String?
    var city: String?
    var surrounding: String? = nil

    var body: some View {
        NavigationStack {
            VStack {
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(alignment: .leading, spacing: 4) {
                        headerSection
                        
                        if viewModel.isLoading && viewModel.restaurants.isEmpty {
                            HStack{
                                Spacer()
                                
                                loadingView
                                Spacer()
                            }
                        } else {
                            restaurantList
                                .padding(.top)
                        }
                    }
                }
                .refreshable {
                    await refreshRestaurants()
                }
            }
            .edgesIgnoringSafeArea(.top)
            .navigationDestination(for: Restaurant.self) { restaurant in
                RestaurantProfileView(restaurantId: restaurant.id)
            }
        }
        .onAppear {
            Task {
                await refreshRestaurants()
            }
        }
    }
    
    private var headerSection: some View {
        ZStack(alignment: .bottomLeading) {
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
    
    private var timePeriodSelector: some View {
        HStack(spacing: 10) {
            Spacer()
            Button {
                switchTimePeriod(.month)
            } label: {
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
            
            Button {
                switchTimePeriod(.week)
            } label: {
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
    
    private var dateRangeView: some View {
        HStack {
            Spacer()
            if viewModel.timePeriod == .week {
                Text(getDateRangeForCurrentWeek())
                    .font(.custom("MuseoSansRounded-500", size: 14))
                    .foregroundStyle(.black)
            } else {
                Text(getCurrentMonth())
                    .font(.custom("MuseoSansRounded-500", size: 14))
                    .foregroundStyle(.black)
            }
            Spacer()
        }
    }
    
    private var loadingView: some View {
        FastCrossfadeFoodImageView()
    }
    
    private var restaurantList: some View {
        ForEach(Array(viewModel.restaurants.enumerated()), id: \.element.id) { index, restaurant in
            NavigationLink(destination: RestaurantProfileView(restaurantId: restaurant.id)) {
                HStack(spacing: 8) {
                    Text("\(index + 1).")
                        .font(.custom("MuseoSansRounded-700", size: 16))
                        .foregroundColor(.black)
                        .frame(width: 30)
                    RestaurantCircularProfileImageView(imageUrl: restaurant.profileImageUrl ?? "", size: .large)
                    VStack(alignment: .leading) {
                        Text(restaurant.name)
                            .lineLimit(1)
                            .font(.custom("MuseoSansRounded-700", size: 14))
                            .foregroundColor(.black)
                        Text("\(restaurant.city ?? ""), \(restaurant.state ?? "")")
                            .lineLimit(1)
                            .font(.custom("MuseoSansRounded-300", size: 12))
                            .foregroundColor(.gray)
                        Text("\(combineRestaurantDetails(restaurant:restaurant))")
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
            .onAppear {
                if restaurant == viewModel.restaurants.last {
                    Task {
                        try? await viewModel.fetchMoreRestaurants(state: state, city: city, geohash: surrounding)
                    }
                }
            }
        }
    }
    
    private func switchTimePeriod(_ period: TimePeriod) {
        guard canSwitchTab else { return }
        withAnimation(.easeInOut(duration: 0.5)) {
            viewModel.timePeriod = period
        }
        canSwitchTab = false
        Task {
            await refreshRestaurants()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            canSwitchTab = true
        }
    }
    
    private func refreshRestaurants() async {
        viewModel.resetPagination()
        try? await viewModel.fetchMoreRestaurants(state: state, city: city, geohash: surrounding)
    }
    
    private func calculateOverallRating(for restaurant: Restaurant) -> Double? {
        guard let ratingStats = restaurant.ratingStats else { return nil }
        let categories = [ratingStats.overall, ratingStats.service, ratingStats.atmosphere, ratingStats.value, ratingStats.food]
        let validCategories = categories.compactMap { $0 }
        guard !validCategories.isEmpty else { return nil }
        
        var weightedSum = 0.0
        var totalCount = 0
        
        for category in validCategories {
            if let average = category.average, let count = category.totalCount {
                weightedSum += average * Double(count)
                totalCount += count
            }
        }
        
        return totalCount > 0 ? (weightedSum / Double(totalCount)).rounded(to: 1) : nil
    }
    private func combineRestaurantDetails(restaurant: Restaurant) -> String {
        var details = [String]()
        
        if let cuisine = restaurant.categoryName {
            details.append(cuisine)
        }
        if let price = restaurant.price {
            details.append(price)
        }
        
        return details.joined(separator: ", ")
    }
    private func getCurrentMonth() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM yyyy"
        return dateFormatter.string(from: Date())
    }
    
    private func getDateRangeForCurrentWeek() -> String {
        let calendar = Calendar.current
        let today = Date()
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today))!
        let endOfWeek = calendar.date(byAdding: .day, value: 6, to: startOfWeek)!
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM/dd"
        let startString = dateFormatter.string(from: startOfWeek)
        let endString = dateFormatter.string(from: endOfWeek)
        return "\(startString)-\(endString)"
    }
}

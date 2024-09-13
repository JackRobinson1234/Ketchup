//
//  RestaurantLeaderboard.swift
//  Ketchup
//
//  Created by Jack Robinson on 9/9/24.
//

import SwiftUI
enum listSection {
    case list, map
}
struct RestaurantLeaderboard: View {
    @ObservedObject var viewModel: LeaderboardViewModel
    @State private var selectedRestaurant: Restaurant?
    @Environment(\.dismiss) var dismiss
    @State private var canSwitchTab = true
    @State var restaurants: [Restaurant] = []
    var topImage: String?
    var title: String
    var state: String?
    var city: String?
    var surrounding: String?
    var leaderboardType: RestaurantLeaderboardType
    var selectedLocation: ActivityView.LocationType
    enum RestaurantLeaderboardType {
        case mostPosts
        case highestRated(LeaderboardViewModel.RatingCategory)
    }
    @State var currentSection: listSection = .list

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 0) {
                        Color.clear.frame(height: 200) // Space for sticky header
                        
                        LazyVStack(alignment: .leading, spacing: 4) {
                            if viewModel.isLoading && restaurants.isEmpty {
                                Spacer()
                                HStack {
                                    Spacer()
                                    loadingView
                                    Spacer()
                                }
                                Spacer()
                            } else {
                                toggleButtons
                                if currentSection == .list {
                                    restaurantList
                                        .padding(.top)
                                } else {
                                    
                                }
                            }
                        }
                    }
                    .refreshable {
                        await refreshRestaurants()
                    }
                }
                
                // Sticky header section
                headerSection
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
            
            Text(headerTitle)
                .font(.custom("MuseoSansRounded-300", size: 20))
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .padding([.horizontal, .bottom])
        }
        .frame(height: 200)
        .background(Color.black.opacity(0.5)) // Optional background
    }
    private var toggleButtons: some View {
        HStack(spacing: 0) {
            Image(systemName: currentSection == .list ? "list.bullet" : "list.bullet")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 50, height: 20)
                .onTapGesture {
                    withAnimation {
                        self.currentSection = .list
                    }
                }
                .modifier(UnderlineImageModifier(isSelected: currentSection == .list))
                .frame(maxWidth: .infinity)
            
            Image(systemName: currentSection == .map ? "location.fill" : "location")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 50, height: 22)
                .onTapGesture {
                    withAnimation {
                        self.currentSection = .map
                    }
                }
                .modifier(UnderlineImageModifier(isSelected: currentSection == .map))
                .frame(maxWidth: .infinity)
        }
        .padding()
    }
    private var headerTitle: String {
        switch leaderboardType {
        case .mostPosts:
            return "Most Posted Restaurants: \(title)"
        case .highestRated(let category):
            return "Top 20 \(category.rawValue.capitalized): \(title)"
        }
    }
    
    private var loadingView: some View {
        FastCrossfadeFoodImageView()
    }
    private var restaurantList: some View {
        ForEach(Array(restaurants.enumerated()), id: \.element.id) { index, restaurant in
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
                        Text("\(combineRestaurantDetails(restaurant: restaurant))")
                            .font(.custom("MuseoSansRounded-300", size: 12))
                            .foregroundColor(.gray)
                        Text("Posts: \(restaurant.stats?.postCount ?? 0)")
                            .font(.custom("MuseoSansRounded-300", size: 12))
                            .foregroundColor(.gray)
                        if let rating = getRatingForDisplay(restaurant) {
                            Text("\(getRatingDescription()) Rating: \(rating, specifier: "%.1f")")
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
        Task {
            await refreshRestaurants()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            canSwitchTab = true
        }
    }
    
    private func refreshRestaurants() async {
        viewModel.resetPagination()
        await fetchMoreRestaurants()
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
    private func fetchMoreRestaurants() async {
        do {
            let locationFilter: LeaderboardViewModel.LocationFilter
            switch selectedLocation {
            case .usa:
                locationFilter = .anywhere
            case .city:
                locationFilter = .city(city ?? "")
            case .surrounding:
                locationFilter = .geohash(surrounding ?? "")
            }
            print("LEADERBOARD LOCATION FILTER", locationFilter)
            switch leaderboardType {
            case .mostPosts:
                self.restaurants = try await viewModel.fetchTopRestaurants(count: 20, locationFilter: locationFilter)
            case .highestRated(let category):
                self.restaurants = try await viewModel.fetchHighestRatedRestaurants(category: category, count: 20, locationFilter: locationFilter)
            }
        } catch {
            print("Error fetching more restaurants: \(error.localizedDescription)")
        }
    }
    private func getRatingDescription() -> String {
           switch leaderboardType {
           case .mostPosts:
               return "Overall"
           case .highestRated(let category):
               return category.rawValue.capitalized
           }
       }
    private func getRatingForDisplay(_ restaurant: Restaurant) -> Double? {
        switch leaderboardType {
        case .mostPosts:
            return restaurant.overallRating?.average
        case .highestRated(let category):
            switch category {
            case .overall:
                return restaurant.overallRating?.average
            case .food:
                return restaurant.ratingStats?.food?.average
            case .atmosphere:
                return restaurant.ratingStats?.atmosphere?.average
            case .value:
                return restaurant.ratingStats?.value?.average
            case .service:
                return restaurant.ratingStats?.service?.average
            }
        }
    }
}

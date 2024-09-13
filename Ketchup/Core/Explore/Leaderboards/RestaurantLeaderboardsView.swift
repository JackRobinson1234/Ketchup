//
//  RestaurantLeaderboardListView.swift
//  Ketchup
//
//  Created by Jack Robinson on 9/12/24.
//

import SwiftUI
struct RestaurantLeaderboardsView: View {
    @ObservedObject var viewModel: LeaderboardViewModel
    @Binding var leaderboardData: [ActivityView.LeaderboardCategory: [ActivityView.LocationType: Any]]
    @Binding var selectedLeaderboard: (category: ActivityView.LeaderboardCategory?, location: ActivityView.LocationType?)?


    
    var city: String?
    var state: String?
    var surroundingGeohash: String?
    var surroundingCounty: String
    
    private let categories: [ActivityView.LeaderboardCategory] = [
        .mostPosts, .highestOverallRated, .highestFoodRated,
        .highestAtmosphereRated, .highestValueRated, .highestServiceRated
    ]
    
    var body: some View {
        VStack(alignment: .leading) {
            ForEach(categories, id: \.self) { category in
                leaderboardSection(for: category)
            }
        }
    }
    
    private func leaderboardSection(for category: ActivityView.LeaderboardCategory) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            sectionTitle(category.rawValue)
                .padding(.horizontal)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 20){
                    ForEach(ActivityView.LocationType.allCases) { locationType in
                        if let data = leaderboardData[category]?[locationType] {
                            leaderboardButton(for: category, locationType: locationType, data: data)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    private func leaderboardButton(for category: ActivityView.LeaderboardCategory, locationType: ActivityView.LocationType, data: Any) -> some View {
        Button {
            selectedLeaderboard = (category: category, location: locationType)
            
        } label: {
            LeaderboardCover(
                imageUrl: imageUrlForLeaderboard(category: category, locationType: locationType, data: data),
                title: titleForLeaderboard(category: category),
                subtitle: subtitleForLeaderboard(locationType: locationType)
            )
        }
    }
    
    private func imageUrlForLeaderboard(category: ActivityView.LeaderboardCategory, locationType: ActivityView.LocationType, data: Any) -> String? {
        return (data as? [Restaurant])?.first?.profileImageUrl
    }
    
    private func titleForLeaderboard(category: ActivityView.LeaderboardCategory) -> String {
        switch category {
        case .mostPosts:
            return "Most Posts"
        case .highestOverallRated:
            return "Best Overall"
        case .highestFoodRated:
            return "Best Food"
        case .highestAtmosphereRated:
            return "Best Atmosphere"
        case .highestValueRated:
            return "Best Value"
        case .highestServiceRated:
            return "Best Service"
        default:
            return ""
        }
    }
    
    private func subtitleForLeaderboard(locationType: ActivityView.LocationType) -> String {
        switch locationType {
        case .city:
            return city ?? "City"
        case .surrounding:
            return surroundingCounty
        case .usa:
            return "USA"
        }
    }
    
    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.custom("MuseoSansRounded-700", size: 25))
            .foregroundColor(.black)
    }
    
    func fetchLeaderboardData(for category: ActivityView.LeaderboardCategory, locationType: ActivityView.LocationType) async {
        do {
            let locationFilter: LeaderboardViewModel.LocationFilter
            switch locationType {
            case .usa:
                locationFilter = .anywhere
            case .city:
                locationFilter = .city(city ?? "")
            case .surrounding:
                locationFilter = .geohash(surroundingGeohash ?? "")
            }

            let data: Any
            switch category {
            case .mostPosts:
                data = try await viewModel.fetchTopRestaurants(count: 20, locationFilter: locationFilter)
            case .highestOverallRated:
                data = try await viewModel.fetchHighestRatedRestaurants(category: .overall, count: 20, locationFilter: locationFilter)
            case .highestFoodRated:
                data = try await viewModel.fetchHighestRatedRestaurants(category: .food, count: 20, locationFilter: locationFilter)
            case .highestAtmosphereRated:
                data = try await viewModel.fetchHighestRatedRestaurants(category: .atmosphere, count: 20, locationFilter: locationFilter)
            case .highestValueRated:
                data = try await viewModel.fetchHighestRatedRestaurants(category: .value, count: 20, locationFilter: locationFilter)
            case .highestServiceRated:
                data = try await viewModel.fetchHighestRatedRestaurants(category: .service, count: 20, locationFilter: locationFilter)
            default:
                return
            }
            
            if (data as? [Any])?.isEmpty == false {
                if leaderboardData[category] == nil {
                    leaderboardData[category] = [:]
                }
                leaderboardData[category]?[locationType] = data
            }
        } catch {
            print("Error fetching data for \(category) - \(locationType): \(error.localizedDescription)")
        }
    }
}

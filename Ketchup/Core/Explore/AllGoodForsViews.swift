//
//  AllGoodForsViews.swift
//  Ketchup
//
//  Created by Jack Robinson on 10/28/24.
//

import SwiftUI
import CoreLocation

struct AllGoodForsView: View {
    let groupedRestaurantsByGoodFor: [String: [Restaurant]]
    @ObservedObject var locationViewModel: LocationViewModel
    @Binding var showAllGoodFors: Bool
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Loop through each category
                    ForEach(goodForOptions.keys.sorted(), id: \.self) { category in
                        // Filter tags that have restaurants
                        let tagsInCategory = goodForOptions[category]?.filter { tag in
                            groupedRestaurantsByGoodFor[tag]?.isEmpty == false
                        } ?? []

                        // Only show the category if there are tags with restaurants
                        if !tagsInCategory.isEmpty {
                            VStack(alignment: .leading, spacing: 10) {
                                // Category Title
                                Text(category)
                                    .font(.title2)
                                    .bold()
                                    .padding(.horizontal)

                                // Tags under the category
                                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                                    ForEach(tagsInCategory, id: \.self) { tag in
                                        if let restaurants = groupedRestaurantsByGoodFor[tag], !restaurants.isEmpty {
                                            NavigationLink(destination: GoodForRestaurantsView(
                                                goodForTag: tag,
                                                restaurants: restaurants,
                                                locationViewModel: locationViewModel
                                            )) {
                                                ExploreCell(
                                                    imageUrl: restaurants.first?.profileImageUrl ?? "",
                                                    cuisineName: tag
                                                )
                                            }
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                }
                .padding(.top)
            }
            .navigationTitle("Restaurants for an Occasion")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        showAllGoodFors = false
                    }
                }
            }
        }
    }
}
struct GoodForTagsView: View {
    let category: String
    let tags: [String]
    let groupedRestaurantsByGoodFor: [String: [Restaurant]]
    @ObservedObject var locationViewModel: LocationViewModel

    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 10)], spacing: 10) {
                ForEach(tags, id: \.self) { tag in
                    if let restaurants = groupedRestaurantsByGoodFor[tag], !restaurants.isEmpty {
                        NavigationLink(destination: GoodForRestaurantsView(
                            goodForTag: tag,
                            restaurants: restaurants,
                            locationViewModel: locationViewModel
                        )) {
                            ExploreCell(
                                imageUrl: restaurants.first?.profileImageUrl ?? "",
                                cuisineName: tag
                            )
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
        .navigationTitle(category)
        .navigationBarTitleDisplayMode(.inline)
    }
}
struct GoodForRestaurantsView: View {
    let goodForTag: String
    let restaurants: [Restaurant]
    @ObservedObject var locationViewModel: LocationViewModel

    @State private var sortOption: SortOption = .distance

    private let columns: [GridItem] = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]

    private enum SortOption: String, CaseIterable {
        case distance = "Distance"
        case rating = "Rating"
        case popularity = "Popularity"
    }

    private var sortedRestaurants: [Restaurant] {
        switch sortOption {
        case .distance:
            guard let userLocation = locationViewModel.selectedLocationCoordinate else {
                return restaurants
            }
            let userCLLocation = CLLocation(latitude: userLocation.latitude, longitude: userLocation.longitude)
            return restaurants.sorted {
                ($0.distance(from: userCLLocation) ?? Double.infinity) < ($1.distance(from: userCLLocation) ?? Double.infinity)
            }
        case .rating:
            return restaurants.sorted {
                ($1.overallRating?.average ?? 0.0) < ($0.overallRating?.average ?? 0.0)
            }
        case .popularity:
            return restaurants.sorted {
                ($1.goodFor?[goodForTag] ?? 0) < ($0.goodFor?[goodForTag] ?? 0)
            }
        }
    }

    var body: some View {
        VStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(sortedRestaurants, id: \.id) { restaurant in
                        let userLocation = locationViewModel.selectedLocationCoordinate.map {
                            CLLocation(latitude: $0.latitude, longitude: $0.longitude)
                        }
                        NavigationLink(destination: RestaurantProfileView(restaurantId: restaurant.id)) {
                            RestaurantCardView(userLocation: userLocation, restaurant: restaurant)
                        }
                    }
                }
                .padding()
            }
        }
        .navigationTitle(goodForTag)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Picker("Sort By", selection: $sortOption) {
                        ForEach(SortOption.allCases, id: \.self) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                } label: {
                    VStack {
                        Image(systemName: "arrow.up.arrow.down")
                            .foregroundColor(Color("Colors/AccentColor"))
                        Text("Sort")
                            .font(.custom("MuseoSansRounded-500", size: 11))
                            .foregroundColor(Color("Colors/AccentColor"))
                    }
                }
            }
        }
    }
}

//
//  ClusterRestaurantListView.swift
//  Ketchup
//
//  Created by Jack Robinson on 7/2/24.
//

import SwiftUI

struct ClusterRestaurantListView: View {
    let restaurants: [ClusterRestaurant]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            List(restaurants, id: \.id) { restaurant in
                NavigationLink(destination: RestaurantProfileView(restaurantId: restaurant.id)) {
                    RestaurantRowView(restaurant: restaurant)
                }
                .listRowBackground(Color.clear) // Ensures the row has no background
            }
            .listStyle(PlainListStyle()) // Removes default styling from the List
            .background(Color.clear) // Makes sure the List's background is clear
            .navigationTitle("Restaurants")
            .navigationBarItems(trailing: Button("Close") {
                dismiss()
            })
        }
        .background(Color.clear) // Ensures the NavigationView's background is clear
    }
}

struct RestaurantRowView: View {
    let restaurant: ClusterRestaurant

    var body: some View {
        HStack {
            RestaurantCircularProfileImageView(imageUrl: restaurant.profileImageUrl, size: .medium)
            VStack(alignment: .leading) {
                Text(restaurant.name)
                    .font(.custom("MuseoSansRounded-500", size: 18))
                    .foregroundColor(.primary) // Default to primary text color
                Text(restaurant.cuisine ?? "")
                    .font(.custom("MuseoSansRounded-300", size: 14))
                    .foregroundColor(.secondary) // Default to secondary text color
                if let price = restaurant.price {
                    Text(price)
                        .font(.custom("MuseoSansRounded-300", size: 14))
                        .foregroundColor(.secondary) // Default to secondary text color
                }
            }
        }
        .background(Color.clear) // Ensures the row has no background color
    }
}

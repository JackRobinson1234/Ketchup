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
            }
            .navigationTitle("Clustered Restaurants")
            .navigationBarItems(trailing: Button("Close") {
                dismiss()
            })
        }
    }
}

struct RestaurantRowView: View {
    let restaurant: ClusterRestaurant

    var body: some View {
        HStack {
            RestaurantCircularProfileImageView(imageUrl: restaurant.profileImageUrl, size: .medium)
            VStack(alignment: .leading) {
                Text(restaurant.name)
                    .font(.headline)
                    .font(.custom("MuseoSansRounded-300", size: 18))
                Text(restaurant.cuisine ?? "")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .font(.custom("MuseoSansRounded-300", size: 14))
                if let price = restaurant.price {
                    Text(price)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .font(.custom("MuseoSansRounded-300", size: 14))
                }
            }
        }
    }
}

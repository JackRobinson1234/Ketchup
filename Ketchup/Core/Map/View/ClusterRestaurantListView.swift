//
//  ClusterRestaurantListView.swift
//  Ketchup
//
//  Created by Jack Robinson on 7/2/24.
//

import SwiftUI

struct ClusterRestaurantListView: View {
    let restaurants: [Restaurant]
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
    let restaurant: Restaurant

    var body: some View {
        HStack {
            RestaurantCircularProfileImageView(imageUrl: restaurant.profileImageUrl, size: .small)
            VStack(alignment: .leading) {
                Text(restaurant.name)
                    .font(.headline)
                Text(restaurant.cuisine ?? "")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
        }
    }
}

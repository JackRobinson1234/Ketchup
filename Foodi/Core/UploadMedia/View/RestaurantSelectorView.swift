//
//  RestaurantSelectorView.swift
//  Foodi
//
//  Created by Jack Robinson on 2/5/24.
//

import SwiftUI

struct RestaurantSelectorView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                SearchView(userService: UserService(), searchConfig: .restaurants(restaurantListConfig: .restaurants))
            }
            .navigationDestination(for: Restaurant.self) { restaurant in
                RestaurantProfileView(restaurant: restaurant)}
        }
    }
}

#Preview {
    RestaurantSelectorView()
}

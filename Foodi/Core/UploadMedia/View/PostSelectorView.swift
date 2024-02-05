//
//  PostSelectorView.swift
//  Foodi
//
//  Created by Jack Robinson on 2/5/24.
//

import SwiftUI

struct PostSelectorView: View {
    private let restaurant: Restaurant
    init(restaurant: Restaurant) {
        self.restaurant = restaurant
    }
    var body: some View {
        VStack{
            SelectedRestaurantView(restaurant: restaurant)
        }
    }
}

#Preview {
    PostSelectorView(restaurant: DeveloperPreview.restaurants[0])
}

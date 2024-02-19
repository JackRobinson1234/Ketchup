//
//  SelectedRestaurantView.swift
//  Foodi
//
//  Created by Jack Robinson on 2/5/24.
//

import SwiftUI

import SwiftUI

import SwiftUI
import Kingfisher


struct SelectedRestaurantView: View {
    var restaurant: Restaurant
    var body: some View {
        VStack  {
            RestaurantCircularProfileImageView(imageUrl: restaurant.profileImageUrl, size: .large)
            Text(restaurant.name)
                .font(.title3)
                .bold()
            Text("\(restaurant.address ?? ""), \(restaurant.city ?? ""), \(restaurant.state ?? "")")
                .font(.caption)
        }
    }
}

#Preview {
    SelectedRestaurantView(restaurant: DeveloperPreview.restaurants[0])
}

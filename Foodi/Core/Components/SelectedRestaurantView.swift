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
            RestaurantCircularProfileImageView(size: .xLarge)
            Text(restaurant.name)
                .font(.title2)
                .bold()
            Text("\(restaurant.cuisine ?? ""), \(restaurant.price ?? "")")
            Text("\(restaurant.address ?? ""), \(restaurant.city ?? ""), \(restaurant.state ?? "")")
                .font(.subheadline)
        }
    }
}

#Preview {
    SelectedRestaurantView(restaurant: DeveloperPreview.restaurants[0])
}

//
//  RestaurantCell.swift
//  Foodi
//
//  Created by Jack Robinson on 2/1/24.
//

import SwiftUI

struct RestaurantCell: View {
    let restaurant: Restaurant
    
    init(restaurant: Restaurant) {
        self.restaurant = restaurant
    }
    
    var body: some View {
        HStack(spacing: 12) {
            RestaurantCircularProfileImageView(imageUrl: restaurant.profileImageUrl, size: .large)
            
            VStack(alignment: .leading) {
                Text(restaurant.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.leading)
                
                Text(restaurant.cuisine ?? "Unknown Cuisine")
                    .font(.footnote)
                    .multilineTextAlignment(.leading)
                
                let address = restaurant.address ?? "Unknown Address"
                let city = restaurant.city ?? "Unknown City"
                let state = restaurant.state ?? "Unknown State"
                
                Text("\(address) \(city), \(state)")
                    .font(.footnote)
                    .multilineTextAlignment(.leading)
            }
            .foregroundStyle(.black)
            
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundStyle(.black)
                .padding([.leading, .trailing])
        
        }
    }
}


#Preview {
    RestaurantCell(restaurant: DeveloperPreview.restaurants[0])
}

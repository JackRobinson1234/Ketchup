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
                    .font(.custom("MuseoSansRounded-300", size: 16))
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.leading)
                    .foregroundColor(.black)
                
                Text(restaurant.categoryName ?? "Unknown Cuisine")
                    .font(.custom("MuseoSansRounded-300", size: 10))
                    .multilineTextAlignment(.leading)
                    .foregroundColor(.black)
                
                let address = restaurant.address ?? "Unknown Address"
//                let city = restaurant.city ?? "Unknown City"
//                let state = restaurant.state ?? "Unknown State"
                
                Text("\(address)")
                //Text("\(address) \(city), \(state)")
                    .font(.custom("MuseoSansRounded-300", size: 10))
                    .multilineTextAlignment(.leading)
                    .foregroundColor(.black)
            }
            .foregroundStyle(.black)
            
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundStyle(.black)
                .padding([.leading, .trailing])
        
        }
    }
}

//
//#Preview {
//    RestaurantCell(restaurant: DeveloperPreview.restaurants[0])
//}

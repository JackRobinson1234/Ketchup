//
//  SimilarRestaurantCell.swift
//  Ketchup
//
//  Created by Jack Robinson on 10/8/24.
//

import SwiftUI
import Kingfisher
struct SimilarRestaurantCell: View {
    let restaurant: Restaurant
    
    var body: some View {
        NavigationLink(destination: RestaurantProfileView(restaurantId: restaurant.id)) {
            HStack(spacing: 12) {
                // Restaurant image
                if let imageURL = restaurant.profileImageUrl {
                    KFImage(URL(string: imageURL))
                        .resizable()
                        .scaledToFill()
                        .frame(width: 46, height: 46)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                } else {
                    Image(systemName: "fork.knife")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 30, height: 30)
                        .foregroundColor(.gray)
                        .frame(width: 56, height: 56)
                        .background(Color.gray.opacity(0.2))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
                
                // Restaurant details
                VStack(alignment: .leading, spacing: 2) {
                    Text(restaurant.name)
                        .font(.custom("MuseoSansRounded-300", size: 12))
                        .foregroundColor(.black)
                        .lineLimit(1)
                    
                    if let city = restaurant.city, let state = restaurant.state {
                        Text("\(city), \(state)")
                            .font(.custom("MuseoSansRounded-300", size: 10))
                        
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    
                    Text(combineRestaurantDetails(restaurant: restaurant))
                        .font(.custom("MuseoSansRounded-300", size: 10))
                        .foregroundColor(.gray)
                        .lineLimit(1)
                }
            }
            .padding(.horizontal, 16)
            .frame(height: 46)  // Increased height to accommodate the new line
            .contentShape(Rectangle())
        }
    }

    private func combineRestaurantDetails(restaurant: Restaurant) -> String {
        var details = [String]()
        
        if let cuisine = restaurant.categoryName {
            details.append(cuisine)
        }
        if let price = restaurant.price {
            details.append(price)
        }
        
        return details.joined(separator: " | ")
    }
}


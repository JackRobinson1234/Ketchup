//
//  FavoriteRestaurantsView.swift
//  Foodi
//
//  Created by Jack Robinson on 2/19/24.
//

import SwiftUI

struct FavoriteRestaurantsView: View {
    let user: User
    
    var body: some View {
        VStack{
            HStack{
                Text("Favorites")
                    .font(.caption)
            }
            HStack(alignment: .top, spacing: 10){
                Spacer()
                if let favorites = user.favorites {
                    ForEach(favorites) { favoriteRestaurant in
                        VStack {
                            ZStack(alignment: .bottom) {
                                if let imageUrl = favoriteRestaurant.restaurantProfileImageUrl {
                                    RestaurantCircularProfileImageView(imageUrl: imageUrl, size: .medium)
                                }
                            }
                            Text(favoriteRestaurant.name)
                                .font(.caption)
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                        }
                        Spacer()
                    }
                    ForEach(0..<(4 - favorites.count), id: \.self) { _ in RestaurantCircularProfileImageView( size: .medium)
                        Spacer()
                    }
                }
            }
            .padding(.horizontal)
        }
        
    }
}


#Preview {
    FavoriteRestaurantsView(user: DeveloperPreview.user)
}

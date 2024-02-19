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
        
        HStack(spacing: 15){
            if let favorites = user.favorites {
                ForEach(favorites) { favoriteRestaurant in
                    ZStack(alignment: .bottom) {
                        if let imageUrl = favoriteRestaurant.restaurantProfileImageUrl {
                            RestaurantCircularProfileImageView(imageUrl: imageUrl, size: .large)
                        }
                        
                    }
                }
            }
        }
    }
}


#Preview {
    FavoriteRestaurantsView(user: DeveloperPreview.user)
}

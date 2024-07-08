//
//  FavoriteRestaurantsView.swift
//  Foodi
//
//  Created by Jack Robinson on 2/19/24.
//

import SwiftUI

struct FavoriteRestaurantsView: View {
    let user: User
    let favorites: [FavoriteRestaurant]?
    @State private var showRestaurantProfile: Bool = false
    @State private var restaurantProfileId: String = ""
    
    var body: some View {
        HStack(alignment: .top, spacing: 8){
            if let favorites {
                ForEach(favorites) { favoriteRestaurant in
                    //NavigationLink(destination: RestaurantProfileView(restaurantId: favoriteRestaurant.id)) {
                    NavigationLink(value: favoriteRestaurant) {
                        VStack {
                            if let imageUrl = favoriteRestaurant.restaurantProfileImageUrl {
                                RestaurantCircularProfileImageView(imageUrl: imageUrl, /*color: Color("Colors/AccentColor"),*/ size: .large)
                            }
                            Text(favoriteRestaurant.name)
                                .font(.custom("MuseoSansRounded-500", size: 10))
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                                .foregroundStyle(.primary)
                            
                        }
                        
                        
                        
                        
                        
                    }
                    .disabled(favoriteRestaurant.name.isEmpty)
                    .frame(width:  UIScreen.main.bounds.width / 4 -     10, alignment: .center)
                }
            }
        }
    }
}






#Preview {
    FavoriteRestaurantsView(user: DeveloperPreview.user, favorites: DeveloperPreview.user.favorites)
}


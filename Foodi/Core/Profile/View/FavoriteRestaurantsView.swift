//
//  FavoriteRestaurantsView.swift
//  Foodi
//
//  Created by Jack Robinson on 2/19/24.
//

import SwiftUI

enum favoriteRestaurantViewEnum {
    case editProfile
    case profileView
}

struct FavoriteRestaurantsView: View {
    let user: User
    let favoriteRestaurantViewEnum: favoriteRestaurantViewEnum
    
    var body: some View {
            HStack(alignment: .top, spacing: 8){
                Spacer()
                if let favorites = user.favorites {
                    ForEach(favorites) { favoriteRestaurant in
                        HStack{
                            NavigationLink(destination: RestaurantProfileView(restaurant: DeveloperPreview.restaurants[0])) {
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
                            }
                        }
                    }
                
                        Spacer()
                    }
                    
                
                ForEach(0..<(4 - (user.favorites?.count ?? 0)), id: \.self) { _ in
                    if user.isCurrentUser {
                        ZStack(alignment: .bottom) {
                            RestaurantCircularProfileImageView( size: .medium)
                            Image(systemName: "plus.circle.fill")
                                .foregroundStyle(.pink)
                                .offset(y: 8)
                        }
                        Spacer()
                        
                    }
            
                     else {
                        RestaurantCircularProfileImageView( size: .medium)
                        Spacer()
                    }
                        
                }
            }
        .padding(.horizontal)
        }
    }



#Preview {
    FavoriteRestaurantsView(user: DeveloperPreview.user, favoriteRestaurantViewEnum: .profileView)
}

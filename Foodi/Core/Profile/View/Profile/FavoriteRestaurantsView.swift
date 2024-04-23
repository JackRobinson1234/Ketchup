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
                Spacer()
                if let favorites {
                    ForEach(favorites) { favoriteRestaurant in
                        HStack{
                            NavigationLink(destination: NavigationLazyView(RestaurantProfileView(restaurantId: favoriteRestaurant.id))) {VStack {
                                if let imageUrl = favoriteRestaurant.restaurantProfileImageUrl {
                                    RestaurantCircularProfileImageView(imageUrl: imageUrl, size: .medium)
                                }
                                Text(favoriteRestaurant.name)
                                    .font(.caption)
                                    .multilineTextAlignment(.center)
                                    .lineLimit(2)
                                    .foregroundStyle(.black)
                            }
                            
                            }
                            .disabled(favoriteRestaurant.id.isEmpty)
                            
                            Spacer()
                        }
                    }
                }
            }
            
            
            .padding(.horizontal)
            
        }
    }

                
                



#Preview {
    FavoriteRestaurantsView(user: DeveloperPreview.user, favorites: DeveloperPreview.user.favorites)
}


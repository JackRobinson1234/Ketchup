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
   
    
    
    
    var body: some View {
        NavigationStack{
            HStack(alignment: .top, spacing: 8){
                Spacer()
                if let favorites {
                    ForEach(favorites) { favoriteRestaurant in
                        HStack{
                            
                                Button{showRestaurantProfile.toggle()} label:{
                                    VStack {
                                        if let imageUrl = favoriteRestaurant.restaurantProfileImageUrl {
                                            RestaurantCircularProfileImageView(imageUrl: imageUrl, size: .medium)
                                        }
                                        Text(favoriteRestaurant.name)
                                            .font(.caption)
                                            .multilineTextAlignment(.center)
                                            .lineLimit(2)
                                    }
                                
                                .disabled(favoriteRestaurant.id.isEmpty)
                                
                            }
                            
                            
                            Spacer()
                        }
                        .fullScreenCover(isPresented: $showRestaurantProfile) {
                            NavigationStack{
                                RestaurantProfileView(restaurant: DeveloperPreview.restaurants[0])
                            }
                        }
                    }
                }
                
                
                /*
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
                 */
            }
            
            .padding(.horizontal)
            
        }
    }
}
                
                



#Preview {
    FavoriteRestaurantsView(user: DeveloperPreview.user, favorites: DeveloperPreview.user.favorites)
}


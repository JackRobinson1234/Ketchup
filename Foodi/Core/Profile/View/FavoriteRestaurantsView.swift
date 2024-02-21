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
    let restaurantService: RestaurantService = RestaurantService()
    @State private var fetchedRestaurant: Restaurant?
    @State private var isEditFavoritesShowing = false
    let favorites: [FavoriteRestaurant]?
    @State var oldSelection: FavoriteRestaurant?
    
    
    var body: some View {
        HStack(alignment: .top, spacing: 8){
            Spacer()
            if let favorites {
                ForEach(favorites) { favoriteRestaurant in
                    HStack{
                        /*Button{
                         Task {
                         do {
                         let fetchedRestaurant = try await restaurantService.fetchRestaurant(withId: favoriteRestaurant.id)
                         print("first: \(fetchedRestaurant)")
                         isDetailViewActive = true
                         print("second \(isDetailViewActive)")
                         } catch {
                         // Handle error if needed
                         print("Error fetching restaurant: \(error.localizedDescription)")
                         }
                         }
                         
                         } label: { */
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
                        /*}
                         .sheet(isPresented: $isDetailViewActive) {
                         if let unwrappedRestaurant = fetchedRestaurant{
                         RestaurantProfileView(restaurant: unwrappedRestaurant)
                         }
                         }*/
                    }
                    
                    
                    Spacer()
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
            
                
                


/*
#Preview {
    FavoriteRestaurantsView(user: DeveloperPreview.user, favoriteRestaurantViewEnum: .editProfile, favorites: DeveloperPreview.user.favorites)
}
*/

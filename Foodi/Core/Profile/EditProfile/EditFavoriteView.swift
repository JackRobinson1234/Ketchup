//
//  EditFavoritesView.swift
//  Foodi
//
//  Created by Jack Robinson on 2/20/24.
//
/*
import SwiftUI

struct EditFavoriteView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var user: User
    @Binding var oldSelection: FavoriteRestaurant
    @Binding var favoritesPreview: [FavoriteRestaurant]
    var body: some View {
        ScrollView {
            SearchView(userService: UserService(), searchConfig: .restaurants(restaurantListConfig: .upload), oldSection: $oldSelection, favoritesPreview: $favoritesPreview)
        }
        /*.navigationDestination(for: Restaurant.self) { restaurant in
         let name = restaurant.name
         let id = restaurant.id
         let restaurantProfileImageUrl = restaurant.profileImageUrl ?? ""
         let newSelection = FavoriteRestaurant(name: name, id: id, restaurantProfileImageUrl: restaurantProfileImageUrl)
         if let index = favoritesPreview.firstIndex(of: oldSelection) {
         let newFavoritesPreview = $favoritesPreview
         newFavoritesPreview[
         }
         EditProfileView(user: $user)
         }
         .navigationBarBackButtonHidden()
         .toolbar {
         ToolbarItem(placement: .topBarLeading) {
         Button {
         dismiss()
         } label: {
         Text("Cancel")
         }
         }
         }
         .toolbar(.hidden, for: .tabBar)
         }*/
    }
}

#Preview {
    EditFavoriteView(user: .constant(DeveloperPreview.user), oldSelection: .constant(FavoriteRestaurant(name: "hello", id: "hello", restaurantProfileImageUrl: nil)), favoritesPreview: .constant([]))
}
*/

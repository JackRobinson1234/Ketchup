//
//  RestaurantSelectorView.swift
//  Foodi
//
//  Created by Jack Robinson on 2/5/24.
//

import SwiftUI

struct RestaurantSelectorView: View {
    @Binding var tabIndex: Int
    @Binding var cover: Bool
    @Environment(\.dismiss) var dismiss
    init(tabIndex: Binding<Int>, cover: Binding<Bool>) {
        self._tabIndex = tabIndex
        self._cover = cover
    }
    
    var body: some View {
        NavigationStack{
            ScrollView {
                SearchView(userService: UserService(), searchConfig: .restaurants(restaurantListConfig: .upload))
            }
            .navigationDestination(for: Restaurant.self) { restaurant in
                MediaSelectorView(tabIndex: $tabIndex, restaurant: restaurant, cover: $cover)}
        }
        .navigationBarBackButtonHidden()
        .toolbar(.hidden, for: .tabBar)
        
    }
}


#Preview {
    RestaurantSelectorView(tabIndex: .constant(0), cover: .constant(true))
}

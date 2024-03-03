//
//  RestaurantSelectorView.swift
//  Foodi
//
//  Created by Jack Robinson on 2/5/24.
//

import SwiftUI

struct RestaurantSelectorView: View {
    @Binding var tabIndex: Int
    @Environment(\.dismiss) var dismiss
    init(tabIndex: Binding<Int>) {
        self._tabIndex = tabIndex
    }
    
    var body: some View {
        NavigationStack{
            ScrollView {
                SearchView(userService: UserService(), searchConfig: .restaurants(restaurantListConfig: .upload))
            }
            .navigationDestination(for: Restaurant.self) { restaurant in
                RestaurantMediaSelectorView(tabIndex: $tabIndex, restaurant: restaurant)}
        }
        .navigationBarBackButtonHidden()
        .toolbar(.hidden, for: .tabBar)
        
    }
}


#Preview {
    RestaurantSelectorView(tabIndex: .constant(0))
}

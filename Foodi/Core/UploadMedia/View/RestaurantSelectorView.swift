//
//  RestaurantSelectorView.swift
//  Foodi
//
//  Created by Jack Robinson on 2/5/24.
//

import SwiftUI

struct RestaurantSelectorView: View {
    @Binding var tabIndex: Int
    init(tabIndex: Binding<Int>) {
        self._tabIndex = tabIndex
    }
    var body: some View {
        NavigationStack{
            ScrollView {
                SearchView(userService: UserService(), searchConfig: .restaurants(restaurantListConfig: .upload))
            }
            .navigationDestination(for: Restaurant.self) { restaurant in
                MediaSelectorView(tabIndex: $tabIndex, restaurant: restaurant)}
            .navigationBarBackButtonHidden()
        }
    }
}


#Preview {
    RestaurantSelectorView(tabIndex: .constant(0))
}

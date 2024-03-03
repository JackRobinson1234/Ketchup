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
    private var postType: PostType
    
    init(tabIndex: Binding<Int>, cover: Binding<Bool>, postType: PostType) {
        self._tabIndex = tabIndex
        self._cover = cover
        self.postType = postType
    }
    
    var body: some View {
        NavigationStack{
            ScrollView {
                SearchView(userService: UserService(), searchConfig: .restaurants(restaurantListConfig: .upload))
            }
            .navigationDestination(for: Restaurant.self) { restaurant in
                MediaSelectorView(tabIndex: $tabIndex, restaurant: restaurant, cover: $cover, postType: postType)}
        }
        .navigationBarBackButtonHidden()
        .toolbar(.hidden, for: .tabBar)
        
    }
}

/*
#Preview {
    RestaurantSelectorView(tabIndex: .constant(0), cover: .constant(true), postType: .constant(.restaurant))
}
*/

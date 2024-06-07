//
//  AddItemSelector.swift
//  Foodi
//
//  Created by Jack Robinson on 4/15/24.
//

import SwiftUI

struct AddItemSelector: View {
    @ObservedObject var viewModel: ProfileCollectionsViewModel
    //@Binding var cover: Bool
    @Environment(\.dismiss) var dismiss
    
    
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


#Preview {
    AddItemSelector(tabIndex: .constant(0), cover: .constant(true), postType: .constant(.restaurant))
}

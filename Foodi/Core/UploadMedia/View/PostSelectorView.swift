//
//  PostSelectorView.swift
//  Foodi
//
//  Created by Jack Robinson on 2/5/24.
//

import SwiftUI

struct PostSelectorView: View {
    var body: some View {
        NavigationStack{
            VStack {
                NavigationLink(destination: RestaurantSelectorView()) {
                    CreatePostSelection()
                }
            }
        }
    }
}

#Preview {
    PostSelectorView()
}

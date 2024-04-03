//
//  PostTypeFilter.swift
//  Foodi
//
//  Created by Jack Robinson on 4/3/24.
//

import SwiftUI

struct PostTypeFilter: View {
    @State private var restaurantChecked: Bool = true
    @State private var brandChecked: Bool = true
    @State private var recipeChecked: Bool = true
    var body: some View {
        VStack(alignment: .leading) {
            HStack{
                VStack (alignment: .leading) {
                    Text("Filter by Post Type")
                        .font(.title2)
                        .fontWeight(.semibold)
                    Text("Select which types of posts will show in the feed")
                        .font(.caption)
                }
                Spacer()
            }
            Toggle("Restaurant Posts", isOn: $restaurantChecked)
            Toggle("Brand Posts", isOn: $brandChecked)
            Toggle("Recipe Posts", isOn: $recipeChecked)
        }
        .padding(.horizontal)
        .cornerRadius(8)
        .padding(.vertical, 8)
    }
}

#Preview {
    PostTypeFilter()
}

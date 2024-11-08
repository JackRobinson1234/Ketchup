//
//  SimplifiedPostClusterListView.swift
//  Ketchup
//
//  Created by Jack Robinson on 11/7/24.
//

import SwiftUI

struct SimplifiedPostClusterListView: View {
    let posts: [SimplifiedPost]
    
    var body: some View {
        NavigationView {
            List(posts) { post in
                NavigationLink(destination: RestaurantProfileView(restaurantId: post.restaurant.id)) {
                    HStack {
                        AsyncImage(url: URL(string: post.thumbnailUrl)) { image in
                            image.resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 50, height: 50)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        } placeholder: {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 50, height: 50)
                        }
                        
                        VStack(alignment: .leading) {
                            Text(post.restaurant.name)
                                .font(.headline)
                            Text(post.user.fullname)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Posts")
        }
    }
}

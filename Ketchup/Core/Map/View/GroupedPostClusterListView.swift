//
//  GroupedPostClusterListView.swift
//  Ketchup
//
//  Created by Jack Robinson on 11/7/24.
//

import SwiftUI

struct GroupedPostClusterListView: View {
    let groupedPosts: [GroupedPostMapAnnotation]
    
    var body: some View {
        NavigationView {
            List(groupedPosts) { groupedPost in
                NavigationLink(destination: RestaurantProfileView(restaurantId: groupedPost.restaurant.id)) {
                    HStack {
                        AsyncImage(url: URL(string: groupedPost.restaurant.profileImageUrl ?? "")) { image in
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
                            Text(groupedPost.restaurant.name)
                                .font(.headline)
                            Text("\(groupedPost.postCount) posts by \(groupedPost.userCount) users")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Restaurants")
        }
    }
}

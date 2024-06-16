//
//  PostListCell.swift
//  Foodi
//
//  Created by Jack Robinson on 4/22/24.
//

import SwiftUI
import Kingfisher

struct PostListCell: View {
    var post: Post
    var width: CGFloat =  70
    var body: some View {
        HStack(spacing: 12) {
            //MARK: Thumbnail Image
            KFImage(URL(string: post.thumbnailUrl))
                .resizable()
                .scaledToFill()
                .frame(width: width, height: 90)
                .clipped()
            
            //MARK: Restaurant Info
            if post.postType == .dining, let restaurant = post.restaurant{
                VStack(alignment: .leading) {
                    Text(restaurant.name)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                    Text("by \(post.user.fullname)")
                        .font(.caption)
                        .foregroundStyle(.primary)
                    if let cuisine = post.cuisine {
                        Text(cuisine)
                            .font(.footnote)
                            .foregroundStyle(.primary)
                    }
                    let city = restaurant.city ?? ""
                    let state = restaurant.state ?? ""
                    Text("\(city), \(state)")
                        .font(.footnote)
                        .foregroundStyle(.primary)
                }
                .foregroundStyle(.primary)
                
            }
            //MARK: Recipe Info
            else if post.postType == .cooking {
                VStack(alignment: .leading) {
                    if let recipe = post.cookingTitle {
                        Text(recipe)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                    Text("by \(post.user.fullname)")
                        .foregroundStyle(.primary)
                        .font(.caption)
                    if let cuisine = post.cuisine {
                        Text(cuisine)
                            .font(.footnote)
                            .foregroundStyle(.primary)
                    }
                }
            }
            Spacer()
            //MARK: Right Arrow
            Image(systemName: "chevron.right")
                .foregroundStyle(.primary)
                .padding([.leading, .trailing])
        }
    }
}
#Preview {
    PostListCell(post: DeveloperPreview.posts[0])
}

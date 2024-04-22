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
    var width: CGFloat =  50
    var body: some View {
        HStack(spacing: 12) {
            KFImage(URL(string: post.thumbnailUrl))
                .resizable()
                .scaledToFill()
                .frame(width: width, height: 75)
                .clipped()
            if post.postType == "restaurant", let restaurant = post.restaurant{
                VStack(alignment: .leading) {
                    Text(restaurant.name)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    if let cuisine = post.cuisine {
                        Text(cuisine)
                            .font(.footnote)
                    }
                    let address = restaurant.address ?? ""
                    let city = restaurant.city ?? ""
                    let state = restaurant.state ?? ""
                    
                    Text("\(address) \(city), \(state)")
                        .font(.footnote)
                    Text("by  \(post.user.fullName)")
                }
                .foregroundStyle(.black)
                
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundStyle(.black)
                    .padding([.leading, .trailing])
                
            }
        }
    }
}
#Preview {
    PostListCell(post: DeveloperPreview.posts[0])
}

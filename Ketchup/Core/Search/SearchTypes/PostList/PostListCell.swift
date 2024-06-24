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
            if let restaurant = post.restaurant{
                VStack(alignment: .leading) {
                    Text(restaurant.name)
                        .font(.custom("MuseoSansRounded-300", size: 16))
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                    Text("by \(post.user.fullname)")
                        .font(.custom("MuseoSansRounded-300", size: 10))
                        .foregroundStyle(.primary)
                    if let cuisine = restaurant.cuisine {
                        Text(cuisine)
                            .font(.custom("MuseoSansRounded-300", size: 10))
                            .foregroundStyle(.primary)
                    }
                    let city = restaurant.city ?? ""
                    let state = restaurant.state ?? ""
                    Text("\(city), \(state)")
                        .font(.custom("MuseoSansRounded-300", size: 10))
                        .foregroundStyle(.primary)
                }
                .foregroundStyle(.primary)
                
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

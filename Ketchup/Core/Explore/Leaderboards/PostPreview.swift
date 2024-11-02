//
//  PostPreview.swift
//  Ketchup
//
//  Created by Jack Robinson on 10/21/24.
//

import SwiftUI
import Kingfisher

struct PostPreview: View {
    let width: CGFloat = 150
    var post: Post

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .bottomLeading) {
                if !post.thumbnailUrl.isEmpty {
                    KFImage(URL(string: post.thumbnailUrl))
                        .resizable()
                        .scaledToFill()
                        .frame(width: width, height: 150)
                        .cornerRadius(8)
                        .clipped()
                } else if let image = post.restaurant.profileImageUrl, !image.isEmpty {
                    KFImage(URL(string: image))
                        .resizable()
                        .scaledToFill()
                        .frame(width: width, height: 200)
                        .cornerRadius(8)
                        .clipped()
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: width, height: 200)
                        .cornerRadius(8)
                }
                // Overlay restaurant name
                Text(post.restaurant.name)
                    .font(.custom("MuseoSansRounded-700", size: 16))
                    .foregroundColor(.white)
                    .padding([.leading, .bottom], 8)
                    .lineLimit(2)
                    .shadow(color: Color.black.opacity(0.5), radius: 2, x: 0, y: 0)
            }
            HStack(spacing: 8) {
                // User profile image
                if let userProfileUrl = post.user.profileImageUrl, !userProfileUrl.isEmpty {
                    KFImage(URL(string: userProfileUrl))
                        .resizable()
                        .scaledToFill()
                        .frame(width: 25, height: 25)
                        .clipShape(Circle())
                } else {
                    Circle()
                        .fill(Color.gray.opacity(0.5))
                        .frame(width: 40, height: 40)
                }

                VStack(alignment: .leading, spacing: 4) {
                    // Username
                    Text("@\(post.user.username)")
                        .font(.custom("MuseoSansRounded-500", size: 12))
                        .foregroundColor(.black)
                        .lineLimit(1)
                        .truncationMode(.tail)
                    // Rating
                    if let rating = post.overallRating {
                        ScrollFeedOverallRatingView(rating: rating, font: .black, size: 30)
                            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                    }
                }
                Spacer()
            }
            .padding([.leading, .trailing, .bottom], 8)
        }
        .frame(width: width)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
}

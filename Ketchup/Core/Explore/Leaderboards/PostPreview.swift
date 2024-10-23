//
//  PostPreview.swift
//  Ketchup
//
//  Created by Jack Robinson on 10/21/24.
//

import SwiftUI
import Kingfisher


struct PostPreview: View {

    var post: Post

    var body: some View {
        HStack(spacing: 12) {
            // Ranking number
           

            // Thumbnail Image
            if !post.thumbnailUrl.isEmpty {
                KFImage(URL(string: post.thumbnailUrl))
                    .resizable()
                    .scaledToFill()
                    .frame(width: 130, height: 130)
                    .cornerRadius(8)
                    .clipped()
            } else {
                // Placeholder image if thumbnail is missing
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 130, height: 130)
                    .cornerRadius(8)
            }

            VStack(spacing:6) {
                if let rating = post.overallRating {
                    ScrollFeedOverallRatingView(rating: rating, font: .black, size: 30)
                        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                }
//                HStack(spacing: 1) {
//                    Image(systemName: "heart")
//                        .font(.footnote)
//                        .foregroundColor(.gray)
//
//                    Text("\(post.likes)")
//                        .font(.custom("MuseoSansRounded-300", size: 10))
//                        .foregroundColor(.gray)
//                }
            }

            VStack(alignment: .leading, spacing: 0) {
                // Restaurant name
                Text(post.restaurant.name)
                    .font(.custom("MuseoSansRounded-700", size: 14))
                    .foregroundColor(.black)
                    .multilineTextAlignment(.leading)

                // City and state (new addition)
                if let city = post.restaurant.city, let state = post.restaurant.state {
                    Text("\(city), \(state)")
                        .font(.custom("MuseoSansRounded-500", size: 12))
                        .foregroundColor(.gray)
                }

                // Username
                Text("@\(post.user.username)")
                    .font(.custom("MuseoSansRounded-500", size: 12))
                    .foregroundColor(.gray)

                // Rating and caption
                Text(post.caption)
                    .font(.custom("MuseoSansRounded-300", size: 12))
                    .foregroundColor(.black)
                    .lineLimit(2)
                    .truncationMode(.tail)
                    .multilineTextAlignment(.leading)
                HStack{
                    Spacer()
                    Text("Go to feed >")
                        .font(.custom("MuseoSansRounded-700", size: 14))
                        .foregroundColor(.red)
                }
                
            }

            Spacer()
        }
        .background(Color.gray.opacity(0.1))
        .cornerRadius(6)
    }
}

//
//  WrittenFeedCell.swift
//  Ketchup
//
//  Created by Jack Robinson on 6/25/24.
//

import SwiftUI
import Kingfisher
    struct WrittenFeedCell: View {
        var post: Post

        var body: some View {
            VStack(alignment: .leading) {
                // Header with user info
                HStack {
                    if let profileImageUrl = post.user.profileImageUrl, let url = URL(string: profileImageUrl) {
                        KFImage(url)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 40, height: 40)
                            .clipShape(Circle())
                    } else {
                        Image(systemName: "person.crop.circle.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 40, height: 40)
                            .clipShape(Circle())
                    }
                    VStack(alignment: .leading) {
                        Text(post.user.username)
                            .font(.headline)
                        Text(post.user.fullname)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    Spacer()
                    Text("2d") // Example, replace with actual timestamp
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding([.leading, .trailing, .top])

                // Post image
                if let imageUrl = post.mediaUrls.first, let url = URL(string: imageUrl) {
                    KFImage(url)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(maxWidth: .infinity)
                        .clipped()
                }

                // Restaurant info
                if let restaurant = post.restaurant {
                    VStack(alignment: .leading) {
                        Text(restaurant.name)
                            .font(.headline)
                        Text("\(restaurant.city ?? ""), \(restaurant.state ?? "")")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .padding([.leading, .trailing])
                }

                // Ratings
                HStack {
                    if let overallRating = post.overallRating {
                        RatingView(rating: overallRating, label: "Overall")
                    }
                    if let serviceRating = post.serviceRating {
                        RatingView(rating: serviceRating, label: "Service")
                    }
                    if let atmosphereRating = post.atmosphereRating {
                        RatingView(rating: atmosphereRating, label: "Atmosphere")
                    }
                }
                .padding([.leading, .trailing])

                // Caption
                Text(post.caption)
                    .padding([.leading, .trailing, .top])

                // Interaction icons
                HStack {
                    InteractionButtonView(icon: "bubble.left", count: post.commentCount)
                    InteractionButtonView(icon: "arrow.2.squarepath", count: post.repostCount)
                    InteractionButtonView(icon: post.didLike ? "heart.fill" : "heart", count: post.likes, color: post.didLike ? .red : .primary)
                    InteractionButtonView(icon: "paperplane", count: 35) // Example share count
                    Spacer()
                }
                .padding([.leading, .trailing, .bottom])
            }
            .background(Color.white)
            .cornerRadius(10)
            .shadow(radius: 2)
            .padding([.leading, .trailing, .top])
        }
    }

struct RatingView: View {
    var rating: Rating
    var label: String?

    var body: some View {
        HStack {
            if let label{
                Text(label)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            ForEach(1...5, id: \.self) { index in
                Rating.image(forValue: index)
                    .resizable()
                    .frame(width: 20, height: 20) // Adjusted for better visibility
                    .foregroundColor(index <= rating.rawValue ? .yellow : .gray)
                    .underline(index == rating.rawValue, color: .black)
            }
        }
    }
}

    struct InteractionButtonView: View {
        var icon: String
        var count: Int
        var color: Color = .primary

        var body: some View {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text("\(count)")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding(.trailing, 10)
        }
    }

#Preview {
    WrittenFeedCell(post: DeveloperPreview.posts[0])
}

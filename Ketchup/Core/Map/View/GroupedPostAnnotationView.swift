//
//  GroupedPostAnnotationView.swift
//  Ketchup
//
//  Created by Jack Robinson on 11/7/24.
//

import SwiftUI

struct GroupedPostAnnotationView: View {
    let groupedPost: GroupedPostMapAnnotation
    
    private func calculateOverallRating(for post: SimplifiedPost) -> Double? {
        let ratings = [post.serviceRating, post.atmosphereRating, post.valueRating, post.foodRating]
        let validRatings = ratings.compactMap { $0 }
        guard !validRatings.isEmpty else { return nil }
        return validRatings.reduce(0, +) / Double(validRatings.count)
    }
    
    private var averageRating: String {
        let overallRatings = groupedPost.posts.compactMap { calculateOverallRating(for: $0) }
        guard !overallRatings.isEmpty else { return "N/A" }
        let average = overallRatings.reduce(0, +) / Double(overallRatings.count)
        return String(format: "%.1f", average)
    }
    
    var body: some View {
        VStack(spacing: 2) {
            ZStack {
                RestaurantCircularProfileImageView(imageUrl: groupedPost.restaurant.profileImageUrl, color: Color("Colors/AccentColor"), size: .medium)
                    .frame(width: 50, height: 50)
                
                VStack {
                    HStack {
                        Spacer()
                        Text(averageRating)
                            .font(.custom("MuseoSansRounded-700", size: 11))
                            .foregroundColor(.black)
                            .padding(2)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(.white)
                                    .shadow(color: Color.gray, radius: 1)
                            )
                    }
                    Spacer()
                }
                
                VStack {
                    Spacer()
                    HStack(spacing: 1) {
                        Image(systemName: "person.2")
                            .font(.system(size: 10))
                            .foregroundColor(.white)
                        Text("\(groupedPost.posts.count)")
                            .font(.custom("MuseoSansRounded-500", size: 10))
                            .foregroundColor(.white)
                    }
                    .padding(3)
                    .background(Color("Colors/AccentColor"))
                    .clipShape(Capsule())
                    .padding(.bottom, -8) // Shift it slightly lower
                }
            }
        }
        .padding(.bottom,5)
    }
}


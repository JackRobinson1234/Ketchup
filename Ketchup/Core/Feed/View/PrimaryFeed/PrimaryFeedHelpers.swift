//
//  PrimaryFeedHelpers.swift
//  Ketchup
//
//  Created by Jack Robinson on 7/30/24.
//

import SwiftUI

struct InteractionButtonView: View {
    var icon: String
    var count: Int?
    var color: Color = .gray
    var width: CGFloat?
    var height: CGFloat?
    
    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: icon)
                .resizable()
                .scaledToFit()
                .frame(width: width ?? 18, height: height ?? 18)
                .foregroundColor(color)
            if let count {
                Text("\(count)")
                    .font(.custom("MuseoSansRounded-300", size: 14))
                    .foregroundColor(.gray)
            }
        }
        .padding(.trailing, 10)
    }
}

struct RatingSlider: View {
    let rating: Double
    let label: String
    let isOverall: Bool
    let fontColor: Color
    
    var formattedRating: String {
        return String(format: "%.1f", rating)
    }
    
    var body: some View {
        HStack(alignment: .center, spacing: 5) {
            Text(label)
                .font(isOverall ? .custom("MuseoSansRounded-700", size: 16) : .custom("MuseoSansRounded-300", size: 16))
                .foregroundColor(fontColor)
                .frame(width: 90, alignment: .leading)
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 2)
                        .cornerRadius(1)
                    
                    Rectangle()
                        .fill(Color("Colors/AccentColor"))
                        .frame(width: (rating / 10.0) * geometry.size.width, height: 2)
                        .cornerRadius(1)
                }
                .frame(maxHeight: .infinity)
            }
            .frame(height: 20) // This sets a fixed height for the GeometryReader
            
            Text(formattedRating)
                .font(.custom("MuseoSansRounded-300", size: 14))
                .foregroundColor(fontColor)
                .frame(width: 40, alignment: .trailing)
        }
    }
}

struct RatingsView: View {
    let post: Post
    @Binding var isExpanded: Bool
    
    var overallRating: Double {
        let ratings = [post.foodRating, post.atmosphereRating, post.valueRating, post.serviceRating].compactMap { $0 }
        guard !ratings.isEmpty else { return 0 }
        return ratings.reduce(0, +) / Double(ratings.count)
    }
    
    var body: some View {
        VStack {
            if isExpanded {
                VStack(alignment: .leading, spacing: 10) {
                    if let foodRating = post.foodRating {
                        RatingSlider(rating: foodRating, label: "Food", isOverall: false, fontColor: .primary)
                    }
                    if let atmosphereRating = post.atmosphereRating {
                        RatingSlider(rating: atmosphereRating, label: "Atmosphere", isOverall: false, fontColor: .primary)
                    }
                    if let valueRating = post.valueRating {
                        RatingSlider(rating: valueRating, label: "Value", isOverall: false, fontColor: .primary)
                    }
                    if let serviceRating = post.serviceRating {
                        RatingSlider(rating: serviceRating, label: "Service", isOverall: false, fontColor: .primary)
                    }
                }
                .transition(.scale(scale: 0.9, anchor: .top).combined(with: .opacity))
            }
        }
    }
}

struct FeedOverallRatingView: View {
    let rating: Double?
    var font: Color? = .primary
    
    var body: some View {
        if let rating = rating {
            VStack(spacing: 4) {
                ZStack {
                    Circle()
                        .stroke(lineWidth: 3)
                        .opacity(0.3)
                        .foregroundColor(Color.gray)
                    
                    Circle()
                        .trim(from: 0.0, to: CGFloat(min(rating / 10, 1.0)))
                        .stroke(Color("Colors/AccentColor"), style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                        .rotationEffect(Angle(degrees: 270.0))
                        .animation(.linear, value: rating)
                    
                    Text(String(format: "%.1f", rating))
                        .font(.custom("MuseoSansRounded-500", size: 16))
                }
                .frame(width: 40, height: 40)
            }
        }
    }
}



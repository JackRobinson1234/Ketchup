//
//  OverallRatingView.swift
//  Ketchup
//
//  Created by Jack Robinson on 7/28/24.
//

import SwiftUI

struct ScrollFeedOverallRatingView: View {
    let rating: Double?
    var font: Color? = .black
    var size: CGFloat = 40 // Default size
    
    var body: some View {
        if let rating = rating {
            VStack(spacing: 4) {
                ZStack {
                    Circle()
                        .stroke(lineWidth: size / 13.3) // Adjust stroke width relative to size
                        .opacity(0.3)
                        .foregroundColor(Color.gray)
                    
                    Circle()
                        .trim(from: 0.0, to: CGFloat(min(rating / 10, 1.0)))
                        .stroke(Color("Colors/AccentColor"), style: StrokeStyle(lineWidth: size / 13.3, lineCap: .round, lineJoin: .round)) // Adjust stroke width relative to size
                        .rotationEffect(Angle(degrees: 270.0))
                        .animation(.linear, value: rating)
                    
                    Text(String(format: "%.1f", rating))
                        .font(.custom("MuseoSansRounded-500", size: size / 2.2)) // Adjust font size relative to size
                        .foregroundColor(font)
                }
                .frame(width: size, height: size) // Use the provided or default size
            }
        }
    }
}

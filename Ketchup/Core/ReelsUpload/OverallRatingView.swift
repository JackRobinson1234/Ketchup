//
//  OverallRatingView.swift
//  Ketchup
//
//  Created by Jack Robinson on 7/9/24.
//

import SwiftUI

struct OverallRatingView: View {
    let rating: Double
    
    var body: some View {
        VStack(spacing: 8) { // Add spacing to create space between circle and "Overall" text
            ZStack {
                Circle()
                    .stroke(lineWidth: 6) // Thinner line
                    .opacity(0.3)
                    .foregroundColor(Color.gray)
                
                Circle()
                    .trim(from: 0.0, to: CGFloat(min(rating / 10, 1.0)))
                    .stroke(Color("Colors/AccentColor"), style: StrokeStyle(lineWidth: 6, lineCap: .round, lineJoin: .round)) // Thinner line
                    .rotationEffect(Angle(degrees: 270.0))
                    .animation(.linear, value: rating)
                
                Text(String(format: "%.1f", rating)) // Display as a number with one decimal place
                    .font(.custom("MuseoSansRounded-500", size: 18)) // Slightly smaller font size
                    .foregroundColor(.primary)
                
                // Fun lines coming out of the circle if rating is 10
            }
            .frame(width: 50, height: 50) // Smaller frame size

            Text("Overall")
                .font(.custom("MuseoSansRounded-500", size: 16)) // Slightly smaller font size
                .foregroundColor(.primary)
        }
    }
}

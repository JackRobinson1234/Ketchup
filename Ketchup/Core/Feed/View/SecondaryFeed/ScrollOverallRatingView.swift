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
    var body: some View {
        
        if let rating = rating {
            VStack(spacing: 4) {
                ZStack {
                    Circle()
                        .stroke(lineWidth: 3) // Thicker stroke
                        .opacity(0.3)
                        .foregroundColor(Color.gray)
                    
                    Circle()
                        .trim(from: 0.0, to: CGFloat(min(rating / 10, 1.0)))
                        .stroke(Color("Colors/AccentColor"), style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round)) // Thicker stroke
                        .rotationEffect(Angle(degrees: 270.0))
                        .animation(.linear, value: rating)
                    
                    Text(String(format: "%.1f", rating))
                        .font(.custom("MuseoSansRounded-500", size: 18)) // Larger font size
                        .foregroundColor(font) // Apply the font color
                }
                .frame(width: 40, height: 40) // Larger size
            }
        }
    }
}

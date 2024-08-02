//
//  OverallRatingView.swift
//  Ketchup
//
//  Created by Jack Robinson on 7/9/24.
//

import SwiftUI

struct OverallRatingView: View {
    let rating: String
    
    private var numericRating: Double? {
        Double(rating)
    }
    
    var body: some View {
        VStack(spacing: 4) {
            if numericRating == 10 {
                Image("Skip")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40)
            } else {
                Spacer()
                    .frame(height: 20)  // To maintain consistent spacing when star is not shown
            }
            
            ZStack {
                Circle()
                    .stroke(lineWidth: 6)
                    .opacity(0.3)
                    .foregroundColor(Color.gray)
                
                if let numericRating = numericRating {
                    Circle()
                        .trim(from: 0.0, to: CGFloat(min(numericRating / 10, 1.0)))
                        .stroke(Color("Colors/AccentColor"), style: StrokeStyle(lineWidth: 6, lineCap: .round, lineJoin: .round))
                        .rotationEffect(Angle(degrees: 270.0))
                        .animation(.linear, value: numericRating)
                }
                
                Text(rating)
                    .font(.custom("MuseoSansRounded-500", size: 18))
                    .foregroundColor(.primary)
            }
            .frame(width: 50, height: 50)

            Text("Overall")
                .font(.custom("MuseoSansRounded-500", size: 16))
                .foregroundColor(.primary)
        }
    }
}

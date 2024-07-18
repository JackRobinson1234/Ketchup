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
        VStack(spacing: 8) {
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
                
                // Fun lines coming out of the circle if rating is 10
                if numericRating == 10 {
                    ForEach(0..<8) { index in
                        Line()
                            .stroke(Color("Colors/AccentColor"), lineWidth: 2)
                            .frame(width: 10, height: 2)
                            .offset(x: 30)
                            .rotationEffect(.degrees(Double(index) * 45))
                    }
                }
            }
            .frame(width: 50, height: 50)

            Text("Overall")
                .font(.custom("MuseoSansRounded-500", size: 16))
                .foregroundColor(.primary)
        }
    }
}

struct Line: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.width, y: rect.midY))
        return path
    }
}

//
//  ReviewSlideBar.swift
//  Ketchup
//
//  Created by Jack Robinson on 7/9/24.
//

import SwiftUI
struct RatingSliderGroup: View {
    let label: String
    @Binding var rating: Double
    
    var formattedRating: String {
        String(format: "%.1f", rating)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(label)
                    .font(.custom("MuseoSansRounded-300", size: 16))
                    .foregroundColor(.primary)
                
                Spacer()
                
                HStack(spacing: 2) {
                    Text(formattedRating)
                        .frame(width: 40, alignment: .trailing)
                        .font(.custom("MuseoSansRounded-300", size: 16))
                        .foregroundColor(.primary)
                    
                    Text("/ 10.0")
                        .font(.custom("MuseoSansRounded-300", size: 16))
                        .foregroundColor(.primary)
                }
            }
            
            Slider(value: $rating, in: 0...10, step: 0.5)
        }
        .onAppear {
            UISlider.appearance().setThumbImage(nil, for: .normal)
        }
    }
}

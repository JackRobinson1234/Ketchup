//
//  LeaderboardCover.swift
//  Ketchup
//
//  Created by Jack Robinson on 9/9/24.
//

import SwiftUI
import Kingfisher

struct LeaderboardCover: View {
    private let spacing: CGFloat = 8
    private var width: CGFloat {
        (UIScreen.main.bounds.width - (spacing * 2)) / 3
    }
    let cornerRadius: CGFloat = 5
    var imageUrl: String?
    var title: String
    var subtitle: String
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            if let imageUrl {
                KFImage(URL(string: imageUrl))
                    .resizable()
                    .scaledToFill()
                    .frame(width: 200, height: width + 40) // Slightly bigger image
                    .cornerRadius(cornerRadius)
                    .clipped()
            } else {
                Color.gray
                    .frame(width: 200, height: width + 40)
                    .cornerRadius(cornerRadius)
                    .clipped()
            }
            ZStack{
                VStack{
                    Spacer()
                    HStack{
                        Spacer()
                        Text(title)
                            .lineLimit(2)
                            .truncationMode(.tail)
                            .foregroundColor(.white)
                            .font(.custom("MuseoSansRounded-700", size: 16))
                            .shadow(color: .black, radius: 2, x: 0, y: 1)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity) // Ensures the title is centered
                            .padding(.horizontal, 8)
                        Spacer()
                    }
                    Spacer()
                }
                VStack(spacing: 0) {
                    // Title centered at the top
                    // Add some horizontal padding
                    
                    Spacer() // Push subtitle to the bottom
                    
                    // Subtitle at the bottom left
                    Text(subtitle)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .foregroundColor(.white)
                        .font(.custom("MuseoSansRounded-500", size: 12))
                        .shadow(color: .black, radius: 2, x: 0, y: 1)
                        .frame(maxWidth: .infinity, alignment: .leading) // Align to the left
                        .padding([.leading, .bottom], 8) // Padding for bottom left corner
                }
            }
            .frame(width: 200, height: width + 40) // Ensure the frame matches the image size
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [.clear, .black.opacity(0.7)]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .cornerRadius(cornerRadius)
        }
    }
}

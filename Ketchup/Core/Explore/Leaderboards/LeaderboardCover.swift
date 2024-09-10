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
    var body: some View {
        ZStack{
            if let imageUrl{
                KFImage(URL(string: imageUrl))
                    .resizable()
                    .scaledToFill()
                    .frame(width: 160, height: width)
                    .cornerRadius(cornerRadius)
                    .clipped()
            } else {
                Color.gray
                    .frame(width: 160, height: width)
                    .cornerRadius(cornerRadius)
                    .clipped()
            }
            Text("\(title)")
                .lineLimit(2)
                .truncationMode(.tail)
                .foregroundColor(.white)
                .font(.custom("MuseoSansRounded-300", size: 16))
                .bold()
                .shadow(color: .black, radius: 2, x: 0, y: 1)
                .multilineTextAlignment(.leading)
                .minimumScaleFactor(0.5)
        }
    }
}

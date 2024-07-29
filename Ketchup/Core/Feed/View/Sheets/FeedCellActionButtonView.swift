//
//  FeedCellActionButtonView.swift
//  Foodi
//
//  Created by Jack Robinson on 2/1/24.
//

import SwiftUI

struct FeedCellActionButtonView: View {
    let imageName: String
    var value: Int?
    var height: CGFloat? = 28
    var width: CGFloat? = 28
    var tintColor: Color?
    
    var body: some View {
        VStack {
            Image(systemName: imageName)
                .resizable()
                .scaledToFill()
                .frame(width: width, height: height)
                .foregroundStyle(tintColor ?? .white)
            
            if let value {
                Text("\(value)")
                    .font(.custom("MuseoSansRounded-300", size: 10))
                    .fontWeight(.bold)
            }
        }
        .foregroundStyle(.white)
        .shadow(color: .gray, radius: 2, x: 0, y: 0) // Add shadow here
    }
}

#Preview {
    FeedCellActionButtonView(imageName: "heart.fill", value: 40)
}

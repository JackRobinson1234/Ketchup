//
//  CollageImage.swift
//  Ketchup
//
//  Created by Jack Robinson on 7/13/24.
//

import SwiftUI
import Kingfisher
struct CollageImage: View {
    let tempImageUrls: [String]?
    let width: CGFloat
    
    private let outerSpacing: CGFloat = 2 // Space around the edges
    private let innerSpacing: CGFloat = 1 // Reduced space between images

    var body: some View {
        GeometryReader { geometry in
           if let tempUrls = tempImageUrls, !tempUrls.isEmpty {
                    if tempUrls.count < 4 {
                        KFImage(URL(string: tempUrls[0]))
                            .resizable()
                            .scaledToFill()
                            .frame(width: width, height: width)
                            .clipShape(Rectangle())
                            .cornerRadius(12)
                    } else {
                        VStack(spacing: innerSpacing) {
                            HStack(spacing: innerSpacing) {
                                KFImage(URL(string: tempUrls[0]))
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: (width - outerSpacing * 2 - innerSpacing) / 2, height: (width - outerSpacing * 2 - innerSpacing) / 2)
                                    .clipped()
                                KFImage(URL(string: tempUrls[1]))
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: (width - outerSpacing * 2 - innerSpacing) / 2, height: (width - outerSpacing * 2 - innerSpacing) / 2)
                                    .clipped()
                            }
                            HStack(spacing: innerSpacing) {
                                KFImage(URL(string: tempUrls[2]))
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: (width - outerSpacing * 2 - innerSpacing) / 2, height: (width - outerSpacing * 2 - innerSpacing) / 2)
                                    .clipped()
                                KFImage(URL(string: tempUrls[3]))
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: (width - outerSpacing * 2 - innerSpacing) / 2, height: (width - outerSpacing * 2 - innerSpacing) / 2)
                                    .clipped()
                            }
                        }
                        .padding(outerSpacing)
                        .frame(width: width, height: width)
                        .clipShape(Rectangle())
                        .cornerRadius(12)
                    }
                } else {
                    // Default view when no images are available
                    ZStack {
                        Color.gray.opacity(0.3) // Light gray background
                        Image(systemName: "building.2.fill")
                            .resizable()
                            .scaledToFit()
                            .foregroundColor(.red)
                            .frame(width: width * 0.5, height: width * 0.5)
                    }
                    .frame(width: width, height: width)
                    .clipShape(Rectangle())
                    .cornerRadius(12)
                }
             
        }
        .frame(width: width, height: width)
    }
}

//
//  ListingImageCarouselView.swift
//  Foodi
//
//  Created by Jack Robinson on 2/1/24.
//

import SwiftUI
import Kingfisher

struct ListingImageCarouselView: View {
    
    private var images: [String]?
    init(images: [String]? = nil) {
        self.images = images
    }
    
    var height: CGFloat = 225
    var body: some View {
        if let unwrappedImages = images{
            TabView {
                ForEach(unwrappedImages, id: \.self) { image in
                    KFImage(URL(string: image))
                        .resizable()
                        .scaledToFill()
                }
            } 
            .frame(height: height)
            .tabViewStyle(.page)
        } else {
            TabView {
                Image(systemName: "building.2.crop.circle")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 20, height: 70)
                    

            }
            .frame(height: height)
        }
    }
}

#Preview {
    ListingImageCarouselView()
}


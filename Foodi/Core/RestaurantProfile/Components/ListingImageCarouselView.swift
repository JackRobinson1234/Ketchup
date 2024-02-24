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
    
    var height: CGFloat = 300
    var body: some View {
        if let unwrappedImages = images{
            TabView {
                ForEach(unwrappedImages, id: \.self) { image in
                    KFImage(URL(string: image))
                        .placeholder {ProgressView()}
                        .resizable()
                        .scaledToFill()
                }
            }
            .frame(height: height)
            .tabViewStyle(.page)
        }
    }
}
/*
#Preview {
    ListingImageCarouselView(viewModel: RestaurantViewModel(restaurant: DeveloperPreview.restaurants[0], restaurantService: RestaurantService(), postService: PostService()))
}
*/

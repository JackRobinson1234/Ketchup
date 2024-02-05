//
//  ListingImageCarouselView.swift
//  Foodi
//
//  Created by Jack Robinson on 2/1/24.
//

import SwiftUI
import Kingfisher

struct ListingImageCarouselView: View {
    @ObservedObject var viewModel: RestaurantViewModel
    private var images: [String]? {
        return viewModel.restaurant.imageURLs ?? []
    }
    init(viewModel: RestaurantViewModel) {
        self.viewModel = viewModel
    }
    
    var height: CGFloat = 300
    var body: some View {
        TabView {
            ForEach(images!, id: \.self) { image in
                KFImage(URL(string: image))
                    .resizable()
                    .scaledToFill()
            }
        }
        .frame(height: height)
        .tabViewStyle(.page)
    }
}

#Preview {
    ListingImageCarouselView(viewModel: RestaurantViewModel(restaurant: DeveloperPreview.restaurants[0], restaurantService: RestaurantService(), postService: PostService()))
}

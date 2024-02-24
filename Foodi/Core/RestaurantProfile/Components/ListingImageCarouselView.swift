//
//  ListingImageCarouselView.swift
//  Foodi
//
//  Created by Jack Robinson on 2/1/24.
//

import SwiftUI
import Kingfisher

struct ListingImageCarouselView: View {
    private var restaurant: Restaurant
       
    init(restaurant: Restaurant) {
        self.restaurant = restaurant
    }
    
    var height: CGFloat = 300
    var body: some View {
        TabView {
            if let images = restaurant.imageURLs {
                ForEach(images, id: \.self) { image in
                    KFImage(URL(string: image))
                        .resizable()
                        .scaledToFill()
                }
                
                .frame(height: height)
                .tabViewStyle(.page)
            }
        }
    }
}
/*
#Preview {
    ListingImageCarouselView(viewModel: RestaurantViewModel(restaurant: DeveloperPreview.restaurants[0], restaurantService: RestaurantService(), postService: PostService()))
}
*/

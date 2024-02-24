//
//  RestaurantProfileHeaderView.swift
//  Foodi
//
//  Created by Jack Robinson on 2/2/24.
//

import SwiftUI
import Kingfisher
struct RestaurantProfileHeaderView: View {
    @Binding var currentSection: Section
    private var restaurant: Restaurant
    private var posts: [Post]?
    
    init(restaurant: Restaurant, currentSection: Binding<Section> = .constant(.posts), posts: [Post]?) {
        self._currentSection = currentSection
        self.restaurant = restaurant
        self.posts = posts
    }
    var body: some View {
        ScrollView {
            VStack{
                ListingImageCarouselView(images: restaurant.imageURLs)
                VStack(alignment: .center, spacing: 8) {
                    Text("\(restaurant.name)")
                        .font(.title)
                        .fontWeight(.semibold)
                }
                VStack(alignment: .center) {
                    Text("\(restaurant.address ?? "") \(restaurant.city ?? ""), \(restaurant.state ?? "")")
                        .font(.headline)
                        .fontWeight(.semibold)
                    Text("\(restaurant.cuisine ?? ""), \(restaurant.price ?? "")")
                        .font(.subheadline)
                    Text("\(restaurant.bio ?? "")")
                        .font(.caption)
                        .multilineTextAlignment(.center)
                }
                .padding([.leading, .trailing])
                
                Spacer()
                HStack(alignment: .center, spacing: 15) {
                    VStack{
                        Text("Available")
                            .foregroundColor(.green)
                            .fontWeight(.semibold)
                        Text("Reservations")
                    }
                    Divider()
                    
                    VStack{
                        Text("Available")
                            .foregroundColor(.green)
                            .fontWeight(.semibold)
                        Text("Delivery")
                    }
                    Divider()
                    
                    VStack{
                        Text("Open")
                            .foregroundColor(.green)
                            .fontWeight(.semibold)
                        Text("Reservations")
                    }
                }
                RestaurantProfileSlideBarView(restaurant: restaurant, posts: posts, currentSection: $currentSection)
            }
            .padding(.bottom, 100)
            
           
        }
        .ignoresSafeArea()
    }
}
/*
#Preview {
    RestaurantProfileHeaderView(viewModel: RestaurantViewModel(restaurant: DeveloperPreview.restaurants[0], restaurantService: RestaurantService(), postService: PostService()))
}
*/

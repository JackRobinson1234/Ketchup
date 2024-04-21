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
    @ObservedObject var viewModel: RestaurantViewModel
    @State var showAddToCollection = false
    @State var user: User? = nil

    
    var body: some View {
        if let restaurant = viewModel.restaurant {
        //let restaurant = DeveloperPreview.restaurants[0]
            ScrollView {
                VStack{
                    ListingImageCarouselView(images: restaurant.imageURLs)
                    VStack(alignment: .center, spacing: 8) {
                        Text("\(restaurant.name)")
                            .font(.title)
                            .fontWeight(.semibold)
                            .multilineTextAlignment(.center)
                    }
                    VStack(alignment: .center) {
                        Text("\(restaurant.address ?? "") \(restaurant.city ?? ""), \(restaurant.state ?? "")")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
                        Text("\(restaurant.cuisine ?? ""), \(restaurant.price ?? "")")
                            .font(.subheadline)
                        Text("\(restaurant.bio ?? "")")
                            .font(.caption)
                            .multilineTextAlignment(.center)
                    }
                    Button{
                    // Add Functionality
                    } label: {
                        Text("Order Now/ Make a Reservation")
                            .modifier(StandardButtonModifier(width: 275))
                    }
                    .padding()
                    
                    
                    Spacer()
                    RestaurantProfileSlideBarView(currentSection: $currentSection, viewModel: viewModel)
                }
                .padding(.bottom, 100)
                
                
            }

            .ignoresSafeArea()
            .sheet(isPresented: $showAddToCollection) {
                if let user {
                    AddItemCollectionList(user: user, restaurant: restaurant)
                }
            }
        }
    }
}
#Preview {
    RestaurantProfileHeaderView(currentSection: .constant(.menu), viewModel: RestaurantViewModel(restaurantId: "", restaurantService: RestaurantService(), postService: PostService()))
}


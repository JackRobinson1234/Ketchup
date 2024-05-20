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
            ScrollView {
                VStack{
                    ListingImageCarouselView(images: restaurant.imageURLs)
                    VStack(alignment: .center, spacing: 8) {
                        Text("\(restaurant.name)")
                            .font(.title)
                            .fontWeight(.semibold)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    VStack(alignment: .center) {
                        Text("\(restaurant.address ?? "") \(restaurant.city ?? ""), \(restaurant.state ?? "")")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .padding(.horizontal)
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
                            
                        Text("\(restaurant.cuisine ?? ""), \(restaurant.price ?? "")")
                            .font(.subheadline)
                            .padding(.horizontal)
                        Text("\(restaurant.bio ?? "")")
                            .font(.caption)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    HStack {
                        Text("Featured In:")
                        UserStatView(value: restaurant.stats.collectionCount, title: "Collections")
                        UserStatView(value: restaurant.stats.postCount, title: "Posts")
                    }
                    .padding()
                    
                    
                    Spacer()
                    RestaurantProfileSlideBarView(currentSection: $currentSection, viewModel: viewModel)
                }
                //.padding(.bottom, 100)
                
                
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
    RestaurantProfileHeaderView(currentSection: .constant(.menu), viewModel: RestaurantViewModel(restaurantId: ""))
}


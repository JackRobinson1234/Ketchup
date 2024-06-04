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
            
            VStack (alignment: .leading){
                    //ListingImageCarouselView(images: restaurant.imageURLs)
                    ZStack(alignment: .bottomLeading) {
                        if let imageURLs = restaurant.profileImageUrl{
                            ListingImageCarouselView(images: [imageURLs])
                        }
                        VStack(alignment: .leading, spacing: 8) {
                            Text("\(restaurant.name)")
                                .font(.title)
                                .fontWeight(.semibold)
                                .multilineTextAlignment(.center)
                                .padding()
                                .foregroundStyle(.white)
                            
                        }
                        .frame(maxWidth: .infinity)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.clear, Color.black.opacity(0.6),]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    }
                VStack (alignment: .leading, spacing: 8){
                    VStack(alignment: .leading){
                        if let street = restaurant.address, !street.isEmpty {
                            HStack{
                                Text(street)
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                Spacer()
                            }
                        }
//                        if let city = restaurant.city, let state = restaurant.state {
//                            Text("\(city), \(state)")
//                                .font(.subheadline)
//                                .fontWeight(.semibold)
//                        }
                    }
                        
                        if let cuisine = restaurant.cuisine, let price = restaurant.price {
                            Text("\(cuisine), \(price)")
                                .font(.subheadline)
                                
                        } else if let cuisine = restaurant.cuisine {
                            Text(cuisine)
                                .font(.subheadline)
                               
                        } else if let price = restaurant.price {
                            Text(price)
                                .font(.subheadline)
                        }
                       
                        Text("\(restaurant.bio ?? "")")
                            .font(.subheadline)
                            .multilineTextAlignment(.leading)
                            .padding(.top)
                        
                        
                    
                    
                    HStack {
                        Spacer()
                        Text("Featured In:")
                            .foregroundStyle(.gray)
                            .font(.subheadline)
                        
                        UserStatView(value: restaurant.stats.collectionCount, title: "Collections")
                        UserStatView(value: restaurant.stats.postCount, title: "Posts")
                        Spacer()
                    }
                   
                    }
                .padding([.horizontal, .top])
                    
                    
                    
                    RestaurantProfileSlideBarView(currentSection: $currentSection, viewModel: viewModel)
                }
                //.padding(.bottom, 100)
                

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


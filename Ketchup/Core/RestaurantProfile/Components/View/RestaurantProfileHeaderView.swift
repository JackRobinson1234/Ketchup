//
//  RestaurantProfileHeaderView.swift
//  Foodi
//
//  Created by Jack Robinson on 2/2/24.
//

import SwiftUI
import Kingfisher
import MapKit
struct RestaurantProfileHeaderView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: RestaurantViewModel
    @State var showAddToCollection = false
    @State var user: User? = nil
    @State var showMapView: Bool = false
    @State var route: MKRoute?
    @State private var travelInterval: TimeInterval?
    var travelTime: String? {
        guard let travelInterval else { return nil}
        let formatter = DateComponentsFormatter()
            formatter.unitsStyle = .full
            formatter.allowedUnits = [.hour, .minute]
            formatter.maximumUnitCount = 2 
        return formatter.string(from: travelInterval)
    }
    var body: some View {
        if let restaurant = viewModel.restaurant {
            VStack (alignment: .leading, spacing: 6){
                //ListingImageCarouselView(images: restaurant.imageURLs)
                ZStack(alignment: .bottomLeading) {
                    if let imageURLs = restaurant.profileImageUrl{
                        ListingImageCarouselView(images: [imageURLs])
                            .overlay(
                                LinearGradient(
                                    gradient: Gradient(stops: [
                                        .init(color: Color.clear, location: 0.6),
                                        .init(color: Color.black.opacity(0.6), location: 1.0)
                                    ]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    }
                    
                    HStack{
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(restaurant.name)")
                                .font(.custom("MuseoSans-500", size: 20))
                                .fontWeight(.semibold)
                                .multilineTextAlignment(.leading)
                                .foregroundStyle(.white)
                            if let cuisine = restaurant.cuisine, let price = restaurant.price {
                                Text("\(cuisine), \(price)")
                                    .font(.custom("MuseoSans-500", size: 16))
                                    .foregroundStyle(.white)
                                
                            } else if let cuisine = restaurant.cuisine {
                                Text(cuisine)
                                    .font(.custom("MuseoSans-500", size: 16))
                                    .foregroundStyle(.white)
                                
                            } else if let price = restaurant.price {
                                Text(price)
                                    .font(.custom("MuseoSans-500", size: 16))
                                    .foregroundStyle(.white)
                            }
                            if let city = restaurant.city, !city.isEmpty, let state = restaurant.state, !state.isEmpty {
                                Text("\(city), \(state)")
                                    .font(.custom("MuseoSans-500", size: 16))
                                    .fontWeight(.semibold)
                                    .multilineTextAlignment(.leading)
                                    .foregroundStyle(.white)
                            } else if let city = restaurant.city, !city.isEmpty {
                                Text("\(city)")
                                    .font(.custom("MuseoSans-500", size: 16))
                                    .fontWeight(.semibold)
                                    .multilineTextAlignment(.leading)
                                    .foregroundStyle(.white)
                            } else if let state = restaurant.state, !state.isEmpty {
                                Text("\(state)")
                                    .font(.custom("MuseoSans-500", size: 16))
                                    .fontWeight(.semibold)
                                    .multilineTextAlignment(.leading)
                                    .foregroundStyle(.white)
                            }
                        }
                        .padding([.horizontal, .bottom])
                        
                        Spacer()
                    }
                    VStack{
                        HStack{
                            Button {
                                dismiss()
                            } label: {
                                Image(systemName: "chevron.left")
                                    .foregroundStyle(.white)
                                    .background(
                                        Circle()
                                            .fill(Color.gray.opacity(0.5)) // Adjust the opacity as needed
                                            .frame(width: 30, height: 30) // Adjust the size as needed
                                    )
                            }
                            Spacer()
                        }
                        .padding(50)
                        Spacer()
                    }
                }
                .frame(maxWidth: .infinity)
                
                
                
                VStack(alignment: .leading) {
                    Button{
                        showMapView.toggle()
                        
                    } label: {
                        if let street = restaurant.address, !street.isEmpty {
                            VStack(alignment: .leading){
                                    if let travelTime {
                                        HStack(spacing: 0){
                                            Image(systemName: "car")
                                            Text(" \(travelTime)")
                                                .font(.custom("MuseoSans-500", size: 16))
                                                .foregroundStyle(.primary)
                                        }
                                    }
                                
                                    Text("(Click to view on map)")
                                        .font(.custom("MuseoSans-500", size: 12))
                                
                            }
                        }
                    }
                    
                    Text("\(restaurant.bio ?? "")")
                        .font(.custom("MuseoSans-500", size: 16))
                        .multilineTextAlignment(.leading)

                }
                .padding()
                
                
                
                
                RestaurantProfileSlideBarView(viewModel: viewModel)
            }
            
            .onReceive(LocationManager.shared.$userLocation.dropFirst().prefix(1)) { userLocation in
                guard userLocation != nil else {
                    return
                }
                Task {
                    if let restaurant = viewModel.restaurant, let coordinates = restaurant.coordinates {
                        let result = await LocationManager.shared.fetchRoute(coordinates: coordinates)
                        route = result.0
                        travelInterval = result.1
                    }
                }
            }
            .ignoresSafeArea()
            .sheet(isPresented: $showAddToCollection) {
                if let user {
                    AddItemCollectionList(user: user, restaurant: restaurant)
                }
            }
            .sheet(isPresented: $showMapView) {
                MapRestaurantProfileView(viewModel: viewModel, route: $route, travelInterval: $travelInterval)
                    .presentationDetents([.height(UIScreen.main.bounds.height * 0.5)])
                
            }
        }
    }
}
#Preview {
    RestaurantProfileHeaderView(viewModel: RestaurantViewModel(restaurantId: ""))
}

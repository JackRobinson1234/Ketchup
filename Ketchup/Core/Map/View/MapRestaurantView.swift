//
//  MapRestaurantView.swift
//  Foodi
//
//  Created by Jack Robinson on 2/12/24.
//  View that appears when you click on a restaurant

import SwiftUI
import Kingfisher
import MapKit

struct MapRestaurantView: View {
    let restaurant: Restaurant
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
        
        VStack {
            ZStack(alignment: .bottomLeading) {
//                if let images = restaurant.imageURLs {
                TabView {
                    //                        ForEach(images, id: \.self) { image in
                    if let image = restaurant.profileImageUrl{
                        KFImage(URL(string: image))
                            .resizable()
                            .scaledToFill()
                            .clipShape(Rectangle())
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
                }
                    .frame(height: 200)
                    .tabViewStyle(.page)
                NavigationLink(destination: RestaurantProfileView(restaurantId: restaurant.id)) {
                    Text("\(restaurant.name)")
                        .font(.title)
                        .bold()
                        .multilineTextAlignment(.leading)
                        .foregroundStyle(.white)
                }
                .padding()
                }
            
            
            HStack {
                VStack(alignment: .leading) {
                    
                       
                    if let cuisine = restaurant.cuisine, let price = restaurant.price {
                        Text("\(cuisine), \(price)")
                            .font(.subheadline)
                            .foregroundStyle(.gray)
                        
                    } else if let cuisine = restaurant.cuisine {
                        Text(cuisine)
                            .font(.subheadline)
                            .foregroundStyle(.gray)
                        
                    } else if let price = restaurant.price {
                        Text(price)
                            .font(.subheadline)
                            .foregroundStyle(.gray)
                    }
                
                    Text("\(restaurant.city ?? ""), \(restaurant.state ?? "")")
                        .foregroundStyle(.gray)
                        .font(.subheadline)
                    if let travelTime {
                        HStack(spacing: 0){
                            Image(systemName: "car")
                            Text(" \(travelTime)")

                        }
                        .font(.subheadline)
                        .foregroundStyle(.gray)
                    }
                }
                
                Spacer()
                NavigationLink(destination: RestaurantProfileView(restaurantId: restaurant.id)) {
                        Text("View Profile")
                    }
                    .modifier(StandardButtonModifier(width: 150))
                    
            }
            .foregroundColor(.black)
            .font(.footnote)
            .padding()
        }
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .padding()
        .frame(width: UIScreen.main.bounds.width)
        .onReceive(LocationManager.shared.$userLocation.dropFirst().prefix(1)) { userLocation in
            guard userLocation != nil else {
                return
            }
            Task {
                if let coordinates = restaurant.coordinates {
                    let result = await LocationManager.shared.fetchRoute(coordinates: coordinates)
                    travelInterval = result.1
                }
            }
        }
    }
}

        
#Preview {
    MapRestaurantView(restaurant: DeveloperPreview.restaurants[0])
}

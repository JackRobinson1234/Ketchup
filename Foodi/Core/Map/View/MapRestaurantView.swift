//
//  MapRestaurantView.swift
//  Foodi
//
//  Created by Jack Robinson on 2/12/24.
//

import SwiftUI

struct MapRestaurantView: View {
    let restaurant: Restaurant
    var body: some View {
        
        VStack {
            ZStack(alignment: .topTrailing) {
                if let images = restaurant.imageURLs {
                    TabView {
                        ForEach(images, id: \.self) { imageUrl in
                            Image(imageUrl)
                                .resizable()
                                .scaledToFill()
                                .clipShape(Rectangle())
                        }
                    }
                    .frame(height: 200)
                    .tabViewStyle(.page)
                }
            }
            
            HStack(alignment: .top) {
                VStack(alignment: .leading) {
                    NavigationLink(destination: RestaurantProfileView(restaurant: restaurant)) {
                        Text("\(restaurant.name)")
                            .font(.subheadline)
                            .bold()
                            .multilineTextAlignment(.leading)
                    }
                       
                    
                    Text("\(restaurant.city ?? ""), \(restaurant.state ?? "")")
                        .foregroundStyle(.gray)
                    Text("\(restaurant.cuisine ?? ""), \(restaurant.price ?? "")")
                        .foregroundStyle(.gray)
                }
                
                Spacer()
                    NavigationLink(destination: RestaurantProfileView(restaurant: restaurant, currentSection: .menu)) {
                        Text("View Menu")
                    }
                    .modifier(StandardButtonModifier(width: 150))
                    
            }
            .foregroundColor(.black)
            .font(.footnote)
            .padding(8)
        }
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .padding()
    }
}

        
#Preview {
    MapRestaurantView(restaurant: DeveloperPreview.restaurants[0])
}

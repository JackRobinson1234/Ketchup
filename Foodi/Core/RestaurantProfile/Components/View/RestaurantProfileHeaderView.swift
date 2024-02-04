//
//  RestaurantProfileHeaderView.swift
//  Foodi
//
//  Created by Jack Robinson on 2/2/24.
//

import SwiftUI
struct RestaurantProfileHeaderView: View {
    var images = [
        "listings-1",
        "listings-2",
        "listings-3",
        "listings-4"
    ]
    
    var body: some View {
        ScrollView {
            ZStack(alignment: .topLeading) {
                ListingImageCarouselView()

            }
            VStack(alignment: .center, spacing: 8) {
                Text("Amir B's Pizzeria")
                    .font(.title)
                    .fontWeight(.semibold)
            }
            VStack(alignment: .center) {
                Text("2425 Piedmont Ave, Berkeley, CA 90254")
                    .font(.headline)
                    .fontWeight(.semibold)
                Text("Italian, $$")
                    .font(.subheadline)
                Text("Amir B's Pizzeria offers a delectable culinary experience, crafting mouthwatering pizzas with a perfect blend of fresh ingredients.")
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
            RestaurantProfileSlideBarView()
            
        }
        .ignoresSafeArea()
    }
}

#Preview {
    RestaurantProfileHeaderView()
}

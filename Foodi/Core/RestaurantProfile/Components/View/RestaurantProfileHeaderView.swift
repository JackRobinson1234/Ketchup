//
//  RestaurantProfileHeaderView.swift
//  Foodi
//
//  Created by Jack Robinson on 2/2/24.
//

import SwiftUI
struct RestaurantProfileHeaderView: View {
    @Binding var currentSection: Section
    @ObservedObject var viewModel: RestaurantViewModel
    private var restaurant: Restaurant {
        return viewModel.restaurant
    }
    
    init(viewModel: RestaurantViewModel, currentSection: Binding<Section> = .constant(.posts)) {
        self._currentSection = currentSection
        self.viewModel = viewModel
    }
    var body: some View {
        ScrollView {
            ZStack(alignment: .topLeading) {
                ListingImageCarouselView()

            }
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
            RestaurantProfileSlideBarView(currentSection: $currentSection)
            
        }
        .ignoresSafeArea()
    }
}

#Preview {
    RestaurantProfileHeaderView(viewModel: RestaurantViewModel(restaurant: DeveloperPreview.restaurants[0], restaurantService: RestaurantService(), postService: PostService()))
}

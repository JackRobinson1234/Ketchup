//
//  MapRestaurantProfileView.swift
//  Foodi
//
//  Created by Jack Robinson on 2/1/24.
//

import SwiftUI
import MapKit
import Kingfisher

struct MapRestaurantProfileView: View {
    @ObservedObject var viewModel: RestaurantViewModel
    private var restaurant: Restaurant {
        return viewModel.restaurant
    }
    private var coordinates: CLLocationCoordinate2D?
    
    init(viewModel: RestaurantViewModel) {
        self.viewModel = viewModel
        self.coordinates = restaurant.coordinates
    }
    
    var body: some View {
        if let coordinates {
            Map(initialPosition: .region(MKCoordinateRegion(center: coordinates, span: (MKCoordinateSpan(latitudeDelta: 0.015, longitudeDelta: 0.015))))){
                    Annotation(restaurant.name, coordinate: coordinates) {
                        RestaurantCircularProfileImageView(imageUrl: restaurant.profileImageUrl, size: .medium)
                    }
            }
            .mapStyle(.standard(elevation: .realistic))
            .frame(height: 300)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        else {
            Text("No Location Found")
        }
    }
}

#Preview {
    MapRestaurantProfileView(viewModel: RestaurantViewModel(restaurant: DeveloperPreview.restaurants[0], restaurantService: RestaurantService(), postService: PostService()))
}

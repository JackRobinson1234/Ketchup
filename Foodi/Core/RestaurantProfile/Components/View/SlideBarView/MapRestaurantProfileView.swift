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
        guard let latitude = restaurant.latitude else {
            print("DEBUG: No Longitude")
            return}
        guard let longitude = restaurant.longitude else {
            print("DEBUG: No Longitude")
            return}
        self.coordinates = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    var body: some View {
        if let coordinates {
            Map(initialPosition: .region(MKCoordinateRegion(center: coordinates, span: (MKCoordinateSpan(latitudeDelta: 0.015, longitudeDelta: 0.015))))){
                    Annotation(restaurant.name, coordinate: coordinates) {
                        RestaurantCircularProfileImageView(restaurant: restaurant, size: .medium)
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

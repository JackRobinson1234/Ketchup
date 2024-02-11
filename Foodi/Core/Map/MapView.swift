//
//  MapView.swift
//  Foodi
//
//  Created by Jack Robinson on 2/1/24.
//

import SwiftUI
import MapKit

struct MapView: View {
    @ObservedObject var viewModel: MapViewModel
        /*private var restaurant: Restaurant {
            return viewModel.restaurant
        } */
    @State var position: MapCameraPosition
    private var restaurants = DeveloperPreview.restaurants
    
    
    init() {
        self.viewModel = MapViewModel(restaurantService: RestaurantService(), postService: PostService())
            self._position = State(initialValue: .userLocation(fallback: .automatic))
        }
    
    var body: some View {
        Map(position: $position) {
            
            ForEach(restaurants, id: \.self) { restaurant in
                if let coordinates = restaurant.coordinates {
                    Annotation(restaurant.name, coordinate: coordinates) {
                        RestaurantCircularProfileImageView(restaurant: restaurant,color: .blue, size: .medium)
                    }
                }
            }
    }
            
        .mapStyle(.standard(elevation: .realistic))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .ignoresSafeArea()
    
        }
    }



#Preview {
    MapView()
}

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
    @State var position: MapCameraPosition
    @State private var selectedRestaurant: Restaurant?
    @State private var showDetails = false
    @State private var showRestaurantPreview = false
    
    
    init() {
        self.viewModel = MapViewModel(restaurantService: RestaurantService())
        self._position = State(initialValue: .userLocation(fallback: .automatic))
        }
    
    var restaurants: [Restaurant] {
        Task {await viewModel.fetchRestaurants()}
        return  viewModel.restaurants
    }
    var body: some View {
        NavigationStack{
            Map(position: $position, selection: $selectedRestaurant) {
                
                ForEach(restaurants, id: \.self) { restaurant in
                    if let coordinates = restaurant.coordinates {
                        Annotation(restaurant.name, coordinate: coordinates) {
                            RestaurantCircularProfileImageView(restaurant: restaurant,color: .blue, size: .medium)
                        }
                    }
                }
            }
            .onChange(of: selectedRestaurant, { oldValue, newValue in
                showRestaurantPreview = newValue != nil
                print($selectedRestaurant)
            })
            .mapStyle(.standard(elevation: .realistic))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .ignoresSafeArea()
            
            if showRestaurantPreview, let restaurant = selectedRestaurant {
                withAnimation(.snappy) {
                    MapRestaurantView(restaurant: restaurant)
                        .onTapGesture {
                            showRestaurantPreview.toggle()
                            showDetails.toggle()
                        }
                }
            }
        }
    }
    
    func clearSelectedListing() {
        selectedRestaurant = nil
        }
    }



#Preview {
    MapView()
}

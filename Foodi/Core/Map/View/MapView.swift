//
//  MapView.swift
//  Foodi
//
//  Created by Jack Robinson on 2/1/24.
//

import SwiftUI
import MapKit

struct MapView: View {
    @StateObject var viewModel: MapViewModel
    @State var position: MapCameraPosition
    @State private var selectedRestaurant: Restaurant?
    @State private var showDetails = false
    @State private var showRestaurantPreview = false
    @State private var fetchedData = false
    @State private var isSearchPresented: Bool = false
    
    
    init() {
        self._viewModel = StateObject(wrappedValue: MapViewModel(restaurantService: RestaurantService()))
        self._position = State(initialValue: .userLocation(fallback: .automatic))
        }
    
    var restaurants: [Restaurant] {
        Task {await viewModel.fetchRestaurants() }
        return  viewModel.restaurants
    }
    var body: some View {
        NavigationStack{
            ZStack(alignment: .bottom) {
                Map(position: $position, selection: $selectedRestaurant) {
                    
                    /*ForEach(restaurants, id: \.self) { restaurant in
                        if let coordinates = restaurant.coordinates {
                            Annotation(restaurant.name, coordinate: coordinates) {
                                RestaurantCircularProfileImageView(imageUrl: restaurant.profileImageUrl, color: .blue, size: .medium)
                            }
                        }
                    } */
                }
                    VStack {
                        HStack {
                            Button(action: {
                                isSearchPresented.toggle()
                            }) {
                                Image(systemName: "magnifyingglass")
                                    .foregroundStyle(.white)
                                    .font(.system(size: 27))
                                    .shadow(color: .gray, radius: 10)
                                    
        
                            }
                            .padding()
                            Spacer()
                        
                        .padding(.top)
                        Button {
                            //showFilters.toggle()
                        }
                        label: {
                            Image(systemName: "slider.horizontal.3")
                                .imageScale(.large)
                                .shadow(radius: 10)
                                .font(.system(size: 23))
                                
                        }
                        }
                        .padding(32)
                        .padding(.top, 20)
                        .foregroundStyle(.white)
                        Spacer()
                    }
                .onChange(of: selectedRestaurant, { oldValue, newValue in
                    showRestaurantPreview = newValue != nil
                })
                
                
                .sheet(isPresented: $isSearchPresented) {SearchView(userService: UserService(),searchConfig: .restaurants(restaurantListConfig: .restaurants))}
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
    }
    
    func clearSelectedListing() {
        selectedRestaurant = nil
        }
    }



#Preview {
    MapView()
}

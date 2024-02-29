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
    @State private var inSearchView: Bool = false
    @State private var isSearchPresented: Bool = false
    @State private var isFiltersPresented: Bool = false
    @ObservedObject var locationManager = LocationManager.shared
    @State var isLoading = true
    @Namespace var mapScope

    
    
    
    init() {
        self._viewModel = StateObject(wrappedValue: MapViewModel(restaurantService: RestaurantService()))
        self._position = State(initialValue: .userLocation(fallback: .automatic))
        }
    
    
    var body: some View {
        if isLoading {
            // Loading screen
            ProgressView("Loading...")
                .onAppear {
                    Task {
                        await viewModel.fetchRestaurants()
                        isLoading = false
                    }
                }
        } else {
            NavigationStack{
                ZStack(alignment: .bottom) {
                    Map(position: $position, selection: $selectedRestaurant, scope: mapScope) {
                        if !inSearchView{
                            ForEach(viewModel.restaurants, id: \.self) { restaurant in
                                if let coordinates = restaurant.coordinates {
                                    Annotation(restaurant.name, coordinate: coordinates) {
                                        RestaurantCircularProfileImageView(imageUrl: restaurant.profileImageUrl, color: .blue, size: .medium)
                                    }
                                }
                            }
                        } else {
                            ForEach(viewModel.searchPreview, id: \.self) { restaurant in
                                if let coordinates = restaurant.coordinates {
                                    Annotation(restaurant.name, coordinate: coordinates) {
                                        RestaurantCircularProfileImageView(imageUrl: restaurant.profileImageUrl, color: .blue, size: .medium)
                                    }
                                }
                            }
                        }
                        UserAnnotation()
                    }
                    .overlay(alignment: .bottomTrailing) {
                        VStack {
                            MapUserLocationButton(scope: mapScope)
                        }
                        .padding([.bottom, .trailing], 20)
                        .buttonBorderShape(.circle)
                    }
                    .mapScope(mapScope)
                    
                    VStack {
                        if !inSearchView{
                            HStack {
                                Button(action: {
                                    inSearchView.toggle()
                                    isSearchPresented.toggle()
                                    position = .automatic
                                }) {
                                    Image(systemName: "magnifyingglass")
                                        .foregroundStyle(.white)
                                        .font(.system(size: 27))
                                        .shadow(color: .gray, radius: 10)
                                    
                                    
                                }
                                Spacer()
                                
                                    .padding(.top)
                                Button {
                                    isFiltersPresented.toggle()
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
                        else {
                            VStack{
                                HStack{
                                    Button{
                                        inSearchView = false
                                        position = .userLocation(fallback: .automatic)
                                    } label: {
                                        Text("Cancel")
                                            .foregroundStyle(.blue)
                                            .bold()
                                    }
                                    Spacer()
                                }
                                .padding(32)
                                .padding(.top, 20)
                                Spacer()
                            }
                        }
                    }
                    .onChange(of: selectedRestaurant, { oldValue, newValue in
                        showRestaurantPreview = newValue != nil
                    })
                    
                    
                    .sheet(isPresented: $isSearchPresented) {
                        NavigationStack {
                            MapSearchView(restaurantService: RestaurantService(), mapViewModel: viewModel, inSearchView: $inSearchView)
                        }
                    }
                    .sheet(isPresented: $isFiltersPresented) {
                        NavigationStack {
                            FiltersView()
                        }
                    }
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
                .onAppear{LocationManager.shared.requestLocation()}
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

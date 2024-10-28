//
//  CuisineCategoryView.swift
//  Ketchup
//
//  Created by Jack Robinson on 10/22/24.
//

import SwiftUI
import Kingfisher
import CoreLocation

struct CuisineCategoryView: View {
    var selectedCuisines: [String]
    let groupedRestaurants: [String: [Restaurant]]
    @ObservedObject var locationViewModel: LocationViewModel
    private let columns: [GridItem] = Array(repeating: .init(.flexible(), spacing: 10), count: 2)
    @State private var showAllCuisines = false
    @State private var sortedCuisinesWithImages: [(cuisine: String, imageUrl: String)] = []
    @State private var hasCalculatedCuisines = false
    @State private var showLocationSearch = false

    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading) {
                    Text("Explore Restaurants")
                        .font(.custom("MuseoSansRounded-700", size: 25))
                        .foregroundStyle(.black)
                    Button {
                        showLocationSearch = true
                    } label: {
                    Text("Near \(locationViewModel.city != nil && locationViewModel.state != nil ? "\(locationViewModel.city!), \(locationViewModel.state!)" : "Any Location")")
                        .font(.custom("MuseoSansRounded-500", size: 12))
                        .foregroundColor(.gray)
                        +
                    Text(" (edit)")
                            .font(.custom("MuseoSansRounded-500", size: 12))
                            .foregroundColor(.red)
                }
                }
                Spacer()
                Button(action: {
                    showAllCuisines = true
                }) {
                    Text("See all")
                        .font(.custom("MuseoSansRounded-500", size: 12))
                        .foregroundStyle(.gray)
                }
            }
            .padding(.horizontal)
            
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(sortedCuisinesWithImages.prefix(8), id: \.cuisine) { cuisineData in
                    NavigationLink(destination: CuisineRestaurantsView(
                        cuisineName: cuisineData.cuisine,
                        restaurants: groupedRestaurants[cuisineData.cuisine] ?? [],
                        locationViewModel: locationViewModel
                    )) {
                        CuisineCell(
                            imageUrl: cuisineData.imageUrl,  // Use the pre-computed image URL
                            cuisineName: cuisineData.cuisine
                        )
                    }
                }
            }
            .padding(.horizontal)
        }
        .fullScreenCover(isPresented: $showAllCuisines) {
            AllCuisinesView(
                groupedRestaurants: groupedRestaurants,
                locationViewModel: locationViewModel,
                showAllCuisines: $showAllCuisines
            )
        }
        .sheet(isPresented: $showLocationSearch) {
            LocationSearchView(locationViewModel: locationViewModel)
                .presentationDetents([.height(UIScreen.main.bounds.height * 0.5)])
        }
        .onAppear {
            // Calculate cuisines and images only if it hasn't been done yet
            if !hasCalculatedCuisines {
                computeSortedCuisinesAndImages()
                hasCalculatedCuisines = true
            }
        }
    }
    
    private func computeSortedCuisinesAndImages() {
        let allCuisines = Array(groupedRestaurants.keys)
        let selectedCuisinesInOrder = selectedCuisines.filter { allCuisines.contains($0) }
        let unselectedCuisines = allCuisines.filter { !selectedCuisines.contains($0) }.shuffled()

        // Combine selected cuisines and shuffled unselected cuisines
        let sortedCuisines = selectedCuisinesInOrder + unselectedCuisines

        // Store a random image URL for each cuisine
        sortedCuisinesWithImages = sortedCuisines.map { cuisine in
            let randomImageUrl = groupedRestaurants[cuisine]?.randomElement()?.profileImageUrl ?? ""
            return (cuisine: cuisine, imageUrl: randomImageUrl)
        }
    }
}
struct CuisineCell: View {
    let imageUrl: String
    let cuisineName: String
    
    var body: some View {
        HStack(spacing: 0) {
            KFImage(URL(string: imageUrl))
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 50, height: 50)
                .clipped()
            
            VStack(alignment: .leading) {
                Text(cuisineName)
                    .font(.custom("MuseoSansRounded-700", size: 12))
                    .foregroundStyle(.black)
                    .multilineTextAlignment(.leading)
                
            }
            .padding(.horizontal, 4)
            
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        }
        .background(Color.gray.opacity(0.1))
        .cornerRadius(6)
    }
}
struct AllCuisinesView: View {
    let groupedRestaurants: [String: [Restaurant]]
    @ObservedObject var locationViewModel: LocationViewModel
    @Binding var showAllCuisines: Bool  // Binding to dismiss the full-screen cover
    private let columns: [GridItem] = Array(repeating: .init(.flexible(), spacing: 10), count: 2)  // Update spacing to 10
    
    private var sortedCuisines: [String] {
        groupedRestaurants.keys.sorted()
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 10) {  // Set spacing to 10
                    ForEach(sortedCuisines, id: \.self) { cuisine in
                        NavigationLink(destination: CuisineRestaurantsView(
                            cuisineName: cuisine,
                            restaurants: groupedRestaurants[cuisine] ?? [],
                            locationViewModel: locationViewModel
                        )) {
                            CuisineCell(
                                imageUrl: groupedRestaurants[cuisine]?.randomElement()?.profileImageUrl ?? "",
                                cuisineName: cuisine
                            )
                        }
                    }
                }
                .padding(.horizontal)
                .navigationTitle("All Cuisines")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") {
                            showAllCuisines = false  // Dismiss the full-screen cover
                        }
                    }
                }
            }
        }
    }
}
struct CuisineRestaurantsView: View {
    let cuisineName: String
    let restaurants: [Restaurant]
    @ObservedObject var locationViewModel: LocationViewModel
    
    @State private var sortOption: SortOption = .distance
    
    private let columns: [GridItem] = Array(repeating: .init(.flexible(), spacing: 10), count: 2)
    
    private enum SortOption: String, CaseIterable {
        case distance = "Distance"
        case rating = "Rating"
    }
    
    private var sortedRestaurants: [Restaurant] {
        switch sortOption {
        case .distance:
            guard let userLocation = locationViewModel.selectedLocationCoordinate else {
                return restaurants // If user location is not available, return the original list
            }
            let userCLLocation = CLLocation(latitude: userLocation.latitude, longitude: userLocation.longitude)
            return restaurants.sorted { (restaurant1, restaurant2) -> Bool in
                let distance1 = restaurant1.distance(from: userCLLocation)
                let distance2 = restaurant2.distance(from: userCLLocation)
                return (distance1 ?? Double.infinity) < (distance2 ?? Double.infinity)
            }
        case .rating:
            return restaurants.sorted { (restaurant1, restaurant2) -> Bool in
                let rating1 = restaurant1.overallRating?.average ?? 0.0
                let rating2 = restaurant2.overallRating?.average ?? 0.0
                return rating2 < rating1 // Descending order
            }
        }
    }
    
    var body: some View {
        VStack {
            // Display the map directly above the restaurant list
          

            ScrollView {
                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(sortedRestaurants, id: \.id) { restaurant in
                        if let coordinate = locationViewModel.selectedLocationCoordinate {
                            let userLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
                            NavigationLink(destination: RestaurantProfileView(restaurantId: restaurant.id)) {
                                RestaurantCardView(userLocation: userLocation, restaurant: restaurant)
                            }
                        } else {
                            NavigationLink(destination: RestaurantProfileView(restaurantId: restaurant.id)) {
                                RestaurantCardView(userLocation: nil, restaurant: restaurant)
                            }
                        }
                    }
                }
                .padding()
            }
        }
        .navigationTitle(cuisineName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Picker("Sort By", selection: $sortOption) {
                        ForEach(SortOption.allCases, id: \.self) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                } label: {
                    VStack {
                        Image(systemName: "arrow.up.arrow.down")
                            .foregroundStyle(Color("Colors/AccentColor"))
                        Text("Sort")
                            .font(.custom("MuseoSansRounded-500", size: 11))
                            .foregroundStyle(Color("Colors/AccentColor"))
                    }
                }
            }
        }
    }
}

extension Restaurant {
    func distance(from location: CLLocation) -> Double? {
        guard let restaurantLat = self.geoPoint?.latitude,
              let restaurantLon = self.geoPoint?.longitude else {
            return nil
        }
        let restaurantLocation = CLLocation(latitude: restaurantLat, longitude: restaurantLon)
        return location.distance(from: restaurantLocation)
    }
}

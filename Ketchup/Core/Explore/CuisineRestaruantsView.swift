//
//  CuisineRestaruantsView.swift
//  Ketchup
//
//  Created by Jack Robinson on 10/16/24.
//

import SwiftUI
import MapKit
import CoreLocation
import Kingfisher
import FirebaseFirestoreInternal

struct CuisineRestaurantsView: View {
    let cuisine: String
    let location: CLLocationCoordinate2D?
    @StateObject private var viewModel = CuisineRestaurantsViewModel()
    @Environment(\.dismiss) var dismiss // To dismiss the sheet if needed

    var body: some View {
        NavigationView {
            VStack {
                if viewModel.restaurants.isEmpty && !viewModel.isFetching {
                    Text("No restaurants found for \(cuisine)")
                        .padding()
                } else {
                    ScrollView {
                        LazyVStack {
                            ForEach(viewModel.restaurants.indices, id: \.self) { index in
                                let restaurant = viewModel.restaurants[index]
                                let userLocation = location.map { CLLocation(latitude: $0.latitude, longitude: $0.longitude) }
                                                               
                                                               NavigationLink(destination: RestaurantProfileView(restaurantId: restaurant.id)) {
                                                                   RestaurantCell(restaurant: restaurant, userLocation: userLocation, showFullAddress: false)
                                                                       .padding(.horizontal)
                                                               }
                                .onAppear {
                                    if index == viewModel.restaurants.count - 1 && viewModel.hasMoreRestaurants && !viewModel.isFetching {
                                        Task {
                                            await viewModel.fetchMoreRestaurants(cuisine: cuisine, location: location)
                                        }
                                    }
                                }
                            }
                            if viewModel.isFetching {
                                ProgressView()
                                    .frame(maxWidth: .infinity)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Popular \(cuisine) Nearby")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                Task {
                    await viewModel.fetchRestaurants(cuisine: cuisine, location: location)
                }
            }
        }
    }
}


struct CuisineRestaurantRowView: View {
    let restaurant: Restaurant

    var body: some View {
        HStack {
            if let imageUrl = restaurant.profileImageUrl {
                KFImage(URL(string: imageUrl))
                    .resizable()
                    .scaledToFill()
                    .frame(width: 60, height: 60)
                    .cornerRadius(8)
                    .clipped()
            } else {
                Image("placeholderImage")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 60, height: 60)
                    .cornerRadius(8)
                    .clipped()
            }
            VStack(alignment: .leading) {
                Text(restaurant.name)
                    .font(.headline)
                if let city = restaurant.city {
                    Text(city)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                if let price = restaurant.price, let category = restaurant.categoryName {
                    Text("\(category), \(price)")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                } else if let category = restaurant.categoryName {
                    Text(category)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                } else if let price = restaurant.price {
                    Text(price)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }
            Spacer()
        }
        .padding(.vertical, 4)
    }
}
@MainActor
class CuisineRestaurantsViewModel: ObservableObject {
    @Published var restaurants: [Restaurant] = []
    @Published var isFetching: Bool = false
    @Published var hasMoreRestaurants: Bool = true

    private var lastDocumentSnapshot: DocumentSnapshot?

    func fetchRestaurants(cuisine: String, location: CLLocationCoordinate2D?, limit: Int = 20) async {
        guard !isFetching else { return }
        isFetching = true

        do {
            let (newRestaurants, lastSnapshot) = try await RestaurantService.shared.fetchRestaurantsForCuisine(
                cuisine: cuisine,
                location: location ?? CLLocationCoordinate2D(latitude: 0, longitude: 0),
                lastDocument: lastDocumentSnapshot,
                limit: limit
            )
            if newRestaurants.isEmpty {
                hasMoreRestaurants = false
            }
            lastDocumentSnapshot = lastSnapshot
            restaurants.append(contentsOf: newRestaurants)
        } catch {
            print("Error fetching restaurants for cuisine \(cuisine): \(error)")
            hasMoreRestaurants = false
        }

        isFetching = false
    }

    func fetchMoreRestaurants(cuisine: String, location: CLLocationCoordinate2D?) async {
        await fetchRestaurants(cuisine: cuisine, location: location)
    }
}

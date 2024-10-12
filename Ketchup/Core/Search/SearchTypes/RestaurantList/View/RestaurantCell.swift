//
//  RestaurantCell.swift
//  Foodi
//
//  Created by Jack Robinson on 2/1/24.
//

import SwiftUI
import CoreLocation

struct RestaurantCell: View {
    let restaurant: Restaurant
    @State var userLocation: CLLocation? = LocationManager.shared.userLocation
    var showFullAddress: Bool = true // Default value to true

    @State private var highlightsAndTags: String = ""

    init(restaurant: Restaurant, userLocation: CLLocation? = nil, showFullAddress: Bool = true) {
        self.restaurant = restaurant
        self.userLocation = userLocation
        self.showFullAddress = showFullAddress
    }
    
    private var distanceString: String? {
        guard let userLocation = userLocation,
              let restaurantLat = restaurant._geoloc?.lat,
              let restaurantLon = restaurant._geoloc?.lng else {
            return nil
        }
        let restaurantLocation = CLLocation(latitude: restaurantLat, longitude: restaurantLon)
        let distanceInMeters = userLocation.distance(from: restaurantLocation)
        let distanceInMiles = distanceInMeters / 1609.34 // Convert meters to miles
        
        return String(format: "%.1f mi", distanceInMiles)
    }
    
    var body: some View {
        HStack(spacing: 12) {
            RestaurantCircularProfileImageView(imageUrl: restaurant.profileImageUrl, size: .large)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(restaurant.name)
                    .font(.custom("MuseoSansRounded-300", size: 16))
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.leading)
                    .foregroundColor(.black)
                
                // Display restaurant details on one line
                Text("\(combineRestaurantDetails(restaurant: restaurant))")
                    .font(.custom("MuseoSansRounded-300", size: 12))
                    .foregroundColor(.gray)
                
                // Display post count and rating on a separate line
                if let postAndRating = getPostAndRating(restaurant: restaurant) {
                    Text(postAndRating)
                        .font(.custom("MuseoSansRounded-300", size: 12))
                        .foregroundColor(.gray)
                }

                // Show full address or just city and state based on the showFullAddress parameter
                if showFullAddress {
                    let address = restaurant.address ?? "Unknown Address"
                    let addressWithoutZip = removeZipCode(from: address)
                    Text("\(addressWithoutZip)")
                        .font(.custom("MuseoSansRounded-300", size: 10))
                        .multilineTextAlignment(.leading)
                        .foregroundColor(.gray)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                } else {
                    let city = restaurant.city ?? "Unknown City"
                    let state = restaurant.state ?? "Unknown State"
                    Text("\(city), \(state)")
                        .font(.custom("MuseoSansRounded-300", size: 10))
                        .multilineTextAlignment(.leading)
                        .foregroundColor(.gray)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                }
                
                if let distance = distanceString {
                    Text("\(distance) away")
                        .font(.custom("MuseoSansRounded-300", size: 10))
                        .foregroundColor(Color("Colors/AccentColor"))
                }
            }
            .foregroundStyle(.black)
            
            Spacer()

            Image(systemName: "chevron.right")
                .foregroundStyle(.gray)
        }
        .onAppear{
            calculateHighlightsAndTags(restaurant: restaurant)
        }
    }
    
    private func calculateHighlightsAndTags(restaurant: Restaurant) {
        var items = [String]()
        
        if let highlights = restaurant.additionalInfo?.highlights {
            items.append(contentsOf: highlights.compactMap { $0.name })
        }
        
        if let reviewTags = restaurant.reviewsTags {
            items.append(contentsOf: reviewTags.compactMap { $0.title })
        }
        
        highlightsAndTags = Array(Set(items))
            .map { $0.capitalized }
            .joined(separator: ", ")
    }
    
    private func removeZipCode(from address: String) -> String {
        let components = address.components(separatedBy: ", ")
        if components.count > 1 {
            var newComponents = components
            let lastComponent = components.last ?? ""
            let stateAndZip = lastComponent.components(separatedBy: .whitespaces)
            if stateAndZip.count > 1 {
                newComponents[newComponents.count - 1] = stateAndZip[0]
            }
            return newComponents.joined(separator: ", ")
        }
        return address
    }
    
    private func combineRestaurantDetails(restaurant: Restaurant) -> String {
        var details = [String]()
        
        if let cuisine = restaurant.categoryName {
            details.append(cuisine)
        }
        if let price = restaurant.price {
            details.append(price)
        }
        
        return details.joined(separator: ", ")
    }
    
    // Function to get post count and rating as a separate string
    private func getPostAndRating(restaurant: Restaurant) -> String? {
        var details = [String]()
        
        // Add post count from stats
        if let postCount = restaurant.stats?.postCount, postCount > 0 {
            details.append("\(postCount) posts")
        }
        
        // Add overall rating if available
        if let averageRating = restaurant.overallRating?.average, let totalCount = restaurant.overallRating?.totalCount {
            details.append(String(format: "rating: %.1f", averageRating))
        }
        
        return details.isEmpty ? nil : details.joined(separator: ", ")
    }
}

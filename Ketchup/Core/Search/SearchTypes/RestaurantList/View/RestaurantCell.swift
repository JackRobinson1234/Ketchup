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
    
    init(restaurant: Restaurant, userLocation: CLLocation? = nil) {
        self.restaurant = restaurant
        self.userLocation = userLocation
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
                
                
                Text("\(combineRestaurantDetails(restaurant: restaurant))")
                    .font(.custom("MuseoSansRounded-300", size: 12))
                    .foregroundColor(.gray)
                let address = restaurant.address ?? "Unknown Address"
                let addressWithoutZip = removeZipCode(from: address)
                Text("\(addressWithoutZip)")
                    .font(.custom("MuseoSansRounded-300", size: 10))
                    .multilineTextAlignment(.leading)
                    .foregroundColor(.gray)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
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
}

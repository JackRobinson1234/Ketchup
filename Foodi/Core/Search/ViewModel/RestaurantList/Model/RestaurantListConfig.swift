//
//  RestaurantListConfig.swift
//  Foodi
//
//  Created by Jack Robinson on 2/1/24.
//

import Foundation

enum RestaurantListConfig: Hashable {
    case restaurants
    case upload
    case favorites
   
    
    var navigationTitle: String {
        switch self {
        case .restaurants: return "Explore"
        case .upload: return "Select a Restaurant to Post"
        case .favorites: return "Select New Favorite"
        }
    }
}

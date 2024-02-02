//
//  RestaurantListConfig.swift
//  Foodi
//
//  Created by Jack Robinson on 2/1/24.
//

import Foundation

enum RestaurantListConfig: Hashable {
    case restaurants
   
    
    var navigationTitle: String {
        switch self {
        case .restaurants: return "Explore"
        
        }
    }
}

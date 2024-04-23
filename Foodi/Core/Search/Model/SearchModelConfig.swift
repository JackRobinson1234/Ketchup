//
//  File.swift
//  Foodi
//
//  Created by Jack Robinson on 2/1/24.
//


import Foundation

enum SearchModelConfig: Hashable {
    case posts
    case users
    case restaurants(restaurantListConfig: RestaurantListConfig)
    case collections
}

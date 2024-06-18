//
//  RestaurantRequest.swift
//  Ketchup
//
//  Created by Jack Robinson on 6/15/24.
//

import Foundation
import SwiftUI
import Firebase
struct RestaurantRequest: Codable {
    let id: String
    let userid: String
    let name: String
    let state: String
    let city: String
    let timestamp: Timestamp
    let postType: String
    // Unix timestamp in seconds

    init(id: String, userid: String, name: String, state: String, city: String, timestamp: Timestamp, postType: String) {
        self.id = id
        self.userid = userid
        self.name = name
        self.state = state
        self.city = city
        self.timestamp = timestamp
        self.postType = postType
    }
}

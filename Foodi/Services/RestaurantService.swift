//
//  RestaurantService.swift
//  Foodi
//
//  Created by Jack Robinson on 2/1/24.
//

import Foundation
import FirebaseAuth
import FirebaseFirestoreSwift
import FirebaseFirestore
class RestaurantService {
    //func
    func fetchRestaurant (withId id: String) async throws -> Restaurant {
        return try await FirestoreConstants.RestaurantCollection.document(id).getDocument(as: Restaurant.self)
    }

}

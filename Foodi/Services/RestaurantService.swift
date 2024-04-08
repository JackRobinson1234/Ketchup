//
//  RestaurantService.swift
//  Foodi
//
//  Created by Jack Robinson on 2/1/24.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore
import MapKit
import GeoFire

class RestaurantService {
    
    //MARK: fetchRestaurant
    /// Fetches a single restaurant given an ID
    /// - Parameter id: String of an ID for a restaurant
    /// - Returns: RestaurantObject
    func fetchRestaurant (withId id: String) async throws -> Restaurant {
        print("DEBUG: Ran fetchRestaurant()")
        return try await FirestoreConstants.RestaurantCollection.document(id).getDocument(as: Restaurant.self)
    }
    
    
    
    //MARK: fetchRestaurants
    /// Fetches an array of restaurants that match the provided filters
    /// - Parameter filters: dictionary of filters with the field and an array of matching conditions ex. ["cuisine" : ["japanese", chinese], "price": ["$"]
    /// - Returns: array of restaurants
    func fetchRestaurants(withFilters filters: [String: [Any]]? = nil) async throws -> [Restaurant] {
        var query = FirestoreConstants.RestaurantCollection.order(by: "id", descending: true)
        if let filters = filters, !filters.isEmpty {
            query = await applyFilters(toQuery: query, filters: filters)
        }
        let restaurants = try await query.getDocuments(as: Restaurant.self)
        //print("DEBUG: restaurants fetched", restaurants.count)
        return restaurants
    }
    
    
    //MARK: applyFilters
    /// Applies .whereFields to an existing query that are associated with the filters
    /// - Parameters:
    ///   - query: the existing query that needs to have filters applied to it
    ///   - filters: an map of filter categories and a corresponding array of values ex: ["cuisine": ["Chinese","Japanese"]
    /// - Returns: the original query with .whereFields attached to it
    func applyFilters(toQuery query: Query, filters: [String: [Any]]) async -> Query {
        var updatedQuery = query
        for (field, value) in filters {
            switch field {
            case "location":
                if let coordinates = value.first as? CLLocation {
                    let modifiedQuery = await locationQuery(toQuery: updatedQuery, coordinates: coordinates)
                    updatedQuery = modifiedQuery
                }
            default:
                updatedQuery = updatedQuery.whereField(field, in: value)
            }
        }
        return updatedQuery
    }
    
    
    //MARK: locationQuery
    /// Uses GeoFire to fetch locations. If no locations are found, will give a query that will not return any restaurants
    /// - Parameters:
    ///   - query: existing query to have another .whereField appended to it
    ///   - coordinates: coordinates of the center of the radius
    /// - Returns: an updated query that finds restaurantIds based on returned restaurantIds from GeoFire
    func locationQuery(toQuery query: Query, coordinates: CLLocation, radius: Double? = 10.0) async -> Query {
        let radius: Double = 10.0
        let geoFire = GeoFireManager.shared.geoFire
        let circleQuery = geoFire.query(at: coordinates, withRadius: radius)
        var nearbyRestaurants: [String] = []
        // Perform the asynchronous GeoFire query
        let circleQueryResult = await withCheckedContinuation { continuation in
            circleQuery.observe(.keyEntered, with: { (key, location) in
                nearbyRestaurants.append(key)
            })
            circleQuery.observeReady {
                if !nearbyRestaurants.isEmpty {
                    let updatedQuery = query.whereField("id", in: nearbyRestaurants)
                    continuation.resume(returning: updatedQuery)
                } else {
                    /// Sets the query to an object where no restaurants will be found
                    let updatedQuery = query.whereField("id", in: ["No restaurant Found"])
                    continuation.resume(returning: updatedQuery)
                }
            }
        }
        /// Return the modified query asynchronously
        return circleQueryResult
    }
    
    
}

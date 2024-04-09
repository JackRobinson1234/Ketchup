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
                if let locationFilters = filters["location"], let coordinates = locationFilters.first as? CLLocationCoordinate2D {
                    let restaurants = try await fetchRestaurantsWithLocation(filters: filters, center: coordinates)
                    return restaurants
                }
                
                query = await applyFilters(toQuery: query, filters: filters)
            }
            let restaurants = try await query.getDocuments(as: Restaurant.self)
            print("DEBUG: restaurants fetched", restaurants.count)
            return restaurants
        }
    
    
    //MARK: applyFilters
    /// Applies .whereFields to an existing query that are associated with the filters
    /// - Parameters:
    ///   - query: the existing query that needs to have filters applied to it
    ///   - filters: an map of filter categories and a corresponding array of values ex: ["cuisine": ["Chinese","Japanese"]
    /// - Returns: the original query with .whereFields attached to it
    func applyFilters(toQuery query: Query, filters: [String: [Any]]) -> Query {
        var updatedQuery = query
        for (field, value) in filters {
            switch field {
            case "location":
                continue
            default:
                updatedQuery = updatedQuery.whereField(field, in: value)
            }
        }
        return updatedQuery
    }
    
    
    /// Fetches restaurants that fall within the "radiusInM" range and applies any additional filters selected to that query
    /// - Parameters:
    ///   - filters: an map of filter categories and a corresponding array of values ex: ["cuisine": ["Chinese","Japanese"]
    ///   - center: CLLocationCoordinate2D that represents the center point of the query
    /// - Returns: Array of restaurants that match all of the filters
    func fetchRestaurantsWithLocation(filters: [String: [Any]], center: CLLocationCoordinate2D) async throws -> [Restaurant] {
        let radiusInM: Double = 2 * 1000
        let queryBounds = GFUtils.queryBounds(forLocation: center,
                                              withRadius: radiusInM)
        let queries = queryBounds.map { bound -> Query in
            return applyFilters(toQuery: FirestoreConstants.RestaurantCollection
                .order(by: "geoHash")
                .start(at: [bound.startValue])
                .end(at: [bound.endValue]), filters: filters)
        }
        // After all callbacks have executed, matchingDocs contains the result. Note that this code executes all queries serially, which may not be optimal for performance.
        do {
            let matchingDocs = try await withThrowingTaskGroup(of: [Restaurant].self) { group -> [Restaurant] in
                for query in queries {
                    //await applyFilters(toQuery: query, filters: filters)
                    group.addTask {
                        let snapshot = try await query.getDocuments()
                        return snapshot.documents.compactMap { document in
                            try? document.data(as: Restaurant.self)
                        }
                    }
                }
                var matchingDocs = [Restaurant]()
                for try await documents in group {
                    matchingDocs.append(contentsOf: documents)
                }
                return matchingDocs
            }
            return matchingDocs
        } catch {
            throw error
        }
    }
}

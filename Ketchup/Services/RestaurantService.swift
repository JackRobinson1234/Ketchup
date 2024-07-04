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
    static let shared = RestaurantService() // Singleton instance
    private init() {}
    
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
    func fetchRestaurants(withFilters filters: [String: [Any]]? = nil, limit: Int = 0) async throws -> [Restaurant] {
        let _ = print("went in this fetch")
        var query = FirestoreConstants.RestaurantCollection.order(by: "id", descending: true)
        print("DEBUG: Initial query created with descending order by id")
        
        // Fetch a sample of restaurants to see if any exist in the collection
        let sampleSnapshot = try await query.limit(to: 1).getDocuments()
        let sampleRestaurants = sampleSnapshot.documents.compactMap { document -> Restaurant? in
            do {
                return try document.data(as: Restaurant.self)
            } catch {
                print("DEBUG: Error decoding sample restaurant document:", document.documentID, error)
                return nil
            }
        }
        print("DEBUG: Sample restaurants fetched to check existence:", sampleRestaurants.count)

        if let filters = filters, !filters.isEmpty {
            print("DEBUG: Filters are provided:", filters)
            
            if let locationFilters = filters["location"],
               let coordinates = locationFilters.first as? CLLocationCoordinate2D,
               let radiusInM = locationFilters[1] as? Double {
                print("DEBUG: Location filters found - Coordinates:", coordinates, "Radius (m):", radiusInM)
                let restaurants = try await fetchRestaurantsWithLocation(filters: filters, center: coordinates, radiusInM: radiusInM, limit: limit)
                print("DEBUG: Restaurants fetched with location filters:", restaurants.count)
                if restaurants.isEmpty {
                    print("DEBUG: No restaurants found within the location filters")
                } else {
                    print("DEBUG: Restaurants within location filters: not gonna print")
                }
                return restaurants
            } else {
                print("DEBUG: No valid location filters found in filters")
            }
            
            query = applyFilters(toQuery: query, filters: filters)
            print("DEBUG: Query after applying filters:", query)
        } else {
            print("DEBUG: No filters provided or filters are empty")
        }

        if limit > 0 {
            query = query.limit(to: limit)
            print("DEBUG: Query limit applied:", limit)
        } else {
            print("DEBUG: No limit applied to query")
        }

        let snapshot = try await query.getDocuments()
        let restaurants = snapshot.documents.compactMap { document -> Restaurant? in
            do {
                return try document.data(as: Restaurant.self)
            } catch {
                print("DEBUG: Error decoding restaurant document:", document.documentID, error)
                return nil
            }
        }
        print("DEBUG: Restaurants fetched:", restaurants.count)
        if restaurants.isEmpty {
            print("DEBUG: No restaurants found in the collection")
        } else {
            print("DEBUG: Fetched restaurants: not gonna print all of this")
        }
        return restaurants
    }

    
    
    //MARK: applyFilters
    /// Applies .whereFields to an existing query that are associated with the filters
    /// - Parameters:
    ///   - query: the existing query that needs to have filters applied to it
    ///   - filters: an map of filter categories and a corresponding array of values ex: ["cuisine": ["Chinese","Japanese"]
    /// - Returns: the original query with .whereFields attached to it
    func applyFilters(toQuery query: Query, filters: [String: [Any]], limit: Int = 0) -> Query {
        var updatedQuery = query
        for (field, value) in filters {
            switch field {
            case "location":
                continue
            default:
                updatedQuery = updatedQuery.whereField(field, in: value)
            }
        }
        if limit > 0 {
            updatedQuery = updatedQuery.limit(to: limit)
        }
        return updatedQuery
    }
    
    
    /// Fetches restaurants that fall within the "radiusInM" range and applies any additional filters selected to that query
    /// - Parameters:
    ///   - filters: an map of filter categories and a corresponding array of values ex: ["cuisine": ["Chinese","Japanese"]
    ///   - center: CLLocationCoordinate2D that represents the center point of the query
    /// - Returns: Array of restaurants that match all of the filters
    func fetchRestaurantsWithLocation(filters: [String: [Any]], center: CLLocationCoordinate2D, radiusInM: Double = 500, limit: Int = 0) async throws -> [Restaurant] {
        let queryBounds = GFUtils.queryBounds(forLocation: center,
                                              withRadius: radiusInM)
        let queries = queryBounds.map { bound -> Query in
            return applyFilters(toQuery: FirestoreConstants.RestaurantCollection
                .order(by: "geoHash")
                .start(at: [bound.startValue])
                .end(at: [bound.endValue]), filters: filters, limit: limit)
        }
        // After all callbacks have executed, matchingDocs contains the result. Note that this code executes all queries serially, which may not be optimal for performance.
        do {
            let matchingDocs = try await withThrowingTaskGroup(of: [Restaurant].self) { group -> [Restaurant] in
                for query in queries {
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
    
    
    func fetchClusters(withFilters filters: [String: [Any]]? = nil, limit: Int = 0) async throws -> [Cluster] {
        var query = FirestoreConstants.RestaurantCollection.order(by: "id", descending: true)
            if let filters = filters, !filters.isEmpty {
                if let locationFilters = filters["location"], let coordinates = locationFilters.first as? CLLocationCoordinate2D, let radiusInM = locationFilters[1] as? Double {
                    let restaurants = try await fetchClustersWithLocation(filters: filters, center: coordinates, radiusInM: radiusInM, limit: limit)
                    return restaurants
                }
            }
            return []
        }
    
    
    /// Fetches restaurants that fall within the "radiusInM" range and applies any additional filters selected to that query
    /// - Parameters:
    ///   - filters: an map of filter categories and a corresponding array of values ex: ["cuisine": ["Chinese","Japanese"]
    ///   - center: CLLocationCoordinate2D that represents the center point of the query
    /// - Returns: Array of restaurants that match all of the filters
    func fetchClustersWithLocation(filters: [String: [Any]], center: CLLocationCoordinate2D, radiusInM: Double, limit: Int = 0) async throws -> [Cluster] {
        let queryBounds = GFUtils.queryBounds(forLocation: center,
                                              withRadius: radiusInM)
        //print("bounds", queryBounds)
        let queries = queryBounds.map { bound -> Query in
            //print("endValue", bound.endValue)
//            let geoHash = Geohash(geohash: bound.endValue)
//            if let geoHash {
//                let geoHashCenter = geoHash.region.center
//            }
            return applyFilters(toQuery: FirestoreConstants.RestaurantCollection
                .order(by: "geoHash")
                .start(at: [bound.startValue])
                .end(at: [bound.endValue]), filters: filters, limit: limit)
        }
        print("Query length", queries.count)
        do {
            var clusters = try await withThrowingTaskGroup(of: Int.self) { group -> [Cluster] in
                for query in queries {
                    group.addTask {
                        let clusterCount = try await query.count.getAggregation(source: .server).count
                        return Int(truncating: clusterCount)/*[Cluster(coordinate: CLLocationCoordinate2D(latitude: 0, longitude: 0), count: Int(truncating: clusterCount))]*/
                    }
                }
                var clusters = 0
                for try await documents in group {
                    clusters += documents
                }
                let finalCluster = [Cluster(coordinate: center, count: clusters)]
                print(finalCluster)
                return finalCluster
            }
            //Add randomness?
//            print("cluster length", clusters.count)
//            
//            for index in 0..<clusters.count {
//                let bound = queryBounds[index]
//                if let geoHash = Geohash(geohash: bound.endValue) {
//                    let geoHashCenter = geoHash.region.center
//                    clusters[index].coordinate = geoHashCenter
//                }
//            }
            print("final clusters", clusters)
            return clusters
        }
        catch {
            throw error
        }
    }
    func requestRestaurant(requestRestaurant: RestaurantRequest) async throws {
        let ref = FirestoreConstants.RequestRestaurantCollection.document(requestRestaurant.id)
        guard let requestData = try? Firestore.Encoder().encode(requestRestaurant) else {
            print("not encoding request right")
            return
        }
        do {
            try await ref.setData(requestData)
        } catch {
            print("uploading a request failed")
        }
    }
}

//
//  ClusterService.swift
//  Ketchup
//
//  Created by Jack Robinson on 8/4/24.
//
import MapKit
import GeoFire
import CoreLocation
import Foundation
import Firebase

class ClusterService {
    static let shared = ClusterService() // Singleton instance
    private init() {}

    func fetchClustersWithLocation(filters: [String: [Any]], center: CLLocationCoordinate2D, radiusInM: Double = 500, zoomLevel: String, limit: Int = 0) async throws -> [Cluster] {
        print("Starting fetchClustersWithLocation with center: \(center), radiusInM: \(radiusInM), zoomLevel: \(zoomLevel), limit: \(limit)")
        print("Filters: \(filters)")

        let queryBounds = GFUtils.queryBounds(forLocation: center, withRadius: radiusInM)
        print("Generated Query Bounds: \(queryBounds)")

        let clustersCollection = Firestore.firestore().collection("clusters")
        let queries = queryBounds.map { bound -> Query in
            let query = applyFilters(toQuery: clustersCollection
                .whereField("zoomLevel", isEqualTo: zoomLevel)
                .order(by: "geoHash")
                .start(at: [bound.startValue])
                .end(at: [bound.endValue]), filters: filters)
            print("Constructed Query for bound (\(bound.startValue), \(bound.endValue)): \(query)")
            return query
        }

        do {
            let matchingDocs = try await withThrowingTaskGroup(of: [Cluster].self) { group -> [Cluster] in
                for (index, query) in queries.enumerated() {
                    group.addTask {
                        print("Executing Query \(index + 1): \(query)")
                        let snapshot = try await query.getDocuments()
                        print("Fetched Documents for Query \(index + 1): \(snapshot.documents.count) documents")
                        let clusters = snapshot.documents.compactMap { document in
                            try? document.data(as: Cluster.self)
                        }
                        print("Fetched Clusters for Query \(index + 1): \(clusters)")
                        return clusters
                    }
                }

                var allMatchingDocs = [Cluster]()
                for try await documents in group {
                    allMatchingDocs.append(contentsOf: documents)
                    print("Accumulated Clusters: \(allMatchingDocs.count) total clusters")
                }
                return allMatchingDocs
            }
            print("Total Fetched Clusters: \(matchingDocs.count)")
            return matchingDocs
        } catch {
            print("Error fetching clusters: \(error.localizedDescription)")
            throw error
        }
    }

    func applyFilters(toQuery query: Query, filters: [String: [Any]]) -> Query {
        print("Applying Filters: \(filters) to Query: \(query)")
        var updatedQuery = query
        for (field, value) in filters {
            switch field {
            case "location":
                continue
            default:
                updatedQuery = updatedQuery.whereField(field, in: value)
                print("Applied filter - Field: \(field), Value: \(value)")
            }
        }
        print("Final Query with Filters: \(updatedQuery)")
        return updatedQuery
    }
}

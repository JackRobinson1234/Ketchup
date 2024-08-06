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
        let queryBounds = GFUtils.queryBounds(forLocation: center, withRadius: radiusInM)
        let clustersCollection = Firestore.firestore().collection("clusters")
        let queries = queryBounds.map { bound -> Query in
            let query = applyFilters(toQuery: clustersCollection
                .whereField("zoomLevel", isEqualTo: zoomLevel)
                .order(by: "geoHash")
                .start(at: [bound.startValue])
                .end(at: [bound.endValue]), filters: filters)
            return query
        }

        do {
            let matchingDocs = try await withThrowingTaskGroup(of: [Cluster].self) { group -> [Cluster] in
                for query in queries {
                    group.addTask {
                        let snapshot = try await query.getDocuments()
                        let clusters = snapshot.documents.compactMap { document in
                            try? document.data(as: Cluster.self)
                        }
                        return clusters
                    }
                }

                var allMatchingDocs = [Cluster]()
                for try await documents in group {
                    allMatchingDocs.append(contentsOf: documents)
                }
                return allMatchingDocs
            }
            return matchingDocs
        } catch {
            throw error
        }
    }

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
}

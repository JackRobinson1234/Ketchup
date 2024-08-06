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
        print("DEBUG: Fetching clusters around center: \(center), with radius: \(radiusInM) meters at zoom level: \(zoomLevel)")
        
        let queryBounds = GFUtils.queryBounds(forLocation: center, withRadius: radiusInM)
        let clustersCollection = Firestore.firestore().collection("mapClusters")
        
        let queries = queryBounds.map { bound -> Query in
            let query = applyFilters(toQuery: clustersCollection
                .whereField("zoomLevel", isEqualTo: zoomLevel)
                .order(by: "geoHash")
                .start(at: [bound.startValue])
                .end(at: [bound.endValue]), filters: filters)
            print("DEBUG: Constructed query for bounds start at: \(bound.startValue) and end at: \(bound.endValue)")
            return query
        }

        do {
            let (matchingDocs, totalDocuments) = try await withThrowingTaskGroup(of: (clusters: [Cluster], count: Int).self) { group -> ([Cluster], Int) in
                for query in queries {
                    group.addTask {
                        let snapshot = try await query.getDocuments()
                        print("DEBUG: Executing query for clusters")
                        let clusters = snapshot.documents.compactMap { document -> Cluster? in
                            do {
                                let cluster = try document.data(as: Cluster.self)
                                print("DEBUG: Successfully decoded cluster with id: \(cluster.id)")
                                return cluster
                            } catch {
                                print("ERROR: Failed to decode cluster from document \(document.documentID). Error: \(error)")
                                print("DEBUG: Raw document data: \(document.data())")
                                return nil
                            }
                        }
                        print("DEBUG: Fetched \(clusters.count) clusters from bounds")
                        return (clusters, snapshot.documents.count)
                    }
                }

                var allMatchingDocs = [Cluster]()
                var totalDocumentCount = 0
                for try await (documents, count) in group {
                    allMatchingDocs.append(contentsOf: documents)
                    totalDocumentCount += count
                }
                print("DEBUG: Total clusters fetched: \(allMatchingDocs.count)")
                return (allMatchingDocs, totalDocumentCount)
            }
            
            print("Total number of documents fetched: \(totalDocuments)")
            print("Total number of successfully decoded clusters: \(matchingDocs.count)")
            return matchingDocs
        } catch {
            print("ERROR: Failed to fetch clusters with error \(error)")
            throw error
        }
    }

    func applyFilters(toQuery query: Query, filters: [String: [Any]]) -> Query {
        var updatedQuery = query
        for (field, value) in filters {
            if field == "location" {
                continue
            } else {
                updatedQuery = updatedQuery.whereField(field, in: value)
                print("DEBUG: Applied filter for field \(field) with values: \(value)")
            }
        }
        return updatedQuery
    }
}

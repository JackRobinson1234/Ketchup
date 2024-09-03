//
//  PostClusterService.swift
//  Ketchup
//
//  Created by Jack Robinson on 9/3/24.
//

import Foundation
import MapKit
import GeoFire
import CoreLocation
import Foundation
import Firebase
import FirebaseFirestoreInternal
import FirebaseAuth
class PostClusterService {
    static let shared = PostClusterService() // Singleton instance
    private init() {}
    
    func fetchPostClustersWithLocation(filters: [String: [Any]], center: CLLocationCoordinate2D, radiusInM: Double = 500, zoomLevel: String, limit: Int = 0) async throws -> [PostCluster] {
        print("DEBUG: Fetching post clusters around center: \(center), with radius: \(radiusInM), with filters: \(filters) meters at zoom level: \(zoomLevel)")
        
        let queryBounds = GFUtils.queryBounds(forLocation: center, withRadius: radiusInM)
        guard let currentId = Auth.auth().currentUser?.uid else {
            return []
        }
        let clustersCollection = Firestore.firestore().collection("userFollowingClusters").document(currentId).collection("clusters")
        
        let queries = queryBounds.map { bound -> Query in
            var query = clustersCollection
                .whereField("zoomLevel", isEqualTo: zoomLevel)
                .order(by: "geoHash")
                .start(at: [bound.startValue])
                .end(at: [bound.endValue])
            
            query = applyFilters(toQuery: query, filters: filters)
            print("DEBUG: Constructed query for bounds start at: \(bound.startValue) and end at: \(bound.endValue)")
            return query
        }
        
        do {
            let (matchingDocs, totalDocuments) = try await withThrowingTaskGroup(of: (clusters: [PostCluster], count: Int).self) { group -> ([PostCluster], Int) in
                for query in queries {
                    group.addTask {
                        let snapshot = try await query.getDocuments()
                        print("DEBUG: Executing query for post clusters")
                        let clusters = snapshot.documents.compactMap { document -> PostCluster? in
                            do {
                                var cluster = try document.data(as: PostCluster.self)
                                // Apply filtering and adjust cluster
                                if let adjustedCluster = self.adjustPostClusterForFilters(cluster, filters: filters) {
                                    print("DEBUG: Successfully decoded and filtered post cluster with id: \(adjustedCluster.id)")
                                    return adjustedCluster
                                }
                                return nil
                            } catch {
                                print("ERROR: Failed to decode post cluster from document \(document.documentID). Error: \(error)")
                                print("DEBUG: Raw document data: \(document.data())")
                                return nil
                            }
                        }
                        print("DEBUG: Fetched and filtered \(clusters.count) post clusters from bounds")
                        return (clusters, snapshot.documents.count)
                    }
                }
                
                var allMatchingDocs = [PostCluster]()
                var totalDocumentCount = 0
                for try await (documents, count) in group {
                    allMatchingDocs.append(contentsOf: documents)
                    totalDocumentCount += count
                }
                print("DEBUG: Total filtered post clusters fetched: \(allMatchingDocs.count)")
                return (allMatchingDocs, totalDocumentCount)
            }
            
            print("Total number of documents fetched: \(totalDocuments)")
            print("Total number of successfully decoded and filtered post clusters: \(matchingDocs.count)")
            return matchingDocs
        } catch {
            print("ERROR: Failed to fetch post clusters with error \(error)")
            throw error
        }
    }
    
    private func applyFilters(toQuery query: Query, filters: [String: [Any]]) -> Query {
        var updatedQuery = query
        for (field, value) in filters {
            if field == "location" {
                // Location filtering is handled by GeoHash queries
                continue
            } else if field == "userId" {
                if let userId = value as? String {
                    updatedQuery = updatedQuery.whereField("userId", isEqualTo: userId)
                }
            }
            // Add other specific filters for posts if needed
        }
        return updatedQuery
    }
    
    private func adjustPostClusterForFilters(_ cluster: PostCluster, filters: [String: [Any]]) -> PostCluster? {
        let filteredPosts = cluster.posts.filter { post in
            if let cuisines = filters["cuisine"] as? [String], !cuisines.isEmpty {
                guard let postCuisine = post.restaurant.cuisine, cuisines.contains(postCuisine) else {
                    return false
                }
            }
            
            if let prices = filters["price"] as? [String], !prices.isEmpty {
                guard let postPrice = post.restaurant.price, prices.contains(postPrice) else {
                    return false
                }
            }
            
            if let minRating = filters["minRating"] as? Double {
                guard let overallRating = post.overallRating, overallRating >= minRating else {
                    return false
                }
            }
            
            // Add more post-specific filters here
            
            return true
        }
        
        // If no posts pass the filter, return nil to exclude this cluster
        guard !filteredPosts.isEmpty else {
            return nil
        }
        
        // Create a new cluster with filtered posts and adjusted count
        return PostCluster(
            id: cluster.id,
            center: cluster.center,
            posts: filteredPosts,
            count: filteredPosts.count,
            zoomLevel: cluster.zoomLevel,
            truncatedGeoHash: cluster.truncatedGeoHash,
            geoHash: cluster.geoHash
        )
    }
}

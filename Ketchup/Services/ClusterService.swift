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
import FirebaseFirestoreInternal

class ClusterService {
    static let shared = ClusterService() // Singleton instance
    private init() {}
    
    func fetchClustersWithLocation(filters: [String: [Any]], center: CLLocationCoordinate2D, radiusInM: Double = 500, zoomLevel: String, limit: Int = 0) async throws -> [Cluster] {
        print("DEBUG: Fetching clusters around center: \(center), with radius: \(radiusInM), with filters: \(filters) meters at zoom level: \(zoomLevel)")
        
        let queryBounds = GFUtils.queryBounds(forLocation: center, withRadius: radiusInM)
        let clustersCollection = Firestore.firestore().collection("mapClusters")
        
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
            let (matchingDocs, totalDocuments) = try await withThrowingTaskGroup(of: (clusters: [Cluster], count: Int).self) { group -> ([Cluster], Int) in
                for query in queries {
                    group.addTask {
                        let snapshot = try await query.getDocuments()
                        print("DEBUG: Executing query for clusters")
                        let clusters = snapshot.documents.compactMap { document -> Cluster? in
                            do {
                                var cluster = try document.data(as: Cluster.self)
                                // Apply filtering and adjust cluster
                                if let adjustedCluster = self.adjustClusterForFilters(cluster, filters: filters) {
                                    print("DEBUG: Successfully decoded and filtered cluster with id: \(adjustedCluster.id)")
                                    return adjustedCluster
                                }
                                return nil
                            } catch {
                                print("ERROR: Failed to decode cluster from document \(document.documentID). Error: \(error)")
                                print("DEBUG: Raw document data: \(document.data())")
                                return nil
                            }
                        }
                        print("DEBUG: Fetched and filtered \(clusters.count) clusters from bounds")
                        return (clusters, snapshot.documents.count)
                    }
                }
                
                var allMatchingDocs = [Cluster]()
                var totalDocumentCount = 0
                for try await (documents, count) in group {
                    allMatchingDocs.append(contentsOf: documents)
                    totalDocumentCount += count
                }
                print("DEBUG: Total filtered clusters fetched: \(allMatchingDocs.count)")
                return (allMatchingDocs, totalDocumentCount)
            }
            
            print("Total number of documents fetched: \(totalDocuments)")
            print("Total number of successfully decoded and filtered clusters: \(matchingDocs.count)")
            return matchingDocs
        } catch {
            print("ERROR: Failed to fetch clusters with error \(error)")
            throw error
        }
    }
    
    private func applyFilters(toQuery query: Query, filters: [String: [Any]]) -> Query {
        var updatedQuery = query
        for (field, value) in filters {
            if field == "location" {
                // Location filtering is handled by GeoHash queries
                continue
            } else {
                // We'll handle cuisine and price filters in post-processing
                continue
            }
        }
        return updatedQuery
    }
    
    private func adjustClusterForFilters(_ cluster: Cluster, filters: [String: [Any]]) -> Cluster? {
        let filteredRestaurants = cluster.restaurants.filter { restaurant in
            if let cuisines = filters["cuisine"] as? [String], !cuisines.isEmpty {
                guard let restaurantCuisine = restaurant.cuisine, cuisines.contains(restaurantCuisine) else {
                    return false
                }
            }
            
            if let prices = filters["price"] as? [String], !prices.isEmpty {
                guard let restaurantPrice = restaurant.price, prices.contains(restaurantPrice) else {
                    return false
                }
            }
            return true
        }
        
        // If no restaurants pass the filter, return nil to exclude this cluster
        guard !filteredRestaurants.isEmpty else {
            return nil
        }
        
        // Create a new cluster with filtered restaurants and adjusted count
        return Cluster(
            id: cluster.id,
            center: cluster.center,
            restaurants: filteredRestaurants,
            count: filteredRestaurants.count,
            zoomLevel: cluster.zoomLevel,
            truncatedGeoHash: cluster.truncatedGeoHash,
            geoHash: cluster.geoHash
        )
    }
    func fetchFollowerPostsWithLocation(filters: [String: [Any]], center: CLLocationCoordinate2D, radiusInM: Double = 500, zoomLevel: String, limit: Int = 0) async throws -> [SimplifiedPost] {
        guard let currentUserID = Auth.auth().currentUser?.uid else { return [] }
        
        print("DEBUG: Fetching posts around center: \(center), with radius: \(radiusInM), with filters: \(filters) meters at zoom level: \(zoomLevel)")
        
        let queryBounds = GFUtils.queryBounds(forLocation: center, withRadius: radiusInM)
        let followingPostsRef = Firestore.firestore().collection("followingposts").document(currentUserID).collection("posts")
        
        let queries = queryBounds.map { bound -> Query in
            var query = followingPostsRef
                .order(by: "restaurant.geoHash")
                .start(at: [bound.startValue])
                .end(at: [bound.endValue])
            
            query = applyFiltersToPost(toQuery: query, filters: filters)
            print("DEBUG: Constructed query for bounds start at: \(bound.startValue) and end at: \(bound.endValue)")
            return query
        }
        
        do {
            let (matchingDocs, totalDocuments) = try await withThrowingTaskGroup(of: ([SimplifiedPost], Int).self) { group -> ([SimplifiedPost], Int) in
                for query in queries {
                    group.addTask {
                        let snapshot = try await query.getDocuments()
                        print("DEBUG: Executing query for posts")
                        let posts = snapshot.documents.compactMap { document -> SimplifiedPost? in
                            do {
                                let post = try document.data(as: SimplifiedPost.self)
                                print("DEBUG: Successfully decoded post with id: \(post.id)")
                                return post
                            } catch {
                                print("ERROR: Failed to decode post from document \(document.documentID). Error: \(error)")
                                print("DEBUG: Raw document data: \(document.data())")
                                return nil
                            }
                        }
                        print("DEBUG: Fetched and filtered \(posts.count) posts from bounds")
                        return (posts, snapshot.documents.count)
                    }
                }
                
                var allMatchingDocs = [SimplifiedPost]()
                var totalDocumentCount = 0
                for try await (documents, count) in group {
                    allMatchingDocs.append(contentsOf: documents)
                    totalDocumentCount += count
                }
                print("DEBUG: Total filtered posts fetched: \(allMatchingDocs.count)")
                return (allMatchingDocs, totalDocumentCount)
            }
            
            print("Total number of documents fetched: \(totalDocuments)")
            print("Total number of successfully decoded and filtered posts: \(matchingDocs.count)")
            return matchingDocs
        } catch {
            print("ERROR: Failed to fetch posts with error \(error)")
            throw error
        }
    }
    
    private func applyFiltersToPost(toQuery query: Query, filters: [String: [Any]]) -> Query {
        var updatedQuery = query
        for (field, value) in filters {
            if field == "location" {
                // Location filtering is handled by GeoHash queries
                continue
            } else {
                // We'll handle cuisine and price filters in post-processing
                continue
            }
        }
        return updatedQuery
    }
}

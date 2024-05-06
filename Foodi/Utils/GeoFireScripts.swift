//
//  ActivityView.swift
//  Foodi
//
//  Created by Jack Robinson on 3/8/24.
//

import SwiftUI
import FirebaseDatabase
import GeoFire
import FirebaseFirestore
import Firebase

struct GeoFireScripts: View {
    @State var restaurants: [Restaurant] = []
    
    var body: some View {
        VStack{
            Button{setupGeofire()}
        label: {Text("Put in geofire")}
            //
            Button{Task{try await fetchLocation()}}
        label: {Text("fetch All Restaurants")}
            
            //
            
        }
    }
    func setupGeofire() {
        for restaurant in restaurants {
            if let coordinates = restaurant.coordinates {
                let hash = GFUtils.geoHash(forLocation: coordinates)
                let documentData: [String: Any] = [
                    "geoHash": hash
                ]
                let restaurantRef = FirestoreConstants.RestaurantCollection.document(restaurant.id)
                restaurantRef.setData(documentData, merge: true) { error in
                    if let error = error {
                        print("Error updating geohash for restaurant \(restaurant.id): \(error.localizedDescription)")
                    } else {
                        print("Geohash updated successfully for restaurant \(restaurant.id)")
                    }
                }
            }
        }
    }
    func fetchLocation() async throws -> [Restaurant] {
            let center = CLLocationCoordinate2D(latitude: 34.02838036237139, longitude: -118.48004444947522)
            let radiusInM: Double = 1 * 1000
            let queryBounds = GFUtils.queryBounds(forLocation: center, withRadius: radiusInM)
            let queries = queryBounds.map { bound -> Query in
                return FirestoreConstants.RestaurantCollection
                    .order(by: "geoHash")
                    .start(at: [bound.startValue])
                    .end(at: [bound.endValue])
                    .whereField("cuisine", in: ["Coffee & Tea"])
            }
            
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
                print(matchingDocs)
                return matchingDocs
            } catch {
                throw error
            }
        }
    func fetchAllRestaurants() {
        Task{
            print("Running Fetch Restaurants")
            restaurants = try await RestaurantService.shared.fetchRestaurants()
            print("Finished Running Fetch Restaurants")
            print(restaurants.count)
        }
    }
    func deleteOld() async {
        for restaurant in restaurants {
            let restaurantRef = FirestoreConstants.RestaurantCollection.document(restaurant.id)
            restaurantRef.updateData(["geohash": FieldValue.delete()]) { error in
                if let error = error {
                    print("Error deleting geohash for restaurant \(restaurant.id): \(error.localizedDescription)")
                } else {
                    print("Geohash deleted successfully for restaurant \(restaurant.id)")
                }
            }
        }
    }
}
    
#Preview {
    GeoFireScripts()
}

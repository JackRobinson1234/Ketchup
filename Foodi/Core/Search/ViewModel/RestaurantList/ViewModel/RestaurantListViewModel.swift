//
//  RestaurantListViewModel.swift
//  Foodi
//
//  Created by Jack Robinson on 2/1/24.
//

// Restaurant Map also grabs from this

import Foundation
import Firebase

@MainActor
class RestaurantListViewModel: ObservableObject {
    @Published var restaurants = [Restaurant]()
    private var restaurantLastDoc: QueryDocumentSnapshot?
    private var restaurantService: RestaurantService = RestaurantService()
    init(restaurantService: RestaurantService) {
        self.restaurantService = restaurantService
        Task {await fetchRestaurants()}
    }
    
    
    
    func fetchRestaurants() async {
        let query = FirestoreConstants.RestaurantCollection.limit(to: 20)
        
        
        if let last = restaurantLastDoc {
            let next = query.start(afterDocument: last)
            guard let snapshot = try? await next.getDocuments() else { return }
            self.restaurantLastDoc = snapshot.documents.last
            
            for document in snapshot.documents {
                if let restaurant = try? document.data(as: Restaurant.self) {
                    print("DEBUG: Successfully fetched restaurants")
                    self.restaurants.append(restaurant)
                } else {
                    print("DEBUG: Error converting document to Restaurant")
                }
            }
            
            print("DEBUG: Successfully fetched \(snapshot.documents.count) more restaurants.")
        } else {
            guard let snapshot = try? await query.getDocuments() else { return }
            self.restaurantLastDoc = snapshot.documents.last
            
            for document in snapshot.documents {
                if let restaurant = try? document.data(as: Restaurant.self) {
                    print("DEBUG: Successfully fetched restaurants")
                    self.restaurants.append(restaurant)
                } else {
                    print("DEBUG: Error converting document to Restaurant")
                }
            }
            
            print("DEBUG: Successfully fetched \(snapshot.documents.count) restaurants.")
            }
        }
        /*private func fetchRestaurants(_ snapshot: QuerySnapshot?) async throws {
            guard let documents = snapshot?.documents else { return }
            
            for doc in documents {
                let restaurant = try await restaurantService.fetchRestaurant(withId: doc.documentID)
                restaurants.append(restaurant)
            }
        }*/
        func filteredRestaurants(_ query: String) -> [Restaurant] {
            let lowercasedQuery = query.lowercased()
            return restaurants.filter({
                $0.name.lowercased().contains(lowercasedQuery) ||
                $0.name.contains(lowercasedQuery)
            })
        }
}

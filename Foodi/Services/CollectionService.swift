//
//  CollectionService.swift
//  Foodi
//
//  Created by Jack Robinson on 4/15/24.
//

import Foundation
import Firebase
import MapKit
import GeoFire
import FirebaseFirestoreInternal
class CollectionService {
    private var collections = [Collection]()
    func fetchCollections(user: String) async throws -> [Collection] {
        //print("DEBUG: Ran fetchUserPost")
        self.collections = try await FirestoreConstants
            .CollectionsCollection
            .whereField("uid", isEqualTo: user)
            .getDocuments(as: Collection.self)
        return collections
    }
}

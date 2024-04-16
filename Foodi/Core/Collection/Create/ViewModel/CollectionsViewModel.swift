//
//  ProfileCollectionsViewModel.swift
//  Foodi
//
//  Created by Jack Robinson on 4/15/24.
//

import Foundation
class CollectionsViewModel: ObservableObject {
    @Published var collections = [Collection]()
    private let collectionService: CollectionService = CollectionService()
    
    func fetchCollections(user: String) async {
        do {
            self.collections = try await collectionService.fetchCollections(user: user)
        } catch {
            print("DEBUG: Failed to fetch posts with error: \(error.localizedDescription)")
        }
    }
}

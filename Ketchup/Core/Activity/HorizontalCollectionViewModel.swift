//
//  HorizontalCollectionViewModel.swift
//  Ketchup
//
//  Created by Jack Robinson on 7/13/24.
//

import Foundation
import FirebaseFirestoreInternal
@MainActor
class HorizontalCollectionViewModel: ObservableObject {
    @Published var collections: [Collection] = []
    @Published var isLoading = false
    private var lastDocument: QueryDocumentSnapshot?
    private let limit = 10
    private var hasMoreCollections = true
    private var currentTask: Task<Void, Never>?
    
    func loadInitialCollections() {
        guard collections.isEmpty else { return }
        loadMore()
    }
    
    func loadMore() {
        guard !isLoading, hasMoreCollections else { return }
        
        currentTask?.cancel()
        currentTask = Task { @MainActor in
            do {
                isLoading = true
                print("Starting to fetch collections")
                
                let (newCollections, lastDoc) = try await CollectionService.shared.fetchPaginatedCollections(
                    lastDocument: lastDocument,
                    limit: limit
                )
                
                collections.append(contentsOf: newCollections)
                lastDocument = lastDoc
                hasMoreCollections = newCollections.count == limit
                print("Fetched \(newCollections.count) collections. Total: \(collections.count)")
            } catch {
                print("Error loading collections: \(error)")
            }
            isLoading = false
        }
    }
}

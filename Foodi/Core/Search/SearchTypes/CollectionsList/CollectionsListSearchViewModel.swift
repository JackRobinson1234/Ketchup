//
//  CollectionsListSearchViewModel.swift
//  Foodi
//
//  Created by Jack Robinson on 4/22/24.
//

import InstantSearch
import InstantSearchCore
import InstantSearchSwiftUI
import Foundation
import SwiftUI

final class CollectionListSearchViewModel: ObservableObject {
    @Published var searchQuery: String {
        didSet {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.notifyQueryChanged()
            }
        }
    }
    @Published var hits: PaginatedDataViewModel<AlgoliaHitsPage<Hit<Collection>>>
    private var itemsSearcher: HitsSearcher
    
    init() {
        let appID: ApplicationID = "74A8XPTT50"
        let apiKey: APIKey = "d7d6db8cc90a900cd8fa87fb302b3448"
        let itemsSearcher = HitsSearcher(appID: appID,
                                         apiKey: apiKey,
                                         indexName: "collections")
        self.itemsSearcher = itemsSearcher
        self.itemsSearcher.shouldTriggerSearchForQuery = {
            return $0.query.query != ""
        }
        self.searchQuery = ""
        self.hits =  itemsSearcher.paginatedData(of: Hit<Collection>.self)
        
    }
    
    private func notifyQueryChanged() {
            if !searchQuery.isEmpty {
                itemsSearcher.request.query.query = searchQuery
                itemsSearcher.search()
        }
    }
}

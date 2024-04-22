//
//  UserListViewModel.swift
//  Foodi
//
//  Created by Jack Robinson on 2/1/24.
//

import InstantSearch
import InstantSearchCore
import InstantSearchSwiftUI
import Foundation
import SwiftUI

final class UserListViewModel: ObservableObject {
    @Published var searchQuery: String {
        didSet {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.notifyQueryChanged()
            }
        }
    }
    var hits: PaginatedDataViewModel<AlgoliaHitsPage<Hit<User>>>
    private var itemsSearcher: HitsSearcher
    
    init() {
        let appID: ApplicationID = "74A8XPTT50"
        let apiKey: APIKey = "d7d6db8cc90a900cd8fa87fb302b3448"
        let itemsSearcher = HitsSearcher(appID: appID,
                                         apiKey: apiKey,
                                         indexName: "users")
        self.itemsSearcher = itemsSearcher
        self.itemsSearcher.shouldTriggerSearchForQuery = {
            return $0.query.query != ""
        }
        self.searchQuery = ""
        self.hits =  itemsSearcher.paginatedData(of: Hit<User>.self)
    }
    
    private func notifyQueryChanged() {
            if !searchQuery.isEmpty {
                itemsSearcher.request.query.query = searchQuery
                itemsSearcher.search()
        }
    }
}

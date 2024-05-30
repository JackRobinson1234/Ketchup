//
//  PostListViewModel.swift
//  Foodi
//
//  Created by Jack Robinson on 2/1/24.
//

import InstantSearch
import InstantSearchCore
import InstantSearchSwiftUI
import Foundation
import SwiftUI

final class PostListViewModel: ObservableObject {
    @Published var searchQuery: String = ""
    var hits: PaginatedDataViewModel<AlgoliaHitsPage<Hit<Post>>>
    private var itemsSearcher: HitsSearcher
    private var filterState = FilterState()
    
    
    init() {
        let appID: ApplicationID = "74A8XPTT50"
        let apiKey: APIKey = "d7d6db8cc90a900cd8fa87fb302b3448"
        self.itemsSearcher = HitsSearcher(appID: appID,
                                          apiKey: apiKey,
                                          indexName: "posts")
        let atHomeFilter = Filter.Facet(attribute: "postType", stringValue: "1")
        let privateFilter = Filter.Facet(attribute: "user.privateMode", boolValue: false)
        self.filterState[and: "postType"].add(atHomeFilter)
        self.filterState[and: "user.privateMode"].add(privateFilter)
        ///If we dont want empty text search enabled
        /*self.itemsSearcher.shouldTriggerSearchForQuery = {
         return $0.query.query != ""
         }*/
        self.itemsSearcher.connectFilterState(filterState)
        self.searchQuery = ""
        self.hits =  itemsSearcher.paginatedData(of: Hit<Post>.self)
    }
    
    //MARK: notifyQueryChanged
    /// When the text changes, checks for filters, updates the searcher with the filters and search query, then searches
    func notifyQueryChanged() {
        itemsSearcher.request.query.query = searchQuery
        itemsSearcher.search()
    }
}

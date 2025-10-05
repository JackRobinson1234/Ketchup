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
    
    @Published var searchQuery: String = ""
    @Published var hits: PaginatedDataViewModel<AlgoliaHitsPage<Hit<Collection>>>
    private var itemsSearcher: HitsSearcher
    private var filterState = FilterState()
    
    init() {
        let appID: ApplicationID = ""
        let apiKey: APIKey = ""
        let itemsSearcher = HitsSearcher(appID: appID,
                                         apiKey: apiKey,
                                         indexName: "collections")
        self.itemsSearcher = itemsSearcher
        let privateFilter = Filter.Facet(attribute: "privateMode", boolValue: false)
        self.filterState[and: "user.privateMode"].add(privateFilter)
        /*self.itemsSearcher.shouldTriggerSearchForQuery = {
            return $0.query.query != ""
        }*/
        self.itemsSearcher.connectFilterState(filterState)
        self.searchQuery = ""
        self.hits =  itemsSearcher.paginatedData(of: Hit<Collection>.self)
        
    }
    
    func notifyQueryChanged() {
            //if !searchQuery.isEmpty {
                itemsSearcher.request.query.query = searchQuery
                itemsSearcher.search()
        //}
    }
}

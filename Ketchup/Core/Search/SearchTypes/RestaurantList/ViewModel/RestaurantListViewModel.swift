//
//  RestaurantListViewModel.swift
//  Foodi
//
//  Created by Jack Robinson on 2/1/24.
//

// Restaurant Map also grabs from this

import InstantSearch
import InstantSearchCore
import InstantSearchSwiftUI
import Foundation
import SwiftUI
import Combine


import Firebase

//@MainActor
final class RestaurantListViewModel: ObservableObject {
    @Published var searchQuery: String = ""
    var hits: PaginatedDataViewModel<AlgoliaHitsPage<Hit<Restaurant>>>
    private var itemsSearcher: HitsSearcher
    
    init() {
        let appID: ApplicationID = "74A8XPTT50"
        let apiKey: APIKey = "d7d6db8cc90a900cd8fa87fb302b3448"
        let itemsSearcher = HitsSearcher(appID: appID,
                                         apiKey: apiKey,
                                         indexName: "restaurants")
        self.itemsSearcher = itemsSearcher
        /*self.itemsSearcher.shouldTriggerSearchForQuery = {
            return $0.query.query != ""
        }*/
        self.searchQuery = ""
        self.hits =  itemsSearcher.paginatedData(of: Hit<Restaurant>.self)
    }
    
    func notifyQueryChanged() {
            //if !searchQuery.isEmpty {
                itemsSearcher.request.query.query = searchQuery
                itemsSearcher.search()
        //}
    }
}

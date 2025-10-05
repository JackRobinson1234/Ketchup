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

final class RestaurantListViewModel: ObservableObject {
    @Published var searchQuery: String = ""
    var hits: PaginatedDataViewModel<AlgoliaHitsPage<Hit<Restaurant>>>
    private var itemsSearcher: HitsSearcher
    
    init() {
        let appID: ApplicationID = ""
        let apiKey: APIKey = ""
        let itemsSearcher = HitsSearcher(appID: appID,
                                         apiKey: apiKey,
                                         indexName: "restaurants7")
        self.itemsSearcher = itemsSearcher
        self.searchQuery = ""
        self.hits =  itemsSearcher.paginatedData(of: Hit<Restaurant>.self)
    }
    
    func notifyQueryChanged() {
        itemsSearcher.request.query.query = searchQuery
        itemsSearcher.search()
    }
}

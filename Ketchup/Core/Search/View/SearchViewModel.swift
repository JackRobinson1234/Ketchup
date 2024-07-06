//
//  SearchViewModel.swift
//  Ketchup
//
//  Created by Jack Robinson on 6/24/24.
//

import InstantSearch
import InstantSearchCore
import InstantSearchSwiftUI
import Foundation
import SwiftUI

final class SearchViewModel: ObservableObject {
    @Published var searchConfig: SearchModelConfig = .restaurants
    @Published var searchQuery: String = ""
    @Published var collectionHits: PaginatedDataViewModel<AlgoliaHitsPage<Hit<Collection>>>
    @Published var userHits: PaginatedDataViewModel<AlgoliaHitsPage<Hit<User>>>
    @Published var restaurantHits: PaginatedDataViewModel<AlgoliaHitsPage<Hit<Restaurant>>>
    private var restaurantItemsSearcher: HitsSearcher
    private var collectionsItemsSearcher: HitsSearcher
    private var usersItemsSearcher: HitsSearcher
    private var filterState = FilterState()
    let appID: ApplicationID = "74A8XPTT50"
    let apiKey: APIKey = "d7d6db8cc90a900cd8fa87fb302b3448"
    
    init() {
        
        
        self.restaurantItemsSearcher = HitsSearcher(appID: appID,
                                                    apiKey: apiKey,
                                                    indexName: "restaurants")
        self.collectionsItemsSearcher = HitsSearcher(appID: appID,
                                                     apiKey: apiKey,
                                                     indexName: "collections")
        self.usersItemsSearcher = HitsSearcher(appID: appID,
                                               apiKey: apiKey,
                                               indexName: "users")
        
        
        let privateFilter = Filter.Facet(attribute: "privateMode", boolValue: false)
        self.filterState[and: "user.privateMode"].add(privateFilter)
        self.collectionsItemsSearcher.connectFilterState(filterState)
        self.searchQuery = ""
        self.collectionHits =  collectionsItemsSearcher.paginatedData(of: Hit<Collection>.self)
        self.userHits =  usersItemsSearcher.paginatedData(of: Hit<User>.self)
        self.restaurantHits =  restaurantItemsSearcher.paginatedData(of: Hit<Restaurant>.self)
        
    }
    
    func notifyQueryChanged() {
        //if !searchQuery.isEmpty {
        switch searchConfig{
        case .users:
            usersItemsSearcher.request.query.query = searchQuery
            usersItemsSearcher.search()
        case .restaurants:
            restaurantItemsSearcher.request.query.query = searchQuery
            restaurantItemsSearcher.search()
        case .collections:
            collectionsItemsSearcher.request.query.query = searchQuery
            collectionsItemsSearcher.search()
            
        }
    }
}

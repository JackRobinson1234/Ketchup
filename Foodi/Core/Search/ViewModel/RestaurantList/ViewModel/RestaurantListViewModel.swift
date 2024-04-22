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
import AlgoliaSearchClient
import InstantSearchInsights
import Foundation
import SwiftUI

import Firebase

//@MainActor
final class RestaurantListViewModel: ObservableObject {
    @Published var searchQuery: String {
        didSet {
            notifyQueryChanged()
        }
    }
    
    @Published var suggestions: [QuerySuggestion]
    
    var hits: PaginatedDataViewModel<AlgoliaHitsPage<Hit<Restaurant>>>
    
    private var itemsSearcher: HitsSearcher
    
    private var suggestionsSearcher: HitsSearcher
    @State var didSubmitSuggestion = false
    
    init() {
        let appID: ApplicationID = "latency"
        let apiKey: APIKey = "af044fb0788d6bb15f807e4420592bc5"
        let itemsSearcher = HitsSearcher(appID: appID,
                                         apiKey: apiKey,
                                         indexName: "instant_search")
        self.itemsSearcher = itemsSearcher
        self.suggestionsSearcher = HitsSearcher(appID: appID,
                                                apiKey: apiKey,
                                                indexName: "query_suggestions")
        self.hits = itemsSearcher.paginatedData(of: Hit<Restaurant>.self)
        searchQuery = ""
        suggestions = []
        suggestionsSearcher.onResults.subscribe(with: self) { _, response in
            do {
                self.suggestions = try response.extractHits()
            } catch _ {
                self.suggestions = []
            }
        }.onQueue(.main)
        suggestionsSearcher.search()
    }
    
    deinit {
        suggestionsSearcher.onResults.cancelSubscription(for: self)
    }
    func submitSearch() {
        suggestions = []
        itemsSearcher.request.query.query = searchQuery
        itemsSearcher.search()
    }
    private func notifyQueryChanged() {
        if didSubmitSuggestion {
            didSubmitSuggestion = false
            submitSearch()
        } else {
            suggestionsSearcher.request.query.query = searchQuery
            itemsSearcher.request.query.query = searchQuery
            suggestionsSearcher.search()
            itemsSearcher.search()
        }
    }
    func completeSuggestion(_ suggestion: String) {
        searchQuery = suggestion
    }
    
    func submitSuggestion(_ suggestion: String) {
        didSubmitSuggestion = true
        searchQuery = suggestion
    }
}

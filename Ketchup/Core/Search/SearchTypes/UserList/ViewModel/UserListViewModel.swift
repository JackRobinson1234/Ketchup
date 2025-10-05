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
    @Published var searchQuery: String = ""
        
    var hits: PaginatedDataViewModel<AlgoliaHitsPage<Hit<User>>>
    private var itemsSearcher: HitsSearcher
    
    init() {
        let appID: ApplicationID = ""
        let apiKey: APIKey = ""
        let itemsSearcher = HitsSearcher(appID: appID,
                                         apiKey: apiKey,
                                         indexName: "users")
        self.itemsSearcher = itemsSearcher
        /*self.itemsSearcher.shouldTriggerSearchForQuery = {
            return $0.query.query != ""
        }*/
        self.searchQuery = ""
        self.hits =  itemsSearcher.paginatedData(of: Hit<User>.self)
    }
    
    func notifyQueryChanged() {
        //if !searchQuery.isEmpty {
                itemsSearcher.request.query.query = searchQuery
                itemsSearcher.search()
        //}
    }
}

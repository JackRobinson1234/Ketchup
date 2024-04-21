//
//  AlgoliaController.swift
//  Foodi
//
//  Created by Jack Robinson on 4/21/24.
//
import InstantSearch
import InstantSearchCore
import InstantSearchSwiftUI
import AlgoliaSearchClient
import InstantSearchInsights
import Foundation
import SwiftUI

class RestaurantAlgoliaController {
  
  let searcher: HitsSearcher

  let searchBoxInteractor: SearchBoxInteractor
  let searchBoxController: SearchBoxObservableController

  let hitsInteractor: HitsInteractor<Restaurant>
  let hitsController: HitsObservableController<Restaurant>
  
  init() {
    self.searcher = HitsSearcher(appID: "latency",
                                 apiKey: "1f6fd3a6fb973cb08419fe7d288fa4db",
                                 indexName: "bestbuy")
    self.searchBoxInteractor = .init()
    self.searchBoxController = .init()
    self.hitsInteractor = .init()
    self.hitsController = .init()
    setupConnections()
  }
  
  func setupConnections() {
    searchBoxInteractor.connectSearcher(searcher)
    searchBoxInteractor.connectController(searchBoxController)
    hitsInteractor.connectSearcher(searcher)
    hitsInteractor.connectController(hitsController)
  }
      
}

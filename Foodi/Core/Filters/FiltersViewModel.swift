//
//  FiltersViewModel.swift
//  Foodi
//
//  Created by Jack Robinson on 4/1/24.
//
import Foundation
import SwiftUI

class FiltersViewModel: ObservableObject {
    @ObservedObject var feedViewModel: FeedViewModel
    @Published var selectedCuisines: [String] = []
    var filters: [String: [Any]] = [:]
    
    init(feedViewModel: FeedViewModel) {
            self.feedViewModel = feedViewModel
        }

    /// fetches filtered from firebase and preloads the next 3 posts in the cache based on the current filters
    func fetchFilteredPosts() async {
        if selectedCuisines.isEmpty {
            filters.removeValue(forKey: "recipe.cuisine")
        } else {
            filters["recipe.cuisine"] = selectedCuisines
        }
        print("DEBUG: \(filters)")
        await feedViewModel.fetchPosts(withFilters: self.filters)
    }
}

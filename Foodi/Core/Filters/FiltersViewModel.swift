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
    init(feedViewModel: FeedViewModel) {
            self.feedViewModel = feedViewModel
        }

    /// fetches filtered from firebase and preloads the next 3 posts in the cache, pass in an array of [filter: filtered query] ex: ["cuisine" : "Chinese"]
    func fetchFilteredPosts(filters: [String: Any]) async {
        print("DEBUG: Fetching filtered posts from feedviewmodel")
        await feedViewModel.fetchPosts(withFilters: filters)
    }
}

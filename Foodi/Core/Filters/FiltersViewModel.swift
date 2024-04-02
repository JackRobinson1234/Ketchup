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

    /// fetches all posts from firebase and preloads the next 3 posts in the cache
    func fetchFilteredPosts(filters: [String: Any]) async {
        print("DEBUG: Fetching filtered posts from feedviewmodel")
        await feedViewModel.fetchPosts(withFilters: filters)
    }
}

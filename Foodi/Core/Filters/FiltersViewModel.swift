//
//  FiltersViewModel.swift
//  Foodi
//
//  Created by Jack Robinson on 4/1/24.
//

import Foundation
class FiltersViewModel: ObservableObject {
    
    /// fetches all posts from firebase and preloads the next 3 posts in the cache
    func fetchFilterdPosts() async {
        print("DEBUG: Fetching filtered posts from feedviewmodel")
        fetchPosts
           

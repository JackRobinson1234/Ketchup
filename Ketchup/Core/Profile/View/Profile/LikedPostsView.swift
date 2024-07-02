//
//  LikedPostsView.swift
//  Foodi
//
//  Created by Jack Robinson on 2/26/24.
//

import SwiftUI

struct LikedPostsView: View {
    @ObservedObject var viewModel: ProfileViewModel
    @State var isLoading = true
    
    
    var body: some View {
        if isLoading {
            // Loading screen
            ProgressView("Loading...")
                .onAppear {
                    Task {
                        try await viewModel.fetchUserLikedPosts()
                        isLoading = false
                    }
                }
        } else {
            PostGridView(posts: viewModel.likedPosts, feedTitleText: "Posts Liked by @\(viewModel.user.username)", viewModel: viewModel.feedViewModel)
        }
    }
}


//
//  LikedPostsView.swift
//  Foodi
//
//  Created by Jack Robinson on 2/26/24.
//

import SwiftUI

struct LikedPostsView: View {
    @StateObject var viewModel: LikedVideosViewModel
    private let user: User
    @State var isLoading = true
    
    init(user: User) {
        self.user = user
        let viewModel = LikedVideosViewModel(user: user)
        self._viewModel = StateObject(wrappedValue: viewModel)
    }
    var body: some View {
        if isLoading {
            // Loading screen
            ProgressView("Loading...")
                .onAppear {
                    Task {
                        await viewModel.fetchUserLikedPosts()
                        isLoading = false
                    }
                }
        } else {
            PostGridView(posts: viewModel.posts)
        }
    }
}


//
//  LikedPostsView.swift
//  Foodi
//
//  Created by Jack Robinson on 2/26/24.
//

import SwiftUI

struct LikedPostsView: View {
    @StateObject var viewModel: LikedVideosViewModel
    private let userService: UserService
    private let postService: PostService
    private let user: User
    @State var isLoading = true
    
    init(user: User, userService: UserService, postService: PostService) {
        self.user = user
        self.userService = userService
        self.postService = postService
        let viewModel = LikedVideosViewModel(user: user, userService: UserService(), postService: PostService())
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
            PostGridView(posts: viewModel.posts, userService: userService)
        }
    }
}


//
//  PostGridView.swift
//  Foodi
//
//  Created by Jack Robinson on 2/1/24.
//

import SwiftUI
import Kingfisher
import AVKit

struct PostGridView: View {
    @ObservedObject var viewModel: ProfileViewModel
    @State private var player = AVPlayer()
    @State private var selectedPost: Post?
    private let userService: UserService
    private let items = [
        GridItem(.flexible(), spacing: 1),
        GridItem(.flexible(), spacing: 1),
        GridItem(.flexible(), spacing: 1),
    ]
    private let width = (UIScreen.main.bounds.width / 3) - 2
    init(viewModel: ProfileViewModel, userService: UserService) {
        self.viewModel = viewModel
        self.userService = userService
    }
    var body: some View {
        LazyVGrid(columns: items, spacing: 2) {
            ForEach(viewModel.posts) { post in
                KFImage(URL(string: post.thumbnailUrl))
                    .resizable()
                    .scaledToFill()
                    .frame(width: width, height: 160)
                    .clipped()
                    .onTapGesture { selectedPost = post }
            }
        }
        .sheet(item: $selectedPost) { post in
            FeedView(player: $player, posts: [post], userService: userService)
                .onDisappear {
                    player.replaceCurrentItem(with: nil)
                }
        }
    }
}

#Preview {
    PostGridView(viewModel: ProfileViewModel(
        user: DeveloperPreview.user,
        userService: UserService(),
        postService: PostService()
    ), userService: UserService()
    )
}

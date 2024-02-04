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
    var viewModel: any PostGridViewModelProtocol
    @State private var player = AVPlayer()
    @State private var selectedPost: Post?
    private let userService: UserService
    private let items = [
        GridItem(.flexible(), spacing: 1),
        GridItem(.flexible(), spacing: 1),
        GridItem(.flexible(), spacing: 1),
    ]
    private let width = (UIScreen.main.bounds.width / 3) - 2
    init(viewModel: any PostGridViewModelProtocol, userService: UserService) {
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
                    .overlay(
                        VStack{
                            HStack{
                                VStack (alignment: .leading) {
                                    Text("\(post.restaurant!.name)")
                                        .lineLimit(1)
                                        .truncationMode(.tail)
                                        .foregroundColor(.white)
                                        .font(.caption)
                                        .bold()
                                    Text("\(post.user!.username)")
                                        .lineLimit(1)
                                        .truncationMode(.tail)
                                        .foregroundColor(.white)
                                        .font(.caption)
                                }
                                .background(Color.black.opacity(0.1))
                                Spacer()
                            }
                            
                            Spacer()
                            HStack {
                                Spacer()
                                HStack(spacing: 2) {
                                    Text("\(post.likes)")
                                        .padding(4)
                                        .foregroundColor(.white)
                                        .cornerRadius(4)
                                        .bold()
                                        .background(Color.black.opacity(0.1))
                                    Image(systemName: "heart.fill")
                                        .resizable()
                                        .frame(width: 14, height: 14)
                                        .foregroundColor(.white)
                                }
                            }
                        }
                        .padding([.bottom, .trailing], 4)
                    )
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

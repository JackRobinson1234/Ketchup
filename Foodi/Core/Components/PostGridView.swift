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
        if !viewModel.posts.isEmpty{
            LazyVGrid(columns: items, spacing: 2) {
                ForEach(viewModel.posts) { post in
                    KFImage(URL(string: post.thumbnailUrl))
                        .resizable()
                        .scaledToFill()
                        .frame(width: width, height: 160)
                        .clipped()
                        .onTapGesture { selectedPost = post}
                        .overlay(
                            VStack{
                                HStack{
                                    VStack (alignment: .leading) {
                                        Text("\(post.restaurant?.name ?? "")")
                                            .lineLimit(1)
                                            .truncationMode(.tail)
                                            .foregroundColor(.white)
                                            .font(.footnote)
                                            .bold()
                                        
                                    }
                                    
                                    Spacer()
                                }
                                
                                Spacer()
                                HStack {
                                    
                                    Spacer()
                                    
                                    Text("\(post.likes)")
                                        .foregroundColor(.white)
                                        .font(.footnote)
                                    
                                }
                                
                            }
                                .padding(4)
                                .background(LinearGradient(gradient: Gradient(colors: [.black.opacity(0.3), .clear, .clear, .black.opacity(0.3)]),
                                                           startPoint: .top,
                                                           endPoint: .bottom))
                                .onTapGesture { selectedPost = post }
                        )
                }
            }
            
            .sheet(item: $selectedPost) { post in
                FeedView(player: $player, posts: [post], userService: userService)
                    .onDisappear {
                        player.replaceCurrentItem(with: nil)
                    }
            }
        } else {
            Text("No Posts to Show")
                .foregroundStyle(.gray)
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

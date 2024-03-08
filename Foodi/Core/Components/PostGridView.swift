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
    //var viewModel: any PostGridViewModelProtocol
    @State private var player = AVPlayer()
    @State private var selectedPost: Post?
    private let userService: UserService
    private let items = [
        GridItem(.flexible(), spacing: 1),
        GridItem(.flexible(), spacing: 1),
        GridItem(.flexible(), spacing: 1),
    ]
    private let posts: [Post]?
    private let width = (UIScreen.main.bounds.width / 3) - 2
    init(posts: [Post]?, userService: UserService) {
        //self.viewModel = viewModel
        self.userService = userService
        self.posts = posts
    }
    
    var body: some View {
        if let unwrappedPosts = posts {
            if !unwrappedPosts.isEmpty{
                LazyVGrid(columns: items, spacing: 2) {
                    ForEach(unwrappedPosts) { post in
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
                                            if let restaurant = post.restaurant {
                                                Text("\(restaurant.name)")
                                                    .lineLimit(2)
                                                    .truncationMode(.tail)
                                                    .foregroundColor(.white)
                                                    .font(.footnote)
                                                    .bold()
                                            }
                                            else if let recipe = post.recipe {
                                                Text("\(recipe.name)")
                                                    .lineLimit(2)
                                                    .truncationMode(.tail)
                                                    .foregroundColor(.white)
                                                    .font(.footnote)
                                                    .bold()
                                            } else if let brand = post.brand {
                                                Text("\(brand.name)")
                                                    .lineLimit(2)
                                                    .truncationMode(.tail)
                                                    .foregroundColor(.white)
                                                    .font(.footnote)
                                                    .bold()
                                            }
                                        }
                                        
                                        Spacer()
                                    }
                                    
                                    Spacer()
                                    HStack {
                                        /*
                                        if post.restaurant != nil {
                                            Image(systemName: "building.2.crop.circle.fill")
                                                .font(.footnote)
                                                .foregroundColor(.white)
                                        } else if post.recipe != nil {
                                            Image(systemName: "fork.knife.circle")
                                                .font(.footnote)
                                                .foregroundColor(.white)
                                        }*/
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
            }
        } else {
            Text("No Posts to Show")
                .foregroundStyle(.gray)
        }
    }
}

#Preview {
    PostGridView(posts: DeveloperPreview.posts, userService: UserService())
}

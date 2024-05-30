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
    //@State private var player = AVPlayer()
    @State private var selectedPost: Post?
    
    private let posts: [Post]?
    
    private let spacing: CGFloat = 8
    private var width: CGFloat {
            (UIScreen.main.bounds.width - (spacing * 2)) / 3
        }
    let cornerRadius: CGFloat = 5
    
    private var items: [GridItem] {
           [
               GridItem(.flexible(), spacing:  2),
               GridItem(.flexible(), spacing:  2),
               GridItem(.flexible(), spacing:  2),
           ]
       }
    init(posts: [Post]?) {
        self.posts = posts
    }
    
    var body: some View {
        if let unwrappedPosts = posts {
            if !unwrappedPosts.isEmpty{
                LazyVGrid(columns: items, spacing: spacing/2) {
                    ForEach(unwrappedPosts) { post in
                        KFImage(URL(string: post.thumbnailUrl))
                            .resizable()
                            .scaledToFill()
                            .frame(width: width, height: 160)
                            .cornerRadius(cornerRadius)
                            .clipped()
                            .onTapGesture { selectedPost = post}
                            .overlay(
                                VStack(alignment: .leading){
                                    HStack {
                                        if post.restaurant != nil {
                                            Image(systemName: "storefront.fill")
                                                .foregroundStyle(.white)
                                                .font(.caption)
                                            
                                        }  else if post.recipe != nil {
                                            Image(systemName: "frying.pan.fill")
                                                .foregroundStyle(.white)
                                                .font(.caption)
                                        }
                                        Spacer()
                                        if post.repost{
                                                Image(systemName: "arrow.2.squarepath")
                                                    .foregroundStyle(.white)
                                                    .font(.caption)
                                            }
                                    }
                                    
                                    Spacer()
                                    HStack{
                                        VStack (alignment: .leading) {
                                            if let restaurant = post.restaurant {
                                                Text("\(restaurant.name)")
                                                    .lineLimit(2)
                                                    .truncationMode(.tail)
                                                    .foregroundColor(.white)
                                                    .font(.footnote)
                                                    .bold()
                                                    .shadow(color: .black, radius: 2, x: 0, y: 1)
                                            }
                                            else if let recipe = post.recipe {
                                                Text("\(recipe.name)")
                                                    .lineLimit(2)
                                                    .truncationMode(.tail)
                                                    .foregroundColor(.white)
                                                    .font(.footnote)
                                                    .bold()
                                                    .shadow(color: .black, radius: 2, x: 0, y: 1)
                                            }
                                        }
                                        
                                        Spacer()
                                    }
                                    
                                }
                                    .padding(4)
//                                    .background(LinearGradient(gradient: Gradient(colors: [.black.opacity(0.3), .clear, .clear, .black.opacity(0.3)]),
//                                                               startPoint: .top,
//                                                               endPoint: .bottom))
                                    .onTapGesture { selectedPost = post }
                            )
                    }
                }
                .padding(spacing/2)
                .sheet(item: $selectedPost) { post in
                    FeedView(videoCoordinator: VideoPlayerCoordinator(), posts: [post], hideFeedOptions: true)
                        .onDisappear {
                            //player.replaceCurrentItem(with: nil)
                        }
                }
            }
            else {
                Text("No Posts to Show")
                    .foregroundStyle(.gray)
                    .font(.subheadline)
            }
        }
    }
}

#Preview {
    PostGridView(posts: DeveloperPreview.posts)
}

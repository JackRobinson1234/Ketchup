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
                                            
                                        }  else if post.cookingTitle != nil {
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
                                            else if let recipe = post.cookingTitle{
                                                Text("\(recipe)")
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
                                    .onTapGesture { selectedPost = post }
                            )
                    }
                }
                .padding(spacing/2)
                .fullScreenCover(item: $selectedPost) { post in
                    if let posts = posts{
                        FeedView(videoCoordinator: VideoPlayerCoordinator(), posts: posts, hideFeedOptions: true, startingPostId: post.id, initialScrollPosition: post.id)
                    }
                }
            }
            else {
                HStack{
                    Spacer()
                    Text("No Posts to Show")
                        .foregroundStyle(.gray)
                        .font(.subheadline)
                    Spacer()
                }
                .padding()
            }
        }
    }
}

#Preview {
    PostGridView(posts: DeveloperPreview.posts)
}

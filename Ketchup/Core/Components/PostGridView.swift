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
    @ObservedObject var viewModel: FeedViewModel
    @State private var selectedPost: Post?
    @Environment(\.dismiss) var dismiss
    private let posts: [Post]?
    private let feedTitleText: String?
    
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
    init(posts: [Post]?, feedTitleText: String?, viewModel: FeedViewModel) {
        self.posts = posts
        self.feedTitleText = feedTitleText
        self.viewModel = viewModel
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
                            .onTapGesture {
                                if let posts {
                                    viewModel.posts = posts
                                    selectedPost = post
                                }
                            }
                            .overlay(
                                VStack(alignment: .leading){
                                    HStack {
                                        Spacer()
                                        if post.repost{
                                            Image(systemName: "arrow.2.squarepath")
                                                .foregroundStyle(.white)
                                                .font(.custom("MuseoSansRounded-300", size: 16))
                                        }
                                    }
                                    
                                    Spacer()
                                    HStack{
                                        VStack (alignment: .leading) {
                                            
                                            Text("\(post.restaurant.name)")
                                                    .lineLimit(2)
                                                    .truncationMode(.tail)
                                                    .foregroundColor(.white)
                                                    .font(.custom("MuseoSansRounded-300", size: 10))
                                                    .bold()
                                                    .shadow(color: .black, radius: 2, x: 0, y: 1)
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
                    NavigationStack {
                        SecondaryFeedView(viewModel: viewModel, hideFeedOptions: false, initialScrollPosition: post.id, titleText: ("Discover"))
                        
                    }
                }
            }
            else {
                HStack{
                    Spacer()
                    Text("No Posts to Show")
                        .foregroundStyle(.gray)
                        .font(.custom("MuseoSansRounded-300", size: 16))
                    Spacer()
                }
                .padding()
            }
        }
    }
}
//
//#Preview {
//    PostGridView(posts: DeveloperPreview.posts, feedTitleText: nil)
//}

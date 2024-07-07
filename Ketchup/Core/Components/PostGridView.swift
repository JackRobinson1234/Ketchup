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
    @StateObject var viewModel = FeedViewModel()
    @State private var selectedPost: Post?
    @Environment(\.dismiss) var dismiss
    private let posts: [Post]?
    private let feedTitleText: String?
    private let showNames: Bool
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
    init(posts: [Post]?, feedTitleText: String?, showNames: Bool) {
        self.posts = posts
        self.feedTitleText = feedTitleText
        self.showNames = showNames
    }
    
    var body: some View {
        if let unwrappedPosts = posts?.filter({ $0.mediaType != .written }) {
            if !unwrappedPosts.isEmpty{
                LazyVGrid(columns: items, spacing: spacing/2) {
                    ForEach(unwrappedPosts) { post in
                        Button{
                            if let posts {
                                viewModel.startingPostId = post.id
                                viewModel.posts = posts
                                selectedPost = post
                            }
                        }  label: {
                            KFImage(URL(string: post.thumbnailUrl))
                                .resizable()
                                .scaledToFill()
                                .frame(width: width, height: 160)
                                .cornerRadius(cornerRadius)
                                .clipped()
                            
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
                                                if showNames {
                                                    Text("\(post.restaurant.name)")
                                                        .lineLimit(2)
                                                        .truncationMode(.tail)
                                                        .foregroundColor(.white)
                                                        .font(.custom("MuseoSansRounded-300", size: 10))
                                                        .bold()
                                                        .shadow(color: .black, radius: 2, x: 0, y: 1)
                                                        .multilineTextAlignment(.leading)
                                                }
                                            }
                                            
                                            
                                            Spacer()
                                        }
                                        
                                    }
                                    
                                        .padding(4)
                                    
                                )
                                
                            
                        }
                        
                            
                        
                    }
                }
                .padding(spacing/2)
                .fullScreenCover(item: $selectedPost) { post in
                    NavigationStack {
                        SecondaryFeedView(viewModel: viewModel, hideFeedOptions: true, initialScrollPosition: post.id, titleText: feedTitleText ?? "Posts", checkLikes: true)
                        
                    }
                }
            } else {
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

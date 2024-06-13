//
//  FeedGridView.swift
//  Foodi
//
//  Created by Jack Robinson on 5/8/24.
//

import SwiftUI
import Kingfisher
import AVKit
struct FeedGridView: View {
    @State private var selectedPost: Post?
    
    
    private let spacing: CGFloat = 8 // New spacing variable
    private let items = [
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2),
    ]
    @ObservedObject var viewModel: FeedViewModel
    private var width: CGFloat {
        (UIScreen.main.bounds.width - (spacing * 2)) / 3
    }
    let heightRatio = 1.25
    let cornerRadius: CGFloat = 5
    var body: some View {
        if !viewModel.posts.isEmpty{
            VStack {
                LazyVGrid(columns: items, spacing: spacing/2) {
                    ///Three blanks to start it lower
                    Color.clear
                        .frame(width: width, height: width * heightRatio )
                        .cornerRadius(cornerRadius)
                    Color.clear
                        .frame(width: width, height: width * heightRatio)
                        .cornerRadius(cornerRadius)
                    Color.clear
                        .frame(width: width, height: width * heightRatio)
                        .cornerRadius(cornerRadius)
                    
                    ForEach(viewModel.posts) { post in
                        KFImage(URL(string: post.thumbnailUrl))
                            .resizable()
                            .scaledToFill()
                            .frame(width: width, height: width * heightRatio)
                            .cornerRadius(cornerRadius)
                            .clipped()
                            .onTapGesture {
                                viewModel.scrollPosition = post.id
                               viewModel.startingPostId = post.id
                               viewModel.feedViewOption = .feed
                                
                                
                              
                            }
                            .id(post.id)
                            
                            .overlay(
                                VStack{
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
                                            else if let recipe = post.cookingTitle {
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
                                //                                    .background(LinearGradient(gradient: Gradient(colors: [.black.opacity(0.3), .clear, .clear, .black.opacity(0.3)]),
                                //                                                               startPoint: .top,
                                //                                                               endPoint: .bottom))
                                    .onTapGesture {
                                        selectedPost = post
                                    }
                            )
                        
                    }
                    Color.clear
                        .frame(width: width, height: width * heightRatio)
                        .cornerRadius(cornerRadius)
                        .onAppear{
                            print("CLEAR APPEARED")
                            if let last = viewModel.posts.last {
                                Task {
                                    await viewModel.loadMoreContentIfNeeded(currentPost: last.id)
                                }
                            }
                        }
                    Color.clear
                        .frame(width: width, height: width * heightRatio)
                        .cornerRadius(cornerRadius)
                    Color.clear
                        .frame(width: width, height: width * heightRatio)
                        .cornerRadius(cornerRadius)
                    
                }
                //                ProgressView()
                //                    .frame(width: width, height: 160)
                //                    .onAppear{
                //                        Task {
                //                            await loadNextPageIfNeeded()
                //                        }
                //                    }
            }
            .padding(spacing/2)
//            .sheet(item: $selectedPost) { post in
//                FeedView(videoCoordinator: VideoPlayerCoordinator(), posts: [post], hideFeedOptions: true)
//                    .onDisappear {
//                        //player.replaceCurrentItem(with: nil)
//                    }
//            }
        }
    }
}

#Preview {
    FeedGridView(viewModel: FeedViewModel())
}



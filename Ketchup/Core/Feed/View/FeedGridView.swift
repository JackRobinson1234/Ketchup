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
                                   
                                    Spacer()
                                    HStack{
                                        VStack (alignment: .leading) {
                                            if let restaurant = post.restaurant {
                                                Text("\(restaurant.name)")
                                                    .lineLimit(2)
                                                    .truncationMode(.tail)
                                                    .foregroundColor(.white)
                                                    .font(.custom("MuseoSans-500", size: 10))
                                                    .bold()
                                                    .shadow(color: .primary, radius: 2, x: 0, y: 1)
                                            }
                                           
                                        }
                                        
                                        Spacer()
                                    }
                                    
                                }
                                    .padding(4)
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

            }
            .padding(spacing/2)

        }
    }
}

#Preview {
    FeedGridView(viewModel: FeedViewModel())
}



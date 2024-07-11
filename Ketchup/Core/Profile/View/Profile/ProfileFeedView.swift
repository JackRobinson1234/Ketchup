//
//  ProfileFeedView.swift
//  Ketchup
//
//  Created by Jack Robinson on 7/2/24.
//

import SwiftUI

struct ProfileFeedView: View {
    @ObservedObject var viewModel: FeedViewModel
    @Binding var scrollPosition: String?
    @State var pauseVideo = false
    @State var selectedPost: Post?
    @Binding var scrollTarget: String?
    var body: some View {
        if !viewModel.posts.isEmpty{
            LazyVStack {
                ForEach($viewModel.posts) { post in
                    WrittenFeedCell(viewModel: viewModel, post: post, scrollPosition: $scrollPosition, pauseVideo: $pauseVideo, selectedPost: $selectedPost, checkLikes: true)
                        .id(post.id)
                    
                    
                    
                }
            }
            .scrollTargetLayout()
            
            .onChange(of: viewModel.initialPrimaryScrollPosition) {
                scrollTarget = viewModel.initialPrimaryScrollPosition
            }
            .fullScreenCover(item: $selectedPost) { post in
                NavigationStack {
                    SecondaryFeedView(viewModel: viewModel, hideFeedOptions: true, initialScrollPosition: post.id, titleText: "Posts")
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
        }
    }
}

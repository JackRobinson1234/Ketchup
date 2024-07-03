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
        LazyVStack {
            ForEach($viewModel.posts) { post in
                WrittenFeedCell(viewModel: viewModel, post: post, scrollPosition: $scrollPosition, pauseVideo: $pauseVideo, selectedPost: $selectedPost, checkLikes: true)
                    .id(post.id)
                
                    
                    
            }
        }
        .scrollTargetLayout()
        .overlay {
            if viewModel.posts.isEmpty {
                ContentUnavailableView("No posts to show", systemImage: "eye.slash")
                    .foregroundStyle(Color("Colors/AccentColor"))
            }
        }
        .onChange(of: viewModel.initialPrimaryScrollPosition) {
            scrollTarget = viewModel.initialPrimaryScrollPosition
        }
        .fullScreenCover(item: $selectedPost) { post in
            NavigationStack {
                SecondaryFeedView(viewModel: viewModel, hideFeedOptions: true, initialScrollPosition: post.id, titleText: "Posts")
            }
        }
    }
}

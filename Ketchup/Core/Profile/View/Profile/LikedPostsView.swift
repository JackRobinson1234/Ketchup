//
//  LikedPostsView.swift
//  Foodi
//
//  Created by Jack Robinson on 2/26/24.
//

import SwiftUI

struct LikedPostsView: View {
    @ObservedObject var viewModel: ProfileViewModel
    @State var isLoading = true
    @StateObject var feedViewModel = FeedViewModel()
    @State private var postDisplayMode: PostDisplayMode = .media
    @Binding var scrollPosition: String?
    @Binding var scrollTarget: String?
    
    var body: some View {
        if isLoading {
            // Loading screen
            ProgressView("Loading...")
                .onAppear {
                    Task {
                        try await feedViewModel.fetchUserLikedPosts(user: viewModel.user)
                        isLoading = false
                    }
                }
        } else {
            VStack {
                Picker("Post Display Mode", selection: $postDisplayMode) {
                    ForEach(PostDisplayMode.allCases, id: \.self) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding([.bottom, .horizontal])
                
                
                switch postDisplayMode {
                case .all:
                    ProfileFeedView(
                        viewModel: feedViewModel,
                        scrollPosition: $scrollPosition,
                        scrollTarget: $scrollTarget
                    )
                case .media:
                    PostGridView(feedViewModel: feedViewModel, feedTitleText: "Posts liked by @\(viewModel.user.username)", showNames: true)
                case .map:
                    ProfileMapView(feedViewModel: feedViewModel)
                        .id("map")
                }
            }
            .onChange(of: postDisplayMode){
                if postDisplayMode == .map {
                    scrollTarget = "map"
                }
            }
        }
    }
}


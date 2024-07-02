//
//  ProfileSlideBar.swift
//  Foodi
//
//  Created by Jack Robinson on 2/19/24.
//

import SwiftUI

enum ProfileSectionEnum {
    case posts, reviews, likes, collections
}

struct ProfileSlideBar: View {
    @Binding var profileSection: ProfileSectionEnum
        @ObservedObject var viewModel: ProfileViewModel
        @StateObject var collectionsViewModel: CollectionsViewModel
        @StateObject var reviewsViewModel: ReviewsViewModel
        @StateObject var feedViewModel = FeedViewModel()
        @Binding var scrollPosition: String?
        @Binding var scrollTarget: String?
        
        init(viewModel: ProfileViewModel, profileSection: Binding<ProfileSectionEnum>, scrollPosition: Binding<String?>, scrollTarget: Binding<String?>) {
            self._profileSection = profileSection
            self.viewModel = viewModel
            self._collectionsViewModel = StateObject(wrappedValue: CollectionsViewModel(user: viewModel.user))
            self._reviewsViewModel = StateObject(wrappedValue: ReviewsViewModel(user: viewModel.user))
            self._scrollPosition = scrollPosition
            self._scrollTarget = scrollTarget
        }
    
    var body: some View {
        //MARK: Images
        VStack{
            HStack(spacing: 0) {
                Image(systemName: profileSection == .posts ? "camera.fill" : "camera")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 45, height: 15)
                
                    .onTapGesture {
                        withAnimation {
                            self.profileSection = .posts
                        }
                    }
                    .modifier(UnderlineImageModifier(isSelected: profileSection == .posts))
                    .frame(maxWidth: .infinity)
                //.task { await viewModel.fetchUserPosts() }
                
                Image(systemName: profileSection == .reviews ? "line.3.horizontal" : "line.3.horizontal")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 50, height: 14)
                    .font(profileSection == .reviews ? .system(size: 10, weight: .bold) : .system(size: 10, weight: .regular))
                    .onTapGesture {
                        withAnimation {
                            feedViewModel.posts = Array(viewModel.posts.prefix(15))
                            self.profileSection = .reviews
                        }
                    }
                    .modifier(UnderlineImageModifier(isSelected: profileSection == .reviews))
                    .frame(maxWidth: .infinity)
                
                
                Image(systemName: profileSection == .collections ? "folder.fill" : "folder")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 45, height: 20)
                
                    .onTapGesture {
                        withAnimation {
                            self.profileSection = .collections
                        }
                    }
                    .modifier(UnderlineImageModifier(isSelected: profileSection == .collections))
                    .frame(maxWidth: .infinity)
                
                Image(systemName: profileSection == .likes ? "heart.fill" : "heart")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 45, height: 20)
                
                    .onTapGesture {
                        withAnimation {
                            self.profileSection = .likes
                        }
                    }
                    .modifier(UnderlineImageModifier(isSelected: profileSection == .likes))
                    .frame(maxWidth: .infinity)
                
            }
        }
        .padding()
        .padding(.bottom, 22)
        
        // MARK: Section Logic
        
        if profileSection == .posts {
            PostGridView(posts: viewModel.posts, feedTitleText: "Posts by @\(viewModel.user.username)", viewModel: feedViewModel)
        }
        
        if profileSection == .reviews {
            ProfileFeedView(
                                            viewModel: feedViewModel,
                                            scrollPosition: $scrollPosition,
                                            scrollTarget: $scrollTarget
                                        )
        }
        
        if profileSection == .likes {
            LikedPostsView(viewModel: viewModel, feedViewModel: feedViewModel)
            
        }
        if profileSection == .collections {
            CollectionsListView(viewModel: collectionsViewModel)
        }
        
    }
    
}

struct ProfileFeedView: View {
    @ObservedObject var viewModel: FeedViewModel
    @Binding var scrollPosition: String?
    @State var pauseVideo = false
    @State var selectedPost: Post?
    @Binding var scrollTarget: String?
    
    var body: some View {
        LazyVStack {
            ForEach($viewModel.posts) { post in
                WrittenFeedCell(viewModel: viewModel, post: post, scrollPosition: $scrollPosition, pauseVideo: $pauseVideo, selectedPost: $selectedPost)
                    .id(post.id)
            }
        }
        .scrollTargetLayout()
        .overlay {
            if viewModel.showEmptyView {
                ContentUnavailableView("No posts to show", systemImage: "eye.slash")
                    .foregroundStyle(Color("Colors/AccentColor"))
            }
        }
        .onChange(of: viewModel.initialPrimaryScrollPosition) {
            print("SHOULD BE SCROLLING")
            //scrollPosition = viewModel.initialPrimaryScrollPosition
            scrollTarget = viewModel.initialPrimaryScrollPosition
        }
        .onChange(of: scrollPosition) { oldPostId, newPostId in
            if let oldIndex = viewModel.posts.firstIndex(where: { $0.id == oldPostId }),
               let newIndex = viewModel.posts.firstIndex(where: { $0.id == newPostId }) {
            }
        }
        .fullScreenCover(item: $selectedPost) { post in
            NavigationStack{
                SecondaryFeedView(viewModel: viewModel, hideFeedOptions: true, initialScrollPosition: post.id, titleText: "Posts")
            }
        }
    }
}

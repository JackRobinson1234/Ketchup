//
//  WrittenFeedCell.swift
//  Ketchup
//
//  Created by Jack Robinson on 6/25/24.
//

import SwiftUI
import Kingfisher
struct WrittenFeedCell: View {
    @ObservedObject var viewModel: FeedViewModel
    @Binding var post: Post
    @State private var showComments = false
    @State private var showShareView = false
    @State private var showCollections = false
    @State private var expandCaption = false
    @State private var showingOptionsSheet = false
    @State private var showingRepostSheet = false
    @State private var currentImageIndex = 0
    @Binding var scrollPosition: String?
    private var didLike: Bool { return post.didLike }
    private let pictureWidth: CGFloat = 240
    private let pictureHeight: CGFloat = 300
    @StateObject private var videoCoordinator: VideoPlayerCoordinator
    @Binding var pauseVideo: Bool

    init(viewModel: FeedViewModel, post: Binding<Post>, scrollPosition: Binding<String?>, pauseVideo: Binding<Bool>) {
        self._viewModel = ObservedObject(initialValue: viewModel)
        self._post = post
        self._scrollPosition = scrollPosition
        self._pauseVideo = pauseVideo
        
        let coordinator: VideoPlayerCoordinator
        if post.wrappedValue.mediaType == .video {
            coordinator = VideoPlayerCoordinatorPool.shared.coordinator(for: post.wrappedValue.id)
        } else {
            coordinator = VideoPlayerCoordinator() // Dummy coordinator for non-video posts
        }
        self._videoCoordinator = StateObject(wrappedValue: coordinator)
    }
    
    var body: some View {
        VStack {
            HStack {
                NavigationLink(value: post.user) {
                    UserCircularProfileImageView(profileImageUrl: post.user.profileImageUrl, size: .medium)
                }
                NavigationLink(value: post.user) {
                    VStack(alignment: .leading) {
                        Text("@\(post.user.username)")
                            .font(.custom("MuseoSansRounded-300", size: 14))
                            .foregroundStyle(.primary)
                            .multilineTextAlignment(.leading)
                        Text("\(post.user.fullname)")
                            .font(.custom("MuseoSansRounded-300", size: 16))
                            .fontWeight(.semibold)
                            .foregroundStyle(.primary)
                            .bold()
                            .multilineTextAlignment(.leading)
                    }
                }
                Spacer()
                if let timestamp = post.timestamp {
                    Text(getTimeElapsedString(from: timestamp))
                        .font(.custom("MuseoSansRounded-300", size: 12))
                        .foregroundColor(.gray)
                }
            }
            if post.mediaType == .photo {
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack {
                        ForEach(Array(post.mediaUrls.enumerated()), id: \.element) { index, url in
                            VStack {
                                Button {
                                    viewModel.startingImageIndex = index
                                    viewModel.scrollPosition = post.id
                                    viewModel.startingPostId = post.id
                                    viewModel.feedViewOption = .feed
                                } label: {
                                    KFImage(URL(string: url))
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: pictureWidth, height: pictureHeight)
                                        .clipped()
                                        .cornerRadius(10)
                                }
                            }
                            .scrollTransition(.animated, axis: .horizontal) { content, phase in
                                content
                                    .opacity(phase.isIdentity ? 1.0 : 0.8)
                            }
                        }
                    }
                    .frame(height: pictureHeight)
                    .scrollTargetLayout()
                }
                .scrollTargetBehavior(.viewAligned)
                .safeAreaPadding(.horizontal, ((UIScreen.main.bounds.width - pictureWidth) / 2))
            } else if post.mediaType == .video {
                Button {
                    viewModel.scrollPosition = post.id
                    viewModel.startingPostId = post.id
                    viewModel.feedViewOption = .feed
                } label: {
                    VideoPlayerView(coordinator: videoCoordinator, videoGravity: .resizeAspectFill)
                        .frame(width: pictureWidth, height: pictureHeight)
                        .cornerRadius(10)
                }
            }
            NavigationLink(destination: RestaurantProfileView(restaurantId: post.restaurant.id)) {
                HStack {
                    VStack(alignment: .leading) {
                        Text(post.restaurant.name)
                            .font(.custom("MuseoSansRounded-300", size: 16))
                            .bold()
                        Text("\(post.restaurant.city ?? ""), \(post.restaurant.state ?? "")")
                            .font(.custom("MuseoSansRounded-300", size: 14))
                    }
                    Spacer()
                }
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    RatingView(rating: post.overallRating, label: "Overall")
                    Divider().frame(height: 20)
                    RatingView(rating: post.foodRating, label: "Food")
                    Divider().frame(height: 20)
                    RatingView(rating: post.atmosphereRating, label: "Atmosphere")
                    Divider().frame(height: 20)
                    RatingView(rating: post.valueRating, label: "Value")
                    Divider().frame(height: 20)
                    RatingView(rating: post.serviceRating, label: "Service")
                }
            }
            HStack {
                Text(post.caption)
                    .font(.custom("MuseoSansRounded-300", size: 16))
                Spacer()
            }
            HStack {
                Button {
                    showComments.toggle()
                } label: {
                    InteractionButtonView(icon: "ellipsis.bubble", count: post.commentCount)
                }
                
                Button {
                    handleLikeTapped()
                } label: {
                    InteractionButtonView(icon: didLike ? "heart.fill" : "heart", count: post.likes, color: didLike ? Color("Colors/AccentColor") : .gray)
                }
                
                Button {
                    showingRepostSheet.toggle()
                } label: {
                    HStack(spacing: 3) {
                        Image(systemName: "arrow.2.squarepath")
                            .resizable()
                            .scaledToFill()
                            .frame(width: 18, height: 18)
                            .foregroundStyle(.gray)
                            .rotationEffect(.degrees(90))
                        Text("\(post.repostCount)")
                            .font(.custom("MuseoSansRounded-300", size: 14))
                            .foregroundStyle(.gray)
                    }
                    .padding(.trailing, 10)
                }
                
                Button {
                    showCollections.toggle()
                } label: {
                    InteractionButtonView(icon: "folder.badge.plus")
                }
                
                Button {
                    showShareView.toggle()
                } label: {
                    InteractionButtonView(icon: "arrowshape.turn.up.right")
                }
                
                Button {
                    showingOptionsSheet = true
                } label: {
                    ZStack {
                        Rectangle()
                            .fill(.clear)
                            .frame(width: 20, height: 28)
                        Image(systemName: "ellipsis")
                            .resizable()
                            .scaledToFill()
                            .frame(width: 5, height: 5)
                            .foregroundColor(.gray)
                    }
                }
                Spacer()
            }
            Divider()
        }
        .padding()
        .onAppear {
            if post.mediaType == .video {
                Task {
                    if let firstMediaUrl = post.mediaUrls.first, let videoURL = URL(string: firstMediaUrl) {
                        videoCoordinator.configurePlayer(url: videoURL, postId: post.id)
                    }
                    if let firstPost = viewModel.posts.first, firstPost.id == post.id && scrollPosition == nil {
                        videoCoordinator.replay()
                    }
                }
            }
        }
        .onDisappear {
            if post.mediaType == .video {
                videoCoordinator.pause()
            }
        }
        .onChange(of: scrollPosition) { oldValue, newValue in
            if post.mediaType == .video {
                if newValue == post.id {
                    videoCoordinator.replay()
                } else {
                    videoCoordinator.pause()
                }
            }
        }
        .sheet(isPresented: $showComments) {
            CommentsView(post: $post)
                .presentationDetents([.height(UIScreen.main.bounds.height * 0.65)])
        }
        .sheet(isPresented: $showShareView) {
            ShareView(post: post, currentImageIndex: currentImageIndex)
                .presentationDetents([.height(UIScreen.main.bounds.height * 0.15)])
        }
        .sheet(isPresented: $showCollections) {
            if let currentUser = AuthService.shared.userSession {
                AddItemCollectionList(user: currentUser, post: post)
            }
        }
        .sheet(isPresented: $showingOptionsSheet) {
            PostOptionsSheet(post: post, viewModel: viewModel)
                .presentationDetents([.height(UIScreen.main.bounds.height * 0.15)])
        }
        .sheet(isPresented: $showingRepostSheet) {
            RepostView(viewModel: viewModel, post: post)
                .presentationDetents([.height(UIScreen.main.bounds.height * 0.35)])
        }
    }
    
    private func handleLikeTapped() {
        Task { didLike ? await viewModel.unlike(post) : await viewModel.like(post) }
    }
}
struct RatingView: View {
    var rating: Rating
    var label: String
    
    var body: some View {
        HStack(spacing: 2) {
            rating.image
                .resizable()
                .frame(width: 20, height: 20)
            Text(label)
                .font(.custom("MuseoSansRounded-300", size: 14))
                .foregroundColor(.primary)
        }
    }
}

struct InteractionButtonView: View {
    var icon: String
    var count: Int?
    var color: Color = .gray
    
    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: icon)
                .resizable()
                .scaledToFill()
                .frame(width: 18, height: 18)
                .foregroundColor(color)
            if let count {
                Text("\(count)")
                    .font(.custom("MuseoSansRounded-300", size: 14))
                    .foregroundColor(.gray)
            }
        }
        .padding(.trailing, 10)
    }
}

#Preview {
    WrittenFeedCell(viewModel: FeedViewModel(), post: .constant(DeveloperPreview.posts[0]), scrollPosition: .constant(""), pauseVideo: .constant(false))
}

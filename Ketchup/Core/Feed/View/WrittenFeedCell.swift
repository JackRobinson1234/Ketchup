//
//  WrittenFeedCell.swift
//  Ketchup
//
//  Created by Jack Robinson on 6/25/24.
//
import SwiftUI
import Kingfisher
struct WrittenFeedCell: View {
    @EnvironmentObject var tabBarController: TabBarController
    @ObservedObject var viewModel: FeedViewModel
    @Binding var post: Post
    @State private var showComments = false
    @State private var showShareView = false
    @State private var showCollections = false
    @State private var showingOptionsSheet = false
    @State private var showingRepostSheet = false
    @State private var currentImageIndex = 0
    @Binding var scrollPosition: String?
    @StateObject private var videoCoordinator: VideoPlayerCoordinator
    @Binding var pauseVideo: Bool
    private let pictureWidth: CGFloat = 240
    private let pictureHeight: CGFloat = 300
    private var didLike: Bool {
        return post.didLike
    }
    @State var configured = false
    @Binding var selectedPost: Post?
    @State var showHeartOverlay = false
    var checkLikes: Bool
    init(viewModel: FeedViewModel, post: Binding<Post>, scrollPosition: Binding<String?>, pauseVideo: Binding<Bool>, selectedPost: Binding<Post?>, checkLikes: Bool = false) {
        self._viewModel = ObservedObject(initialValue: viewModel)
        self._post = post
        self._scrollPosition = scrollPosition
        self._pauseVideo = pauseVideo
        if post.wrappedValue.mediaType == .video {
            let coordinator = VideoPrefetcher.shared.getPlayerItem(for: post.wrappedValue)
            self._videoCoordinator = StateObject(wrappedValue: coordinator)
        } else {
            // Initialize with a dummy coordinator for non-video posts
            self._videoCoordinator = StateObject(wrappedValue: VideoPlayerCoordinator())
        }
        self._selectedPost = selectedPost
        self.checkLikes = checkLikes
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
                .disabled(post.user.username == "ketchup_media")
                Spacer()
                if let timestamp = post.timestamp {
                    Text(getTimeElapsedString(from: timestamp))
                        .font(.custom("MuseoSansRounded-300", size: 12))
                        .foregroundColor(.gray)
                }
            }
            if post.mediaType == .photo {
                if post.mediaUrls.count > 1 {
                    // Use ScrollView for multiple photos
                    ScrollView(.horizontal, showsIndicators: false) {
                        LazyHStack {
                            ForEach(Array(post.mediaUrls.enumerated()), id: \.element) { index, url in
                                VStack {
                                    Button {
                                        viewModel.startingImageIndex = index
                                        viewModel.startingPostId = post.id
                                        selectedPost = post
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
                } else {
                    // Center a single photo
                    Button {
                        viewModel.startingImageIndex = 0
                        viewModel.startingPostId = post.id
                        selectedPost = post
                    } label: {
                        KFImage(URL(string: post.mediaUrls.first ?? ""))
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: pictureWidth, height: pictureHeight)
                            .clipped()
                            .cornerRadius(10)
                    }
                    .frame(maxWidth: .infinity) // This will allow the Button to take full width
                }
            } else if post.mediaType == .video {
                HStack (alignment: .bottom){
                    Rectangle()
                        .frame(width: 40, height: 40)
                        .foregroundStyle(.clear)
                    Button {
                        viewModel.startingPostId = post.id
                        selectedPost = post
                    } label: {
                        VideoPlayerView(coordinator: videoCoordinator, videoGravity: .resizeAspectFill)
                            .frame(width: pictureWidth, height: pictureHeight)
                            .cornerRadius(10)
                    }
                    VStack {
                        Button(action: {
                            let player = videoCoordinator.player
                            switch player.timeControlStatus {
                            case .paused:
                                videoCoordinator.play()
                            case .waitingToPlayAtSpecifiedRate:
                                print("WAITING TO PERFORM AT A SPECIFIED RATE")
                            case .playing:
                                videoCoordinator.pause()
                            @unknown default:
                                print("UNKNOWN PLAYING STATUS")
                            }
                        }) {
                            Image(systemName: videoCoordinator.player.timeControlStatus == .playing ? "pause" : "play")
                                .foregroundColor(.white)
                                .frame(width: 24, height: 24)
                                .background(Circle().fill(Color.gray))
                        }
                        .frame(width: 40, height: 30)
                        
                        Button(action: {
                            viewModel.isMuted.toggle()
                            videoCoordinator.player.isMuted = viewModel.isMuted
                        }) {
                            Image(systemName: viewModel.isMuted ? "speaker.slash" : "speaker.wave.2")
                                .foregroundColor(.white)
                                .frame(width: 24, height: 24)
                                .background(Circle().fill(Color.gray))
                        }
                        .frame(width: 40, height: 30)
                    }
                }
            }
            NavigationLink(value: post.restaurant) {
                HStack {
                    VStack(alignment: .leading) {
                        Text(post.restaurant.name)
                            .font(.custom("MuseoSansRounded-300", size: 16))
                            .bold()
                        Text("\(post.restaurant.city ?? ""), \(post.restaurant.state ?? "")")
                            .font(.custom("MuseoSansRounded-300", size: 14))
                    }
                    .multilineTextAlignment(.leading)
                    Spacer()
                }
            }
            VStack(spacing: 10) {
                RatingsView(post: post)
                    .padding(.vertical, 5)
            }
            HStack {
                Text(post.caption)
                    .font(.custom("MuseoSansRounded-300", size: 16))
                Spacer()
            }
            HStack (spacing: 15) {
                Button {
                    videoCoordinator.pause()
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
                    videoCoordinator.pause()
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
                    .disabled(post.user.id == AuthService.shared.userSession?.id)
                    
                }
                Button {
                    videoCoordinator.pause()
                    showCollections.toggle()
                } label: {
                    InteractionButtonView(icon: "folder.badge.plus")
                }
                
                Button {
                    videoCoordinator.pause()
                    showShareView.toggle()
                } label: {
                    InteractionButtonView(icon: "arrowshape.turn.up.right")
                }
                
                Button {
                    videoCoordinator.pause()
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
                .padding(.top, 5)
        }
        .padding(.horizontal)
        .padding(5)
        .onAppear {
            if checkLikes {
                Task {
                    post.didLike = try await PostService.shared.checkIfUserLikedPost(post)
                }
            }
            if post.mediaType == .video {
                videoCoordinator.player.isMuted = viewModel.isMuted
                Task {
                    if let firstMediaUrl = post.mediaUrls.first, let videoURL = URL(string: firstMediaUrl) {
                        if !configured {
                            //videoCoordinator.configurePlayer(url: videoURL, postId: post.id)
                            //configured = true
                        }
                    }
                    if let firstPost = viewModel.posts.first, firstPost.id == post.id && scrollPosition == nil {
                        videoCoordinator.replay()
                    }
                }
            }
        }
        .onChange(of: tabBarController.selectedTab) { oldTab, newTab in
            if post.mediaType == .video && newTab !=  0 {
                videoCoordinator.pause()
            }
        }
        .onChange(of: scrollPosition) { oldValue, newValue in
            videoCoordinator.player.isMuted = viewModel.isMuted
            if post.mediaType == .video {
                if newValue == post.id {
                    videoCoordinator.play()
                } else {
                    videoCoordinator.pause()
                }
            }
        }
        .sheet(isPresented: $showComments) {
            CommentsView(post: $post)
                .presentationDetents([.height(UIScreen.main.bounds.height * 0.65)])
                .onDisappear {
                    videoCoordinator.play()
                }
        }
        .sheet(isPresented: $showShareView) {
            ShareView(post: post, currentImageIndex: currentImageIndex)
                .presentationDetents([.height(UIScreen.main.bounds.height * 0.15)])
                .onDisappear {
                    videoCoordinator.play()
                }
        }
        .sheet(isPresented: $showCollections) {
            if let currentUser = AuthService.shared.userSession {
                AddItemCollectionList(user: currentUser, post: post)
                    .onDisappear {
                        videoCoordinator.play()
                    }
            }
        }
        .sheet(isPresented: $showingOptionsSheet) {
            PostOptionsSheet(post: post, viewModel: viewModel)
                .presentationDetents([.height(UIScreen.main.bounds.height * 0.15)])
                .onDisappear {
                    videoCoordinator.play()
                }
        }
        .sheet(isPresented: $showingRepostSheet) {
            RepostView(viewModel: viewModel, post: post)
                .presentationDetents([.height(UIScreen.main.bounds.height * 0.35)])
                .onDisappear {
                    videoCoordinator.play()
                }
        }
        .onChange(of: selectedPost) {
            if selectedPost != nil {
                videoCoordinator.pause()
            }
        }
        .overlay(
            ZStack {
                if showHeartOverlay {
                    Image(systemName: "heart.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 100)
                        .foregroundStyle(Color("Colors/AccentColor"))
                        .transition(.opacity)
                    
                }
            }
        )
        .onDisappear {
            videoCoordinator.pause()
        }
        .onChange(of: pauseVideo) {
            if pauseVideo {
                videoCoordinator.pause()
            } else {
                videoCoordinator.play()
            }
        }
    }
    
    private func handleLikeTapped() {
        Task {
            didLike ? await viewModel.unlike(post) : await viewModel.like(post)
            if didLike {
                withAnimation {
                    showHeartOverlay = true
                }
                Debouncer(delay: 1.0).schedule {
                    withAnimation {
                        showHeartOverlay = false
                    }
                }
            }
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

struct RatingSlider: View {
    let rating: Double
    let label: String
    let isOverall: Bool
    let fontColor: Color
    
    var formattedRating: String {
        return String(format: "%.1f", rating)
    }
    
    var body: some View {
        HStack(alignment: .center, spacing: 5) {
            Text(label)
                .font(isOverall ? .custom("MuseoSansRounded-700", size: 16) : .custom("MuseoSansRounded-300", size: 16))
                .foregroundColor(fontColor)
                .frame(width: 90, alignment: .leading)
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 2)
                        .cornerRadius(1)
                    
                    Rectangle()
                        .fill(Color("Colors/AccentColor"))
                        .frame(width: (rating / 10.0) * geometry.size.width, height: 2)
                        .cornerRadius(1)
                }
                .frame(maxHeight: .infinity)
            }
            .frame(height: 20) // This sets a fixed height for the GeometryReader
            
            Text(formattedRating)
                .font(.custom("MuseoSansRounded-300", size: 14))
                .foregroundColor(fontColor)
                .frame(width: 40, alignment: .trailing)
        }
    }
}



struct RatingsView: View {
    let post: Post
    @State private var isExpanded = false
    
    var overallRating: Double {
        let ratings = [post.foodRating, post.atmosphereRating, post.valueRating, post.serviceRating].compactMap { $0 }
        guard !ratings.isEmpty else { return 0 }
        return ratings.reduce(0, +) / Double(ratings.count)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center, spacing: 10) {
                Spacer()
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isExpanded.toggle()
                    }
                }) {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .foregroundColor(.gray)
                        .frame(width: 25)
                        .rotationEffect(.degrees(isExpanded ? 0 : -90))
                        .animation(.easeInOut(duration: 0.3), value: isExpanded)
                }
                FeedOverallRatingView(rating: overallRating)
            }
            
            if isExpanded {
                VStack(alignment: .leading, spacing: 10) {
                    if let foodRating = post.foodRating {
                        RatingSlider(rating: foodRating, label: "Food", isOverall: false, fontColor: .primary)
                    }
                    if let atmosphereRating = post.atmosphereRating {
                        RatingSlider(rating: atmosphereRating, label: "Atmosphere", isOverall: false, fontColor: .primary)
                    }
                    if let valueRating = post.valueRating {
                        RatingSlider(rating: valueRating, label: "Value", isOverall: false, fontColor: .primary)
                    }
                    if let serviceRating = post.serviceRating {
                        RatingSlider(rating: serviceRating, label: "Service", isOverall: false, fontColor: .primary)
                    }
                }
                .transition(.scale(scale: 0.9, anchor: .top).combined(with: .opacity))
            }
        }
    }
}

struct FeedOverallRatingView: View {
    let rating: Double
    
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 25, height: 25)
            
            Text(String(format: "%.1f", rating))
                .font(.custom("MuseoSansRounded-300", size: 12))
                .foregroundColor(.primary)
        }
    }
}

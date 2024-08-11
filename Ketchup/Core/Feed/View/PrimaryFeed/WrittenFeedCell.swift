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
    @State private var currentImageIndex = 0
    @Binding var scrollPosition: String?
    //@StateObject private var videoCoordinator: VideoPlayerCoordinator
    @Binding var pauseVideo: Bool
    private let mediaWidth: CGFloat = 240
    private let mediaHeight: CGFloat = 300
    private var didLike: Bool {
        return post.didLike
    }
    private var didBookmark: Bool {
        return post.didBookmark
    }
    @State private var videoCoordinators: [(String, VideoPlayerCoordinator)] = []
    
    @State var configured = false
    @Binding var selectedPost: Post?
    @State var showHeartOverlay = false
    @State var isExpanded = false
    @State private var currentlyPlayingVideoId: String?
    @State private var isCurrentVideoPlaying = false
    @State private var isTaggedSheetPresented = false
    @State private var showUserProfile = false
    
    @State private var selectedUser: PostUser?
    @State private var parsedCaption: AttributedString?
    
    @State private var selectedUserId: String?
    @State private var currentIndex: Int = 0

    var checkLikes: Bool
    
    init(viewModel: FeedViewModel, post: Binding<Post>, scrollPosition: Binding<String?>, pauseVideo: Binding<Bool>, selectedPost: Binding<Post?>, checkLikes: Bool = false) {
        self._viewModel = ObservedObject(initialValue: viewModel)
        self._post = post
        self._scrollPosition = scrollPosition
        self._pauseVideo = pauseVideo
        self._selectedPost = selectedPost
        self.checkLikes = checkLikes
        
        // Initialize videoCoordinators
        let coordinators = VideoPrefetcher.shared.getPlayerItems(for: post.wrappedValue)
        self._videoCoordinators = State(initialValue: coordinators)
    }
    
    var overallRating: Double? {
        let ratings = [post.foodRating, post.atmosphereRating, post.valueRating, post.serviceRating].compactMap { $0 }
        guard !ratings.isEmpty else { return nil }
        return ratings.reduce(0, +) / Double(ratings.count)
    }
    
    var body: some View {
        VStack {
            
            HStack() {
                Button(action: {
                    showUserProfile = true
                }) {
                    UserCircularProfileImageView(profileImageUrl: post.user.profileImageUrl, size: .medium)
                }
                Button(action: {
                    showUserProfile = true
                }) {
                    VStack(alignment: .leading) {
                        Text("\(post.user.fullname)")
                            .font(.custom("MuseoSansRounded-300", size: 16))
                            .fontWeight(.semibold)
                            .foregroundStyle(.black)
                            .bold()
                            .multilineTextAlignment(.leading)
                        Text("@\(post.user.username)")
                            .font(.custom("MuseoSansRounded-300", size: 14))
                            .foregroundStyle(Color("Colors/AccentColor"))
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
            .padding(.horizontal)
            
            if post.mediaType == .mixed, let mixedMediaUrls = post.mixedMediaUrls, !mixedMediaUrls.isEmpty {
                VStack {
                    ScrollView(.horizontal, showsIndicators: false) {
                        LazyHStack {
                            ForEach(Array(mixedMediaUrls.enumerated()), id: \.element.id) { index, mediaItem in
                                VStack {
                                    Button {
                                        viewModel.startingImageIndex = index
                                        viewModel.startingPostId = post.id
                                        selectedPost = post
                                    } label: {
                                        if mediaItem.type == .photo {
                                            KFImage(URL(string: mediaItem.url))
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                                .frame(width: mediaWidth, height: mediaHeight)
                                                .clipped()
                                                .cornerRadius(10)
                                        } else if mediaItem.type == .video {
                                            ZStack {
                                                VideoPlayerView(coordinator: getVideoCoordinator(for: mediaItem.id), videoGravity: .resizeAspectFill)
                                                    .frame(width: mediaWidth, height: mediaHeight)
                                                    .cornerRadius(10)
                                                    .id(mediaItem.id)
                                                
                                                if !isCurrentVideoPlaying || currentlyPlayingVideoId != mediaItem.id {
                                                    Image(systemName: "play.circle.fill")
                                                        .resizable()
                                                        .frame(width: 50, height: 50)
                                                        .foregroundColor(.white)
                                                        .opacity(0.8)
                                                }
                                            }
                                        }
                                    }
                                }
                                .scrollTransition(.animated, axis: .horizontal) { content, phase in
                                    content
                                        .opacity(phase.isIdentity ? 1.0 : 0.8)
                                }
                            }
                        }
                        .frame(height: mediaHeight)
                        .scrollTargetLayout()
                    }
                    .scrollTargetBehavior(.viewAligned)
                    .safeAreaPadding(.horizontal, ((UIScreen.main.bounds.width - mediaWidth) / 2))
                    .scrollPosition(id: $currentlyPlayingVideoId)
                    
                    // Play/Pause and Mute buttons
                    if let currentVideoId = currentlyPlayingVideoId,
                       mixedMediaUrls.first(where: { $0.id == currentVideoId })?.type == .video {
                        HStack {
                            Spacer()
                            Button(action: {
                                togglePlayPause()
                            }) {
                                Image(systemName: isCurrentVideoPlaying ? "pause.circle.fill" : "play.circle.fill")
                                    .resizable()
                                    .frame(width: 30, height: 30)
                                    .foregroundColor(.white)
                                    .background(Color.black.opacity(0.6))
                                    .clipShape(Circle())
                            }
                            Button(action: {
                                toggleMute()
                            }) {
                                Image(systemName: viewModel.isMuted ? "speaker.slash.circle.fill" : "speaker.wave.2.circle.fill")
                                    .resizable()
                                    .frame(width: 30, height: 30)
                                    .foregroundColor(.white)
                                    .background(Color.black.opacity(0.6))
                                    .clipShape(Circle())
                            }
                            Spacer()
                        }
                        .padding(.top, 8)
                    }
                }
            } else if post.mediaType == .video {
                HStack(alignment: .bottom) {
                    Rectangle()
                        .frame(width: 40, height: 40)
                        .foregroundStyle(.clear)
                    
                    ForEach(videoCoordinators, id: \.0) { mediaItemId, coordinator in
                        Button {
                            viewModel.startingPostId = post.id
                            selectedPost = post
                        } label: {
                            VideoPlayerView(coordinator: coordinator, videoGravity: .resizeAspectFill)
                                .frame(width: mediaWidth, height: mediaHeight)
                                .cornerRadius(10)
                        }
                    }
                    
                    VStack {
                        Button(action: {
                            togglePlayPause()
                        }) {
                            Image(systemName: isPlaying ? "pause" : "play")
                                .foregroundColor(.white)
                                .frame(width: 24, height: 24)
                                .background(Circle().fill(Color.gray))
                        }
                        .frame(width: 40, height: 30)
                        
                        Button(action: {
                            toggleMute()
                        }) {
                            Image(systemName: viewModel.isMuted ? "speaker.slash" : "speaker.wave.2")
                                .foregroundColor(.white)
                                .frame(width: 24, height: 24)
                                .background(Circle().fill(Color.gray))
                        }
                        .frame(width: 40, height: 30)
                    }
                }
            } else if post.mediaType == .photo {
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
                                            .frame(width: mediaWidth, height: mediaHeight)
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
                        .frame(height: mediaHeight)
                        .scrollTargetLayout()
                    }
                    .scrollTargetBehavior(.viewAligned)
                    .safeAreaPadding(.horizontal, ((UIScreen.main.bounds.width - mediaWidth) / 2))
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
                            .frame(width: mediaWidth, height: mediaHeight)
                            .clipped()
                            .cornerRadius(10)
                    }
                    .frame(maxWidth: .infinity) // This will allow the Button to take full width
                }
            }
            VStack{
                NavigationLink(value: post.restaurant) {
                    HStack(alignment: .center) {
                        VStack(alignment: .leading) {
                            Text(post.restaurant.name)
                                .font(.custom("MuseoSansRounded-300", size: 16))
                                .bold()
                            Text("\(post.restaurant.city ?? ""), \(post.restaurant.state ?? "")")
                                .font(.custom("MuseoSansRounded-300", size: 14))
                                .foregroundColor(.black)
                        }
                        .multilineTextAlignment(.leading)
                        Spacer()
                        if let overallRating = overallRating {
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    isExpanded.toggle()
                                }
                            }) {
                                HStack(alignment: .center, spacing: 4) {
                                    FeedOverallRatingView(rating: overallRating)
                                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                                        .foregroundColor(.gray)
                                        .frame(width: 25)
                                        .rotationEffect(.degrees(isExpanded ? 0 : -90))
                                        .animation(.easeInOut(duration: 0.3), value: isExpanded)
                                }
                            }
                        }
                    }
                    .padding(.top, 5)
                }
                
                
                if isExpanded {
                    RatingsView(post: post, isExpanded: $isExpanded)
                        .padding(.vertical, 5)
                }
                
                HStack {
                    if let parsed = parsedCaption {
                        Text(parsed)
                            .font(.custom("MuseoSansRounded-300", size: 16))
                    } else {
                        Text(post.caption)
                            .font(.custom("MuseoSansRounded-300", size: 16))
                            .onAppear {
                                parsedCaption = parseCaption(post.caption)
                            }
                    }
                    Spacer()
                }
                
                if !post.taggedUsers.isEmpty {
                    Button(action: {
                        isTaggedSheetPresented.toggle()
                    }) {
                        HStack() {
                            Text("Went with:")
                                .font(.custom("MuseoSansRounded-300", size: 16))
                                .bold()
                            
                            // Display profile images of the first three tagged users
                            ForEach(post.taggedUsers.prefix(3), id: \.id) { user in
                                UserCircularProfileImageView(profileImageUrl: user.profileImageUrl, size: .xxSmall)
                            }
                            
                            // If there are more than three users, display the count of additional users
                            if post.taggedUsers.count > 3 {
                                VStack {
                                    Spacer()
                                    Text("and \(post.taggedUsers.count - 3) others")
                                        .font(.custom("MuseoSansRounded-300", size: 12))
                                }
                            }
                            
                            Spacer()
                        }
                    }
                    .sheet(isPresented: $isTaggedSheetPresented) {
                        TaggedUsersSheetView(taggedUsers: post.taggedUsers)
                            .presentationDetents([.height(UIScreen.main.bounds.height * 0.5)])
                        
                    }
                }
                
                HStack(spacing: 15) {
                    Button {
                        handleLikeTapped()
                        triggerHapticFeedback()
                    } label: {
                        InteractionButtonView(icon: didLike ? "heart.fill" : "heart", count: post.likes, color: didLike ? Color("Colors/AccentColor") : .gray)
                    }

                    Button {
                        showComments.toggle()
                    } label: {
                        InteractionButtonView(icon: "ellipsis.bubble", count: post.commentCount)
                    }

                    Button {
                        handleBookmarkTapped()
                        triggerHapticFeedback()
                    } label: {
                        InteractionButtonView(icon: didBookmark ? "bookmark.fill" : "bookmark", color: didBookmark ? Color("Colors/AccentColor") : .gray, width: 20, height: 20)
                    }

                    Button {
                        showCollections.toggle()
                    } label: {
                        InteractionButtonView(icon: "folder.badge.plus", width: 24, height: 24)
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
            }
            .padding(.horizontal)
            Divider()
                .padding(.top, 5)
        }
        
        .onAppear {
            if checkLikes {
                Task {
                    await viewModel.checkIfUserLikedPosts()
                    await viewModel.checkIfUserBookmarkedRestaurants()
                }
            }
            isCurrentVideoPlaying = false
            
            // Add this block
            if post.mediaType == .mixed, let firstMediaItem = post.mixedMediaUrls?.first, firstMediaItem.type == .video {
                currentlyPlayingVideoId = firstMediaItem.id
            } else if post.mediaType == .video, let firstVideoId = videoCoordinators.first?.0 {
                currentlyPlayingVideoId = firstVideoId
            }
        }
        
        .onChange(of: scrollPosition){
            if scrollPosition != post.id {
                pauseAllVideos()
            } else {
                handleIndexChange(currentIndex)
            }
        }
        .onDisappear{
            pauseAllVideos()
        }
        .onChange(of: currentIndex) { oldValue, newValue in
            pauseAllVideos()
            handleIndexChange(newValue)
        }
        .onChange(of: pauseVideo){
            if pauseVideo{
                pauseAllVideos()
            } else {
                handleIndexChange(currentIndex)
            }
        }
        .environment(\.openURL, OpenURLAction { url in
            if url.scheme == "user",
               let userId = url.host,
               let user = post.captionMentions.first(where: { $0.id == userId }) {
                selectedUserId = user.id
                viewModel.isShowingProfileSheet = true
                return .handled
            }
            return .systemAction
        })
        .sheet(isPresented: $viewModel.isShowingProfileSheet) {
            if let userId = selectedUserId {
                NavigationStack {
                    if userId == "invalid" {
                        Text("User does not exist")
                    } else {
                        ProfileView(uid: userId)
                    }
                }
                .onAppear {
                    pauseAllVideos()
                }
                .onDisappear {
                    handleIndexChange(currentIndex)
                }
            }
        }
//        .onChange(of: currentlyPlayingVideoId) { oldValue, newValue in
//            if let newValue = newValue,
//               let coordinator = videoCoordinators.first(where: { $0.0 == newValue })?.1 {
//                pauseAllVideos()
//                coordinator.play()
//                isCurrentVideoPlaying = true
//            }
//        }
        

        .sheet(isPresented: $showComments) {
            CommentsView(post: $post)
                .presentationDetents([.height(UIScreen.main.bounds.height * 0.65)])
                .onAppear {
                    pauseAllVideos()
                }
                .onDisappear {
                    handleIndexChange(currentIndex)
                }
        }
        .sheet(isPresented: $showShareView) {
            ShareView(post: post, currentImageIndex: currentImageIndex)
                .presentationDetents([.height(UIScreen.main.bounds.height * 0.15)])
                .onAppear {
                    pauseAllVideos()
                }
                .onDisappear {
                    handleIndexChange(currentIndex)
                }
        }
        .sheet(isPresented: $showCollections) {
            if let currentUser = AuthService.shared.userSession {
                AddItemCollectionList(post: post)
                    .onAppear {
                        pauseAllVideos()
                    }
                    .onDisappear {
                        handleIndexChange(currentIndex)
                    }
            }
        }
        .sheet(isPresented: $showingOptionsSheet) {
            PostOptionsSheet(post: $post, viewModel: viewModel)
                .presentationDetents([.height(UIScreen.main.bounds.height * 0.15)])
                .onAppear {
                    pauseAllVideos()
                }
                .onDisappear {
                    handleIndexChange(currentIndex)
                }
        }
        .onChange(of: selectedPost) {
            if selectedPost != nil {
                //videoCoordinator.pause()
            }
        }
        .onChange(of: currentlyPlayingVideoId) { oldValue, newValue in
            pauseAllVideos()
            handleVisibleMediaChange(oldValue: oldValue, newValue: newValue)
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
                   pauseAllVideos()
                }
                .fullScreenCover(isPresented: $showUserProfile) {
                    NavigationStack {
                        ProfileView(uid: post.user.id)
                    }
                }
    }
    private func handleVisibleMediaChange(oldValue: String?, newValue: String?) {
            pauseAllVideos()
            
            if let newValue = newValue,
               let mediaItem = post.mixedMediaUrls?.first(where: { $0.id == newValue }),
               mediaItem.type == .video {
                playVideo(id: newValue)
            }
        }
    private func handleIndexChange(_ index: Int) {
        pauseAllVideos()
        if post.mediaType == .mixed, let mixedMediaUrls = post.mixedMediaUrls, !mixedMediaUrls.isEmpty {
            if index < mixedMediaUrls.count {
                let mediaItem = mixedMediaUrls[index]
                if mediaItem.type == .video {
                    currentlyPlayingVideoId = mediaItem.id
                    playVideo(id: mediaItem.id)
                }
            }
        } else if post.mediaType == .video && index == 0 {
            if let firstVideoId = videoCoordinators.first?.0 {
                currentlyPlayingVideoId = firstVideoId
                playVideo(id: firstVideoId)
            }
        }
    }
    private func pauseAllVideos() {
        for (_, coordinator) in videoCoordinators {
            coordinator.pause()
        }
        isCurrentVideoPlaying = false
    }
    
    private func togglePlayPause() {
        if let currentVideoId = currentlyPlayingVideoId,
           let coordinator = videoCoordinators.first(where: { $0.0 == currentVideoId })?.1 {
            if isCurrentVideoPlaying {
                coordinator.pause()
            } else {
                   coordinator.play()
               }
               isCurrentVideoPlaying.toggle()
           }
       }
    
    private func toggleMute() {
           viewModel.isMuted.toggle()
           for (_, coordinator) in videoCoordinators {
               coordinator.player.isMuted = viewModel.isMuted
           }
       }
    
    private func playVideo(id: String) {
            if let coordinator = videoCoordinators.first(where: { $0.0 == id })?.1 {
                coordinator.play()
                isCurrentVideoPlaying = true
                currentlyPlayingVideoId = id
            }
        }
    private func pauseVideo(id: String) {
            if let coordinator = videoCoordinators.first(where: { $0.0 == id })?.1 {
                coordinator.pause()
                if currentlyPlayingVideoId == id {
                    isCurrentVideoPlaying = false
                }
            }
        }
    
    
    
    private var isPlaying: Bool {
        videoCoordinators.first?.1.player.timeControlStatus == .playing
    }
    private func getVideoCoordinator(for mediaItemId: String) -> VideoPlayerCoordinator {
        if let coordinator = videoCoordinators.first(where: { $0.0 == mediaItemId }) {
            return coordinator.1
        }
        // If not found, create a new one (this should be rare)
        let newCoordinator = VideoPlayerCoordinator()
        videoCoordinators.append((mediaItemId, newCoordinator))
        return newCoordinator
    }
    private func parseCaption(_ input: String) -> AttributedString {
        var result = AttributedString(input)
        let pattern = "@\\w+"
        
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return result
        }
        
        let nsRange = NSRange(input.startIndex..., in: input)
        let matches = regex.matches(in: input, range: nsRange)
        
        for match in matches.reversed() {
            guard let range = Range(match.range, in: input) else { continue }
            
            let fullMatch = String(input[range])
            let username = String(fullMatch.dropFirst()) // Remove @ from username
            
            if let user = post.captionMentions.first(where: { $0.username.lowercased() == username.lowercased() }),
               let attributedRange = Range(range, in: result) {
                result[attributedRange].foregroundColor = Color("Colors/AccentColor")
                result[attributedRange].link = URL(string: "user://\(user.id)")
            }
        }
        
        return result
    }
    
    private func handleBookmarkTapped() {
        Task {
            if post.didBookmark {
                await viewModel.unbookmark(post)
            } else {
                await viewModel.bookmark(post)
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
    
    private func handleDoubleTap() {
        if !didLike {
            Task {
                await viewModel.like(post)
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

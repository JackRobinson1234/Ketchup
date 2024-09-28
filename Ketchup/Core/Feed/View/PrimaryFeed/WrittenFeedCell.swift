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
    @Binding var scrollPosition: String?
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
    @State private var scrollViewWidth: CGFloat = 0
    @State private var dragOffset: CGFloat = 0
    @GestureState private var dragState = DragState.inactive
    var hideActionButtons: Bool = false

    private enum DragState {
        case inactive
        case dragging(translation: CGFloat)

        var translation: CGFloat {
            switch self {
            case .inactive:
                return 0
            case .dragging(let translation):
                return translation
            }
        }
    }

    var checkLikes: Bool

    init(viewModel: FeedViewModel, post: Binding<Post>, scrollPosition: Binding<String?>, pauseVideo: Binding<Bool>, selectedPost: Binding<Post?>, checkLikes: Bool = false,     hideActionButtons: Bool = false
) {
        self._viewModel = ObservedObject(initialValue: viewModel)
        self._post = post
        self._scrollPosition = scrollPosition
        self._pauseVideo = pauseVideo
        self._selectedPost = selectedPost
        self.checkLikes = checkLikes
        self.hideActionButtons = hideActionButtons

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
            // User profile and timestamp
            HStack() {
                Button(action: {
                    showUserProfile = true
                }) {
                    UserCircularProfileImageView(profileImageUrl: post.user.profileImageUrl, size: .medium)
                }
                .disabled(hideActionButtons)

                Button(action: {
                    showUserProfile = true
                }) {
                    VStack(alignment: .leading) {
                        Text("\(post.user.fullname)")
                            .font(.custom("MuseoSansRounded-300", size: 16))
                            .fontWeight(.semibold)
                            .foregroundColor(.black)
                            .bold()
                            .multilineTextAlignment(.leading)
                        Text("@\(post.user.username)")
                            .font(.custom("MuseoSansRounded-300", size: 14))
                            .foregroundColor(Color("Colors/AccentColor"))
                            .multilineTextAlignment(.leading)
                    }
                }
                .disabled(hideActionButtons)
                .disabled(post.user.username == "ketchup_media")
                Spacer()
                if let timestamp = post.timestamp {
                    Text(getTimeElapsedString(from: timestamp))
                        .font(.custom("MuseoSansRounded-300", size: 12))
                        .foregroundColor(.gray)
                }
            }
            .padding(.horizontal)

            // Media content
            if post.mediaType == .mixed, let mixedMediaUrls = post.mixedMediaUrls, !mixedMediaUrls.isEmpty {
                            VStack {
                                PagingScrollView(
                                    itemWidth: mediaWidth,
                                    itemSpacing: 10,
                                    itemCount: mixedMediaUrls.count,
                                    currentIndex: $currentIndex
                                ) {
                                    HStack(spacing: 10) {
                                        ForEach(Array(mixedMediaUrls.enumerated()), id: \.element.id) { index, mediaItem in
                                            mediaItemView(for: mediaItem, at: index)
                                                .frame(width: mediaWidth)
                                        }
                                    }
                                }
                                .frame(height: mediaHeight)
                                .onAppear {
                                    handleIndexChange(currentIndex)
                                }
                                .onChange(of: currentIndex) { newIndex in
                                    handleIndexChange(newIndex)
                                }
                                
                                // Play/Pause and Mute buttons
                                if currentIndex >= 0 && currentIndex < mixedMediaUrls.count {
                                    let currentMediaItem = mixedMediaUrls[currentIndex]
                                    if currentMediaItem.type == .video {
                                        HStack {
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
                                            .padding(.trailing, 10)
                                            
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
                                        }
                                        .padding(.top, 8)
                                    }
                                }
                            }
                        } else if post.mediaType == .video {
                            videoView()
                        } else if post.mediaType == .photo {
                            photoView()
                        }

            // Restaurant info and ratings
            restaurantInfoView()

            // Caption
            captionView()

            // Tagged users
            taggedUsersView()

            // Interaction buttons
            if !hideActionButtons {
                interactionButtonsView()
            }
            if !hideActionButtons {
                Divider()
                    .padding(.top, 5)
            }
        }
        .onAppear(perform: onAppear)
        .onChange(of: scrollPosition) { _ in handleScrollPositionChange() }
        .onDisappear(perform: pauseAllVideos)
        .onChange(of: pauseVideo) { newValue in handlePauseVideoChange(newValue) }
        .onChange(of: post.caption) { _ in updateParsedCaption() }
        .environment(\.openURL, OpenURLAction { url in handleOpenURL(url) })
        .sheet(item: $selectedUser) { user in
            NavigationView {
                ProfileView(uid: user.id)
            }
            .onAppear(perform: pauseAllVideos)
            .onDisappear { handleIndexChange(currentIndex) }
        }
        .sheet(isPresented: $showComments) {
            CommentsView(post: $post, feedViewModel: viewModel)
                .presentationDetents([.height(UIScreen.main.bounds.height * 0.65)])
                .onAppear(perform: pauseAllVideos)
                .onDisappear { handleIndexChange(currentIndex) }
        }
        .sheet(isPresented: $showShareView) {
            ShareView(post: post, currentMediaIndex: currentIndex)
                .presentationDetents([.height(UIScreen.main.bounds.height * 0.15)])
                .onAppear(perform: pauseAllVideos)
                .onDisappear { handleIndexChange(currentIndex) }
        }
        .sheet(isPresented: $showCollections) {
            if let currentUser = AuthService.shared.userSession {
                AddItemCollectionList(post: post)
                    .onAppear(perform: pauseAllVideos)
                    .onDisappear { handleIndexChange(currentIndex) }
            }
        }
        .sheet(isPresented: $showingOptionsSheet) {
            PostOptionsSheet(post: $post, viewModel: viewModel)
                .presentationDetents([.height(UIScreen.main.bounds.height * 0.15)])
                .onAppear(perform: pauseAllVideos)
                .onDisappear { handleIndexChange(currentIndex) }
        }
        .onChange(of: selectedPost) { newValue in
            if newValue != nil {
                pauseAllVideos()
            }
        }
        .onChange(of: currentlyPlayingVideoId) { newValue in
            handleVisibleMediaChange(newValue: newValue)
        }
        .overlay(
            ZStack {
                if showHeartOverlay {
                    Image(systemName: "heart.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 100)
                        .foregroundColor(Color("Colors/AccentColor"))
                        .transition(.opacity)
                }
            }
        )
        .fullScreenCover(isPresented: $showUserProfile) {
            NavigationView {
                ProfileView(uid: post.user.id)
            }
        }
    }

    // MARK: - Subviews

    
    @ViewBuilder
    private func mediaItemView(for mediaItem: MixedMediaItem, at index: Int) -> some View {
        VStack(spacing: 0) {
            Button {
                pauseAllVideos()
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
                        
                        // Show play icon overlay when video is not playing or not the current one
//                        if !isCurrentVideoPlaying {
//                            Image(systemName: "play.circle.fill")
//                                .resizable()
//                                .frame(width: 50, height: 50)
//                                .foregroundColor(.white)
//                                .opacity(0.8)
//                        }
                    }
                }
            }
        }
    }
    

    private func videoView() -> some View {
        HStack(alignment: .bottom) {
            Rectangle()
                .frame(width: 40, height: 40)
                .foregroundColor(.clear)

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
    }

    private func photoView() -> some View {
        Group {
            if post.mediaUrls.count > 1 {
                // Custom paging for multiple photos
                GeometryReader { geometry in
                    let itemWidth = mediaWidth + 10
                    HStack(spacing: 0) {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(Array(post.mediaUrls.enumerated()), id: \.element) { index, url in
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
                                    .frame(width: mediaWidth)
                                }
                            }
                            .padding(.horizontal, (geometry.size.width - mediaWidth) / 2)
                            .offset(x: self.dragOffset + self.dragState.translation)
                            .animation(.easeOut(duration: 0.2), value: dragOffset)
                            .gesture(
                                DragGesture()
                                    .updating($dragState) { value, state, _ in
                                        state = .dragging(translation: value.translation.width)
                                    }
                                    .onEnded { value in
                                        let itemWidthWithSpacing = mediaWidth + 10
                                        let totalItems = post.mediaUrls.count
                                        let predictedEndOffset = self.dragOffset + value.translation.width
                                        var newIndex = Int(round(-predictedEndOffset / itemWidthWithSpacing))
                                        newIndex = max(0, min(newIndex, totalItems - 1))

                                        self.currentIndex = newIndex
                                        let newOffset = -CGFloat(newIndex) * itemWidthWithSpacing
                                        self.dragOffset = newOffset
                                    }
                            )
                        }
                        .frame(width: geometry.size.width)
                    }
                    .onAppear {
                        self.scrollViewWidth = geometry.size.width
                        self.dragOffset = -CGFloat(self.currentIndex) * (mediaWidth + 10)
                    }
                }
                .frame(height: mediaHeight)
            } else {
                // Single photo
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
                .frame(maxWidth: .infinity)
            }
        }
    }

    private func restaurantInfoView() -> some View {
        VStack {
            NavigationLink(value: post.restaurant) {
                HStack(alignment: .center) {
                    VStack(alignment: .leading) {
                        Text(post.restaurant.name)
                            .font(.custom("MuseoSansRounded-300", size: 16))
                            .foregroundColor(.black)
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
                .padding(.horizontal)
                .padding(.top, 5)
            }
            .disabled(hideActionButtons)

            if isExpanded {
                RatingsView(post: post, isExpanded: $isExpanded)
                    .padding(.vertical, 5)
            }
        }
    }

    private func captionView() -> some View {
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
        .padding(.horizontal)
    }

    private func taggedUsersView() -> some View {
        Group {
            if !post.taggedUsers.isEmpty {
                Button(action: {
                    isTaggedSheetPresented.toggle()
                }) {
                    HStack {
                        Text("Went with:")
                            .font(.custom("MuseoSansRounded-300", size: 16))
                            .foregroundStyle(.black)
                            .bold()

                        ForEach(post.taggedUsers.prefix(3), id: \.id) { user in
                            UserCircularProfileImageView(profileImageUrl: user.profileImageUrl, size: .xxSmall)
                        }

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
                .disabled(hideActionButtons)
                .sheet(isPresented: $isTaggedSheetPresented) {
                    TaggedUsersSheetView(taggedUsers: post.taggedUsers)
                        .presentationDetents([.medium])
                }
            }
        }
        .padding(.horizontal)
    }

    private func interactionButtonsView() -> some View {
        HStack(spacing: 15) {
            Button {
                triggerHapticFeedback()
                handleLikeTapped()
            } label: {
                InteractionButtonView(icon: didLike ? "heart.fill" : "heart", count: post.likes, color: didLike ? Color("Colors/AccentColor") : .gray)
            }

            Button {
                showComments.toggle()
            } label: {
                InteractionButtonView(icon: "ellipsis.bubble", count: post.commentCount)
            }

            Button {
                triggerHapticFeedback()
                handleBookmarkTapped()
            } label: {
                InteractionButtonView(icon: didBookmark ? "bookmark.fill" : "bookmark", count: post.bookmarkCount, color: didBookmark ? Color("Colors/AccentColor") : .gray, width: 20, height: 20)
            }

            Button {
                showCollections.toggle()
            } label: {
                InteractionButtonView(icon: "folder.badge.plus", width: 24, height: 24)
            }

            Button {
                showShareView.toggle()
            } label: {
                InteractionButtonView(icon: "arrowshape.turn.up.right", width: 22, height: 21)
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
        .padding(.horizontal)
    }

    // MARK: - Helper Functions

    private func onAppear() {
        if checkLikes {
               Task {
                   post.didLike = try await PostService.shared.checkIfUserLikedPost(post)
                   post.didBookmark = await viewModel.checkIfUserBookmarkedPost(post)
               }
           }
           isCurrentVideoPlaying = false

           // Handle initial video playback based on the first media item
           handleIndexChange(currentIndex)
           if viewModel.selectedCommentId != nil {
               showComments = true
           }
    }

    private func handleScrollPositionChange() {
            if scrollPosition != post.id {
                pauseAllVideos()
            } else {
                handleIndexChange(currentIndex)
            }
        }

    private func handlePauseVideoChange(_ newValue: Bool) {
        if newValue {
            pauseAllVideos()
        } else {
            handleIndexChange(currentIndex)
        }
    }

    private func updateParsedCaption() {
        parsedCaption = parseCaption(post.caption)
    }

    private func handleOpenURL(_ url: URL) -> OpenURLAction.Result {
        if url.scheme == "user",
           let userId = url.host,
           let user = post.captionMentions.first(where: { $0.id == userId }) {
            selectedUser = user
            return .handled
        }
        return .systemAction
    }

    private func handleVisibleMediaChange(newValue: String?) {
        pauseAllVideos()

        if let newValue = newValue,
           let mediaItem = post.mixedMediaUrls?.first(where: { $0.id == newValue }),
           mediaItem.type == .video {
            playVideo(id: newValue)
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
        // If not found, create a new one
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
            let username = String(fullMatch.dropFirst())

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
                post.bookmarkCount += 1
                await viewModel.bookmark(post)
            }
        }
    }

    private func handleLikeTapped() {
        Task {
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
            didLike ? await viewModel.unlike(post) : await viewModel.like(post)
        }
    }
    private func handleIndexChange(_ index: Int) {
        pauseAllVideos()
        
        switch post.mediaType {
        case .mixed:
            guard let mixedMediaUrls = post.mixedMediaUrls, !mixedMediaUrls.isEmpty else {
                currentlyPlayingVideoId = nil
                return
            }
            
            let safeIndex = max(0, min(index, mixedMediaUrls.count - 1))
            
            if safeIndex < mixedMediaUrls.count {
                let mediaItem = mixedMediaUrls[safeIndex]
                
                if mediaItem.type == .video {
                    currentlyPlayingVideoId = mediaItem.id
                    playVideo(id: mediaItem.id)
                } else {
                    currentlyPlayingVideoId = nil
                }
            } else {
                currentlyPlayingVideoId = nil
            }
            
        case .video:
            if index == 0, let firstVideoId = videoCoordinators.first?.0 {
                currentlyPlayingVideoId = firstVideoId
                playVideo(id: firstVideoId)
            } else {
                currentlyPlayingVideoId = nil
            }
            
        default:
            currentlyPlayingVideoId = nil
        }
    }


    private func playVideoForCurrentIndex(_ index: Int) {
        if post.mediaType == .mixed, let mixedMediaUrls = post.mixedMediaUrls, !mixedMediaUrls.isEmpty {
            if index >= 0 && index < mixedMediaUrls.count {
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
}
struct CustomPagingView<Content: View>: View {
    let itemCount: Int
    let itemWidth: CGFloat
    let itemSpacing: CGFloat
    @Binding var currentIndex: Int
    let content: () -> Content

    @State private var offsetX: CGFloat = 0
    @GestureState private var dragOffsetX: CGFloat = 0

    init(itemCount: Int, itemWidth: CGFloat, itemSpacing: CGFloat = 10, currentIndex: Binding<Int>, @ViewBuilder content: @escaping () -> Content) {
        self.itemCount = itemCount
        self.itemWidth = itemWidth
        self.itemSpacing = itemSpacing
        self._currentIndex = currentIndex
        self.content = content
    }

    var body: some View {
        GeometryReader { geometry in
            let totalContentWidth = CGFloat(itemCount) * (itemWidth + itemSpacing) - itemSpacing
            let containerWidth = geometry.size.width
            let horizontalPadding = (containerWidth - itemWidth) / 2

            HStack(spacing: itemSpacing) {
                content()
                    .frame(width: itemWidth)
            }
            .padding(.horizontal, horizontalPadding)
            .offset(x: offsetX + dragOffsetX)
            .gesture(
                DragGesture()
                    .updating($dragOffsetX) { value, state, _ in
                        state = value.translation.width
                    }
                    .onEnded { value in
                        let itemWidthWithSpacing = itemWidth + itemSpacing
                        let predictedEndOffset = offsetX + value.predictedEndTranslation.width
                        var newIndex = Int(round(-predictedEndOffset / itemWidthWithSpacing))
                        newIndex = max(0, min(newIndex, itemCount - 1))

                        withAnimation(.spring()) {
                            currentIndex = newIndex
                            offsetX = -CGFloat(newIndex) * itemWidthWithSpacing
                        }
                    }
            )
            .onAppear {
                offsetX = -CGFloat(currentIndex) * (itemWidth + itemSpacing)
            }
            .onChange(of: currentIndex) { newIndex in
                withAnimation(.spring()) {
                    offsetX = -CGFloat(newIndex) * (itemWidth + itemSpacing)
                }
            }
        }
    }
}
struct PagingScrollView<Content: View>: UIViewRepresentable {
    let content: Content
    let itemWidth: CGFloat
    let itemSpacing: CGFloat
    let itemCount: Int
    @Binding var currentIndex: Int
    
    init(itemWidth: CGFloat, itemSpacing: CGFloat = 10, itemCount: Int, currentIndex: Binding<Int>, @ViewBuilder content: () -> Content) {
        self.content = content()
        self.itemWidth = itemWidth
        self.itemSpacing = itemSpacing
        self.itemCount = itemCount
        self._currentIndex = currentIndex
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIView(context: Context) -> UIScrollView {
        let scrollView = UIScrollView()
        scrollView.isPagingEnabled = false // We'll simulate paging
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.delegate = context.coordinator
        scrollView.decelerationRate = .fast
        
        // Create a UIHostingController to host SwiftUI content
        let hostingController = UIHostingController(rootView: content)
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        hostingController.view.backgroundColor = .clear
        
        scrollView.addSubview(hostingController.view)
        
        // Constraints for the content size
        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: scrollView.topAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            hostingController.view.heightAnchor.constraint(equalTo: scrollView.heightAnchor)
        ])
        
        // Set contentInset to center the items
        let horizontalInset = (UIScreen.main.bounds.width - itemWidth) / 2
        scrollView.contentInset = UIEdgeInsets(top: 0, left: horizontalInset, bottom: 0, right: horizontalInset)
        scrollView.contentOffset = CGPoint(x: -horizontalInset, y: 0)
        
        return scrollView
    }
    func updateUIView(_ scrollView: UIScrollView, context: Context) {
        // Update content size
        let totalItemWidth = itemWidth + itemSpacing
        let totalWidth = CGFloat(itemCount) * totalItemWidth - itemSpacing
        scrollView.contentSize = CGSize(width: totalWidth, height: scrollView.frame.size.height)
        
        // Update the hosting controller's frame
        if let hostingView = scrollView.subviews.first {
            hostingView.frame = CGRect(origin: .zero, size: CGSize(width: scrollView.contentSize.width, height: scrollView.frame.size.height))
        }
        
        // Update content offset if currentIndex changes programmatically
        let targetX = CGFloat(currentIndex) * totalItemWidth - scrollView.contentInset.left
        if abs(scrollView.contentOffset.x - targetX) > 0.5 {
            scrollView.setContentOffset(CGPoint(x: targetX, y: 0), animated: false)
        }
    }
    
    class Coordinator: NSObject, UIScrollViewDelegate {
        var parent: PagingScrollView
        var isUserScrolling = false
        var targetIndex: Int = 0

        init(_ parent: PagingScrollView) {
            self.parent = parent
        }

        func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
            isUserScrolling = true
        }

        func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
            let pageWidth = self.parent.itemWidth + self.parent.itemSpacing
            let offsetX = scrollView.contentOffset.x + scrollView.contentInset.left
            var index = Int(round(offsetX / pageWidth))

            let velocityX = velocity.x

            if velocityX > 0.2 {
                // Swiping to the left (next item)
                index = min(index + 1, self.parent.itemCount - 1)
            } else if velocityX < -0.2 {
                // Swiping to the right (previous item)
                index = max(index - 1, 0)
            } else {
                // Not enough velocity, snap to nearest
                index = Int(round(offsetX / pageWidth))
            }

            let newOffsetX = CGFloat(index) * pageWidth - scrollView.contentInset.left
            targetContentOffset.pointee.x = newOffsetX

            // Store the target index to update the currentIndex later
            self.targetIndex = index
            isUserScrolling = false
        }

        func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
            // Update currentIndex after scrolling animation ends
            DispatchQueue.main.async {
                self.parent.currentIndex = self.targetIndex
            }
        }

        func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
            // Update currentIndex after decelerating
            DispatchQueue.main.async {
                self.parent.currentIndex = self.targetIndex
            }
        }
    }
}

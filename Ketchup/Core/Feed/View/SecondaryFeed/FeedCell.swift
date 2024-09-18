//
//  FeedCell.swift
//  Foodi
//
//  Created by Jack Robinson on 2/1/24.
//

//
//  FeedCell.swift
//  Foodi
//
//  Created by Jack Robinson on 2/1/24.
//

import SwiftUI
import AVKit
import Photos
import Kingfisher
import FirebaseAuth
import UIKit
struct FeedCell: View {
    @Binding var post: Post
    @State private var isPlaying: Bool = false
    @State private var currentVideoId: String?
    @State private var videoCoordinators: [(String, VideoPlayerCoordinator)] = []
    @ObservedObject var viewModel: FeedViewModel
    @State private var expandCaption = false
    @State private var showComments = false
    @State private var showShareView = false
    @State private var showCollections = false
    @State private var videoConfigured = false
    private var didLike: Bool { return post.didLike }
    @Binding var scrollPosition: String?
    @Binding var pauseVideo: Bool
    @State private var showingOptionsSheet = false
    @State private var currentImageIndex =  0
    @State var isDragging = false
    @State var dragDirection = "left"
    var hideFeedOptions: Bool
    @Environment(\.dismiss) var dismiss
    @State var showHeartOverlay = false
    @State private var offset: CGFloat = 0
    @GestureState private var dragOffset: CGFloat = 0
    @State private var isTaggedSheetPresented = false
    @State private var parsedCaption: AttributedString?
    @State private var currentlyPlayingVideoId: String?
    @State private var isCurrentVideoPlaying = false
    let mediaHeight = UIScreen.main.bounds.width * 1.333
    let mediaWidth = UIScreen.main.bounds.width
    @State private var currentIndex: Int = 0
    var checkLikes: Bool
    @State private var selectedUser: PostUser?
    @State private var isShowingProfileSheet = false
    var overallRating: Double? {
        let ratings = [post.foodRating, post.atmosphereRating, post.valueRating, post.serviceRating].compactMap { $0 }
        guard !ratings.isEmpty else { return nil }
        return ratings.reduce(0, +) / Double(ratings.count)
    }
    
    private var didBookmark: Bool {
        return post.didBookmark
    }
    
    init(post: Binding<Post>,
         viewModel: FeedViewModel,
         scrollPosition: Binding<String?>,
         pauseVideo: Binding<Bool>,
         hideFeedOptions: Bool,
         checkLikes: Bool = false) {
        
        self._post = post
        self.viewModel = viewModel
        self._scrollPosition = scrollPosition
        self._pauseVideo = pauseVideo
        self.hideFeedOptions = hideFeedOptions
        self.checkLikes = checkLikes
        
        let coordinators = VideoPrefetcher.shared.getPlayerItems(for: post.wrappedValue)
        self._videoCoordinators = State(initialValue: coordinators)
    }
    
    var drag: some Gesture {
        DragGesture(minimumDistance: 5)
            .onChanged { _ in self.isDragging = true }
            .onEnded { endedGesture in
                if (endedGesture.location.x - endedGesture.startLocation.x) > 0 {
                    self.dragDirection = "left"
                    if self.currentImageIndex > 0 {
                        withAnimation(.easeInOut) {
                            self.currentImageIndex -= 1
                        }
                    } else {
                        viewModel.initialPrimaryScrollPosition = scrollPosition
                        dismiss()
                    }
                } else {
                    self.dragDirection = "right"
                }
                self.isDragging = false
            }
    }
    
    var body: some View {
        ZStack {
            
            VStack() {
                Spacer()
                if post.mediaType == .mixed, let mixedMediaUrls = post.mixedMediaUrls {
                    
                        CustomHorizontalScrollView(
                            content: {
                                HStack(spacing: 0) {
                                    ForEach(Array(mixedMediaUrls.enumerated()), id: \.element.id) { index, mediaItem in
                                        mediaItemView(for: mediaItem)
                                    }
                                }
                            },
                            currentIndex: $currentIndex,
                            itemCount: mixedMediaUrls.count,
                            itemWidth: mediaWidth,
                            initialIndex: viewModel.startingImageIndex,
                            onDismiss: {
                                viewModel.initialPrimaryScrollPosition = scrollPosition
                                dismiss()
                            }
                        )
                        .onAppear { viewModel.startingImageIndex = 0 }
                        .frame(height: mediaHeight)
                        .overlay(alignment: .top) { IndexIndicatorView(currentIndex: currentIndex, totalCount: mixedMediaUrls.count)
                        }
                        .onTapGesture{
                            withAnimation(.spring()) { expandCaption.toggle() }
                        }
                        
                    
                } else if post.mediaType == .video {
                    ForEach(videoCoordinators.prefix(1), id: \.0) { mediaItemId, coordinator in
                        singleMediaItemView(coordinator: coordinator)
                    }
                } else if post.mediaType == .photo {
                    if !post.mediaUrls.isEmpty {
                        mediaScrollView(items: post.mediaUrls.map { MixedMediaItem(id: UUID().uuidString, url: $0, type: .photo) })
                    }
                }
                Spacer(minLength: 0)
            }
            .padding(.bottom, 137)
        }
        .padding(.top, 35)
        .overlay(heartOverlay)
        .onTapGesture(count: 2) {
            handleLikeTapped()
        }
        .onTapGesture {
            toggleVideoPlayback()
        }
        .onChange(of: currentlyPlayingVideoId) { newValue in
            if let newValue = newValue,
               let coordinator = videoCoordinators.first(where: { $0.0 == newValue })?.1 {
                pauseAllVideos()
                coordinator.play()
                isCurrentVideoPlaying = true
            }
        }
        .onChange(of: scrollPosition) {newValue in
            if scrollPosition != post.id {
                pauseAllVideos()
            } else {
                handleIndexChange(currentIndex)
            }
        }
        .gesture(drag)
        .onAppear {
            handleOnAppear()
        }
        .onDisappear {
            pauseAllVideos()
        }
        .onChange(of: pauseVideo) {newValue in
            if pauseVideo {
                pauseAllVideos()
            } else {
                handleIndexChange(currentIndex)
            }
        }
        .sheet(isPresented: $showComments) {
            CommentsView(post: $post, feedViewModel: viewModel)
                .presentationDetents([.height(UIScreen.main.bounds.height * 0.65)])
                .onAppear {
                    pauseAllVideos()
                }
                .onDisappear {
                    handleIndexChange(currentIndex)
                }
        }
        .sheet(isPresented: $showShareView) {
            ShareView(post: post, currentMediaIndex: currentIndex)
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
        .onChange(of: currentIndex) {newValue in
            handleIndexChange(newValue)
        }
        .overlay(
            GeometryReader { geometry in
                VStack {
                    Spacer()
                    captionAndRatingsBox
                        .animation(.spring(), value: expandCaption)
                }
                .padding(.bottom, 50)
            }
        )
        .sheet(isPresented: $isTaggedSheetPresented) {
            TaggedUsersSheetView(taggedUsers: post.taggedUsers)
                .onAppear {
                    pauseAllVideos()
                }
                .presentationDetents([.height(UIScreen.main.bounds.height * 0.5)])
        }
        .sheet(item: $selectedUser) { user in
            NavigationStack {
                ProfileView(uid: user.id)
            }
            .onAppear {
                pauseAllVideos()
            }
            .onDisappear {
                handleIndexChange(currentIndex)
            }
        }
    }
    
    private func videoControlButtons(for videoId: String) -> some View {
        HStack(spacing: 15) {
            Button(action: {
                togglePlayPause()
            }) {
                Image(systemName: isCurrentVideoPlaying && currentlyPlayingVideoId == videoId ? "pause.circle.fill" : "play.circle.fill")
                    .resizable()
                    .frame(width: 30, height: 30)
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.5), radius: 3, x: 0, y: 0)
            }
            Button(action: {
                toggleMute()
            }) {
                Image(systemName: viewModel.isMuted ? "speaker.slash.circle.fill" : "speaker.wave.2.circle.fill")
                    .resizable()
                    .frame(width: 30, height: 30)
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.5), radius: 3, x: 0, y: 0)
            }
        }
    }
    
    private var taggedUsersButton: some View {
        Group {
            if !post.taggedUsers.isEmpty {
                Button {
                    isTaggedSheetPresented.toggle()
                } label: {
                    Image(systemName: "person.2.circle.fill")
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.white, .red)
                        .font(.system(size: 30))
                        .shadow(color: .black.opacity(0.5), radius: 3, x: 0, y: 0)
                }
            }
        }
    }
    
    private func mediaScrollView(items: [MixedMediaItem]) -> some View {
        CustomHorizontalScrollView(
            content: {
                HStack(spacing: 0) {
                    ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                        mediaItemView(for: item)
                    }
                }
            },
            currentIndex: $currentIndex,
            itemCount: items.count,
            itemWidth: mediaWidth,
            initialIndex: viewModel.startingImageIndex,
            onDismiss: { dismiss() }
        )
        .onAppear { viewModel.startingImageIndex = 0 }
        .frame(height: mediaHeight)
        .overlay(alignment: .top) {
            IndexIndicatorView(currentIndex: currentIndex, totalCount: items.count)
                .padding(.top, 8)
        }
    }
    
    private var captionAndRatingsBox: some View {
        VStack(alignment: .leading, spacing: 7) {
            
            actionButtons
                
            if post.repost {
                HStack(spacing: 1){
                    Image(systemName: "arrow.2.squarepath")
                        .foregroundStyle(.black)
                        .font(.custom("MuseoSansRounded-300", size: 16))
                    Text("reposted")
                        .font(.custom("MuseoSansRounded-300", size: 14))
                        .fontWeight(.semibold)
                        .foregroundStyle(.black)
                        
                        
                }
            }
                       
                
            HStack {
                let restaurant = post.restaurant
                NavigationLink(value: restaurant) {
                    RestaurantRectangleProfileImageView(imageUrl: restaurant.profileImageUrl, size: .large)
                }
                VStack(alignment: .leading) {
                    NavigationLink(value: restaurant) {
                        Text("\(restaurant.name)")
                            .font(.custom("MuseoSansRounded-300", size: 18))
                            .bold()
                            .multilineTextAlignment(.leading)
                            .minimumScaleFactor(0.5)
                            .lineLimit(1)
                    }
                    Text("\(restaurant.city ?? ""), \(restaurant.state ?? "")")
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                        .font(.custom("MuseoSansRounded-300", size: 14))
                    NavigationLink(value: post.user) {
                        Text("by \(post.user.fullname)")
                            .font(.custom("MuseoSansRounded-300", size: 14))
                            .fontWeight(.semibold)
                            .foregroundStyle(Color("Colors/AccentColor"))
                            .bold()
                            .multilineTextAlignment(.leading)
                            .minimumScaleFactor(0.5)
                            .lineLimit(1)
                    }
                    .disabled(post.user.username == "ketchup_media")
                    if let timestamp = post.timestamp {
                        Text(getTimeElapsedString(from: timestamp))
                            .font(.custom("MuseoSansRounded-300", size: 10))
                            .foregroundColor(.gray)
                    }
                }
                Spacer()
                if let overallRating = overallRating {
                    Button(action: {
                        withAnimation(.spring()) { expandCaption.toggle() }
                    }) {
                        HStack(alignment: .center, spacing: 4) {
                            ScrollFeedOverallRatingView(rating: overallRating, font: .black)
                            
                            Image(systemName: expandCaption ? "chevron.down" : "chevron.right")
                                .foregroundColor(.gray)
                                .frame(width: 25)
                                .rotationEffect(.degrees(expandCaption ? 0 : -90))
                                .animation(.easeInOut(duration: 0.3), value: expandCaption)
                        }
                    }
                }
            }
            
            Button(action: {
                withAnimation(.spring()) { expandCaption.toggle() }
            }) {
                VStack(alignment: .leading, spacing: 7) {
                    if let parsed = parsedCaption {
                        Text(parsed)
                            .font(.custom("MuseoSansRounded-300", size: 16))
                            .lineLimit(expandCaption ? 50 : 1)
                            .multilineTextAlignment(.leading)
                            .environment(\.openURL, OpenURLAction { url in
                                if url.scheme == "user",
                                   let userId = url.host,
                                   let user = post.captionMentions.first(where: { $0.id == userId }) {
                                    selectedUser = user
                                    isShowingProfileSheet = true
                                    return .handled
                                }
                                return .systemAction
                            })
                    } else {
                        Text(post.caption)
                            .font(.custom("MuseoSansRounded-300", size: 16))
                            .onAppear {
                                parsedCaption = parseCaption(post.caption)
                            }
                            .lineLimit(expandCaption ? 50 : 1)
                            .multilineTextAlignment(.leading)
                    }
                    
                    if !expandCaption {
                        Text("See more...")
                            .font(.custom("MuseoSansRounded-300", size: 10))
                            .foregroundColor(Color("Colors/AccentColor"))
                    } else {
                        if !post.taggedUsers.isEmpty {
                            Button(action: {
                                isTaggedSheetPresented.toggle()
                            }) {
                                HStack {
                                    Text("Went with:")
                                        .font(.custom("MuseoSansRounded-300", size: 16))
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
                                .frame(height: 15)
                            }
                            .padding(.vertical, 3)
                        }
                        
                        VStack(alignment: .leading, spacing: 5) {
                            if let foodRating = post.foodRating {
                                RatingSlider(rating: foodRating, label: "Food", isOverall: false, fontColor: .black)
                            }
                            if let atmosphereRating = post.atmosphereRating {
                                RatingSlider(rating: atmosphereRating, label: "Atmosphere", isOverall: false, fontColor: .black)
                            }
                            if let valueRating = post.valueRating {
                                RatingSlider(rating: valueRating, label: "Value", isOverall: false, fontColor: .black)
                            }
                            if let serviceRating = post.serviceRating {
                                RatingSlider(rating: serviceRating, label: "Service", isOverall: false, fontColor: .black)
                            }
                        }
                        
                        
                        
                        Text("See less...")
                            .font(.custom("MuseoSansRounded-300", size: 10))
                            .foregroundColor(Color("Colors/AccentColor"))
                    }
                }
                .onChange(of: post.caption) {newValue in
                    parsedCaption = parseCaption(post.caption)
                }
            }
        }
        .padding(.horizontal)
        .padding(.top, 10)
        .font(.custom("MuseoSansRounded-300", size: 16))
        .foregroundStyle(.black)
        .background(Color("Colors/HingeGray"))
        .frame(width: UIScreen.main.bounds.width)
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
    
    private func getVideoCoordinator(for mediaItemId: String) -> VideoPlayerCoordinator {
        if let coordinator = videoCoordinators.first(where: { $0.0 == mediaItemId }) {
            return coordinator.1
        }
        let newCoordinator = VideoPlayerCoordinator()
        videoCoordinators.append((mediaItemId, newCoordinator))
        return newCoordinator
    }
    
    private var actionButtons: some View {
        HStack(spacing: 25) {
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
            
            if viewModel.showBookmarks {
                Button {
                    handleBookmarkTapped()
                    triggerHapticFeedback()
                } label: {
                    InteractionButtonView(icon: didBookmark ? "bookmark.fill" : "bookmark", count: post.bookmarkCount, color: didBookmark ? Color("Colors/AccentColor") : .gray, width: 20, height: 20)
                }
            }
            if viewModel.showBookmarks {
                Button {
                    showCollections.toggle()
                } label: {
                    InteractionButtonView(icon: "folder.badge.plus", width: 24, height: 24)
                }
            }
            
            Button {
                showShareView.toggle()
            } label: {
                InteractionButtonView(icon: "arrowshape.turn.up.right", width: 22, height: 22)
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
        }
    }
    
    private func handleIndexChange(_ index: Int) {
        pauseAllVideos()
        
        if post.mediaType == .mixed, let mixedMediaUrls = post.mixedMediaUrls {
            let safeIndex = min(max(index, 0), mixedMediaUrls.count - 1)
            let mediaItem = mixedMediaUrls[safeIndex]
            
            if mediaItem.type == .video {
                currentlyPlayingVideoId = mediaItem.id
                playVideo(id: mediaItem.id)
            } else {
                currentlyPlayingVideoId = nil
            }
        } else if post.mediaType == .video {
            if let firstVideoId = videoCoordinators.first?.0 {
                currentlyPlayingVideoId = firstVideoId
                playVideo(id: firstVideoId)
            }
        } else {
            currentlyPlayingVideoId = nil
        }
    }
    
    private func mediaItemView(for mediaItem: MixedMediaItem) -> some View {
        ZStack {
            if mediaItem.type == .photo {
                ZoomableImage(imageURL: mediaItem.url)
                    .frame(width: mediaWidth, height: mediaHeight)
                    .cornerRadius(10)
            } else if mediaItem.type == .video {
                ZoomableVideoPlayer(videoCoordinator: getVideoCoordinator(for: mediaItem.id))
                    .frame(width: mediaWidth, height: mediaHeight)
                    .cornerRadius(10)
                    .id(mediaItem.id)
            }
            
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    if mediaItem.type == .video {
                        videoControlButtons(for: mediaItem.id)
                    }
                    taggedUsersButton
                }
                .padding()
            }
        }
        .frame(width: mediaWidth)
    }
    
    @ViewBuilder
    private func singleMediaItemView(coordinator: VideoPlayerCoordinator? = nil, imageURL: String? = nil) -> some View {
        ZStack {
            if let coordinator = coordinator {
                ZoomableVideoPlayer(videoCoordinator: coordinator)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.width * 1.333)
            } else if let imageURL = imageURL {
                ZoomableImage(imageURL: imageURL)
                    .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.width * 1.333)
            }
            
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    if coordinator != nil, let videoId = videoCoordinators.first(where: { $0.1 === coordinator })?.0 {
                        videoControlButtons(for: videoId)
                    }
                    taggedUsersButton
                }
                .padding()
            }
        }
    }
    
    private var heartOverlay: some View {
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
    
    private func toggleVideoPlayback() {
        guard post.mediaType == .video || post.mediaType == .mixed else { return }
        
        let videoToToggle: (String, VideoPlayerCoordinator)?
        
        if post.mediaType == .mixed {
            videoToToggle = videoCoordinators.first(where: { $0.0 == currentlyPlayingVideoId })
        } else {
            videoToToggle = videoCoordinators.first
        }
        
        if let (videoId, coordinator) = videoToToggle {
            if isCurrentVideoPlaying {
                coordinator.pause()
                isCurrentVideoPlaying = false
            } else {
                pauseAllVideos()
                coordinator.play()
                isCurrentVideoPlaying = true
                currentlyPlayingVideoId = videoId
            }
        }
    }
    
    private func handleOnAppear() {
        if checkLikes {
            Task {
                post.didLike = try await PostService.shared.checkIfUserLikedPost(post)
                post.didBookmark = await viewModel.checkIfUserBookmarkedPost(post)
            }
        }
        
        if post.mediaType == .mixed || post.mediaType == .video {
            for (_, coordinator) in videoCoordinators {
                coordinator.player.isMuted = viewModel.isMuted
            }
            
            handleIndexChange(0)
            if viewModel.selectedCommentId != nil {
                showComments = true
            }
        }
    }
    
    private func playVideo(id: String) {
        if let coordinator = videoCoordinators.first(where: { $0.0 == id })?.1 {
            coordinator.play()
            isCurrentVideoPlaying = true
            currentVideoId = id
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
    
    private func pauseAllVideos() {
        for (_, coordinator) in videoCoordinators {
            coordinator.pause()
        }
        isCurrentVideoPlaying = false
    }
    
    private func handleBookmarkTapped() {
        Task {
            if post.didBookmark {
                await viewModel.unbookmark(post)
                //ost.bookmarkCount -= 1
            } else {
                await viewModel.bookmark(post)
                post.bookmarkCount += 1
            }
        }
    }
    
    private var taggedUsersOverlay: some View {
        Group {
            if !post.taggedUsers.isEmpty {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button {
                            isTaggedSheetPresented.toggle()
                        } label: {
                            Image(systemName: "person.2.circle.fill")
                                .symbolRenderingMode(.palette)
                                .foregroundStyle(.white, .red)
                                .font(.system(size: 30))
                        }
                    }
                }
                .padding()
            }
        }
    }
    
    private var imageIndexIndicator: some View {
        Group {
            if post.mediaUrls.count > 1 {
                VStack {
                    HStack(spacing: 6) {
                        ForEach(0..<post.mediaUrls.count, id: \.self) { index in
                            Circle()
                                .fill(index == currentImageIndex ? Color("Colors/AccentColor") : Color.gray)
                                .frame(width: 10, height: 10)
                        }
                    }
                    .padding(.top, 30)
                    Spacer()
                }
            }
        }
    }
}

struct IndexIndicatorView: View {
    var currentIndex: Int
    var totalCount: Int
    
    var body: some View {
        if totalCount > 1 {
            HStack(spacing: 8) {
                ForEach(0..<totalCount, id: \.self) { index in
                    Circle()
                        .fill(index == currentIndex ? Color.white : Color.white.opacity(0.5))
                        .frame(width: 8, height: 8)
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(Color.black.opacity(0.3))
            .cornerRadius(20)
            .padding(.top, 12)
        }
    }
}

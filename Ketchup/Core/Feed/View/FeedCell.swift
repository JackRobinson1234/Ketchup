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
    @StateObject var videoCoordinator: VideoPlayerCoordinator
    @ObservedObject var viewModel: FeedViewModel
    @State private var expandCaption = false
    @State private var showComments = false
    @State private var showShareView = false
    @State private var showRecipe = false
    @State private var showCollections = false
    @State private var videoConfigured = false
    private var didLike: Bool { return post.didLike }
    @Binding var scrollPosition: String?
    @Binding var pauseVideo: Bool
    @State private var showingOptionsSheet = false
    @State private var showingRepostSheet = false
    @State private var currentImageIndex = 0
    @State var isDragging = false
    @State var dragDirection = "left"
    var hideFeedOptions: Bool
    @Environment(\.dismiss) var dismiss
    @State var showHeartOverlay = false
    @State private var offset: CGFloat = 0
    @GestureState private var dragOffset: CGFloat = 0
    var checkLikes: Bool
    var overallRating: Double {
        let ratings = [post.foodRating, post.atmosphereRating, post.valueRating, post.serviceRating].compactMap { $0 }
        guard !ratings.isEmpty else { return 0 }
        return ratings.reduce(0, +) / Double(ratings.count)
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
        
        if post.wrappedValue.mediaType == .video {
            let coordinator = VideoPrefetcher.shared.getPlayerItem(for: post.wrappedValue)
            self._videoCoordinator = StateObject(wrappedValue: coordinator)
        } else {
            // Initialize with a dummy coordinator for non-video posts
            self._videoCoordinator = StateObject(wrappedValue: VideoPlayerCoordinator())
        }
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
                    if self.currentImageIndex < post.mediaUrls.count - 1 {
                        withAnimation(.easeInOut) {
                            self.currentImageIndex += 1
                        }
                    }
                }
                self.isDragging = false
            }
    }

    var body: some View {
        ZStack {
            // Video and Photo handling
           Color("Colors/HingeGray")
                .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
                .containerRelativeFrame([.horizontal, .vertical])
            if post.mediaType == .video {
                VideoPlayerView(coordinator: videoCoordinator, videoGravity: .resizeAspectFill)
                    .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
                    .containerRelativeFrame([.horizontal, .vertical])
            } else if post.mediaType == .photo {
                GeometryReader { geometry in
                                   HStack(spacing: 0) {
                                       ForEach(0..<post.mediaUrls.count, id: \.self) { index in
                                           KFImage(URL(string: post.mediaUrls[index]))
                                               .resizable()
                                               .scaledToFit()
                                               .frame(width: geometry.size.width, height: geometry.size.height)
                                               .cornerRadius(20)
                                       }
                                   }
                                   .offset(x: -CGFloat(currentImageIndex) * geometry.size.width + offset + dragOffset)
                                   .animation(.spring(), value: offset)
//                                   .gesture(
//                                       drag
//                                   )
                               }
                               .overlay(
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
                                               .padding(.top, 130)
                                               Spacer()
                                           }
                                       }
                                   }
                               )           
            }

            ZStack(alignment: .bottom) {
                VStack {
                    Spacer()
                    HStack(alignment: .bottom) {
                        // Caption and Ratings Box
                        captionAndRatingsBox
                        Spacer()
                        // Right-hand VStack with actions
                        actionButtons
                    }
                }

                // Video Slider
                if post.mediaType == .video {
                    videoSlider
                }
            }
            .padding(.bottom, viewModel.isContainedInTabBar ? 75 : 30)
        }
        .overlay(heartOverlay)
        .onTapGesture(count: 2) {
            handleLikeTapped()
        }
        .onTapGesture {
            toggleVideoPlayback()
        }
        .gesture(drag)
        .onAppear {
            handleOnAppear()
        }
        .onDisappear {
            videoCoordinator.pause()
        }
        .sheet(isPresented: $showComments) {
            CommentsView(post: $post)
                .presentationDetents([.height(UIScreen.main.bounds.height * 0.65)])
                .onDisappear { Task { videoCoordinator.play() } }
        }
        .sheet(isPresented: $showShareView) {
            ShareView(post: post, currentImageIndex: currentImageIndex)
                .presentationDetents([.height(UIScreen.main.bounds.height * 0.15)])
                .onDisappear { Task { videoCoordinator.play() } }
        }
        .sheet(isPresented: $showCollections) {
            if let currentUser = AuthService.shared.userSession {
                AddItemCollectionList(user: currentUser, post: post)
            }
        }
        .sheet(isPresented: $showingOptionsSheet) {
            PostOptionsSheet(post: $post, viewModel: viewModel)
                .presentationDetents([.height(UIScreen.main.bounds.height * 0.15)])
        }
        .sheet(isPresented: $showingRepostSheet) {
            RepostView(viewModel: viewModel, post: post)
                .presentationDetents([.height(UIScreen.main.bounds.height * 0.35)])
        }
        .onChange(of: scrollPosition) { oldValue, newValue in
            handleScrollPositionChange(newValue: newValue)
        }
        .onChange(of: pauseVideo) { oldValue, newValue in
            handlePauseVideoChange(newValue: newValue)
        }
    }

    private var captionAndRatingsBox: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack {
                let restaurant = post.restaurant
                NavigationLink(value: restaurant) {
                    RestaurantCircularProfileImageView(imageUrl: restaurant.profileImageUrl, size: .large)
                }
                VStack(alignment: .leading) {
                    NavigationLink(value: restaurant) {
                        Text("\(restaurant.name)")
                            .font(.custom("MuseoSansRounded-300", size: 20))
                            .bold()
                            .multilineTextAlignment(.leading)
                    }
                    Text("\(restaurant.city ?? ""), \(restaurant.state ?? "")")
                    NavigationLink(value: post.user) {
                        Text("by \(post.user.fullname)")
                            .font(.custom("MuseoSansRounded-300", size: 16))
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                            .bold()
                            .multilineTextAlignment(.leading)
                    }
                    .disabled(post.user.username == "ketchup_media")
                    
                }
            }
            if let timestamp = post.timestamp {
                Text(getTimeElapsedString(from: timestamp))
                    .font(.custom("MuseoSansRounded-300", size: 10))
                    .foregroundColor(Color("Colors/HingeGray"))
            }
            
            // Overall rating
            
            Button(action: {
                withAnimation(.snappy) { expandCaption.toggle() }
            }) {
                VStack(alignment: .leading, spacing: 7){
                    Text(post.caption)
                        .lineLimit(expandCaption ? 50 : 1)
                        .font(.custom("MuseoSansRounded-300", size: 16))
                        .multilineTextAlignment(.leading)
                    
                    FeedOverallRatingView(rating: overallRating, font: .white)
                    
                    
                    if !expandCaption {
                        
                        Text("See more...")
                            .font(.custom("MuseoSansRounded-300", size: 10))
                            .foregroundColor(Color(.white))
                    }
                    else {
                        
                        // Other ratings
                        VStack(alignment: .leading, spacing: 5) {
                            if let foodRating = post.foodRating {
                                RatingSlider(rating: foodRating, label: "Food", isOverall: false, fontColor: .white)
                            }
                            if let atmosphereRating = post.atmosphereRating {
                                RatingSlider(rating: atmosphereRating, label: "Atmosphere", isOverall: false, fontColor: .white)
                            }
                            if let valueRating = post.valueRating {
                                RatingSlider(rating: valueRating, label: "Value", isOverall: false, fontColor: .white)
                            }
                            if let serviceRating = post.serviceRating {
                                RatingSlider(rating: serviceRating, label: "Service", isOverall: false, fontColor: .white)
                            }
                        }
                        
                        Text("See less...")
                            .font(.custom("MuseoSansRounded-300", size: 10))
                            .foregroundColor(Color(.white))
                    }
                }
            }
                .padding(.bottom)
                
                
            }
        
        .padding(.horizontal)
        .background(RoundedRectangle(cornerRadius: 10).fill(Color.black.opacity(0.3)))
        .font(.custom("MuseoSansRounded-300", size: 16))
        .foregroundStyle(.white)
        .padding(.horizontal)
    }


    private var actionButtons: some View {
        VStack(spacing: 28) {
            NavigationLink(value: post.user) {
                UserCircularProfileImageView(profileImageUrl: post.user.profileImageUrl, size: .medium)
            }
            .disabled(post.user.username == "ketchup_media")
            Button {
                videoCoordinator.pause()
                showingOptionsSheet = true
            } label: {
                ZStack {
                    Rectangle().fill(.clear).frame(width: 28, height: 28)
                    Image(systemName: "ellipsis")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 6, height: 6)
                        .foregroundStyle(.white)
                }
                .shadow(color: .gray, radius: 1, x: 0, y: 0)
            }
            if let user = Auth.auth().currentUser?.uid, post.user.id != user {
                Button {
                    showingRepostSheet.toggle()
                } label: {
                    VStack {
                        Image(systemName: "arrow.2.squarepath")
                            .resizable()
                            .scaledToFill()
                            .frame(width: 28, height: 28)
                            .foregroundStyle(.white)
                            .rotationEffect(.degrees(90))
                        Text("\(post.repostCount)")
                            .font(.custom("MuseoSansRounded-300", size: 10))
                            .fontWeight(.bold)
                    }
                    .shadow(color: .gray, radius: 1, x: 0, y: 0)
                    .foregroundStyle(.white)
                }
            }
            Button {
                videoCoordinator.pause()
                showCollections.toggle()
            } label: {
                FeedCellActionButtonView(imageName: "folder.fill.badge.plus")
            }
            Button {
                handleLikeTapped()
            } label: {
                FeedCellActionButtonView(imageName: didLike ? "heart.fill" : "heart.fill",
                                         value: post.likes,
                                         tintColor: didLike ? Color("Colors/AccentColor") : .white)
            }
            Button {
                videoCoordinator.pause()
                showComments.toggle()
            } label: {
                FeedCellActionButtonView(imageName: "ellipsis.bubble.fill", value: post.commentCount)
            }
            Button {
                videoCoordinator.pause()
                showShareView.toggle()
            } label: {
                Image(systemName: "arrowshape.turn.up.right.fill")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 28, height: 28)
                    .foregroundStyle(.white)
                    .shadow(color: .gray, radius: 1, x: 0, y: 0)
            }
        }
        .padding(.horizontal)
    }
    
    private var videoSlider: some View {
        let totalTime = videoCoordinator.duration.isFinite ? max(videoCoordinator.duration, 0) : 0
        return Slider(value: $videoCoordinator.currentTime, in: 0...totalTime, onEditingChanged: sliderEditingChanged)
            .onAppear {
                let clearCircleImage = UIImage.clearCircle(radius: 15, lineWidth: 1, color: .clear)
                UISlider.appearance().setThumbImage(clearCircleImage, for: .normal)
            }
            .offset(y: 40)
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
        guard post.mediaType == .video else { return }
        let player = videoCoordinator.player
        switch player.timeControlStatus {
        case .paused:
            videoCoordinator.play()
        case .waitingToPlayAtSpecifiedRate:
            break
        case .playing:
            videoCoordinator.pause()
        @unknown default:
            break
        }
    }
    
    private func handleScrollPositionChange(newValue: String?) {
        guard post.mediaType == .video else { return }
        if newValue == post.id {
            videoCoordinator.replay()
        } else {
            videoCoordinator.pause()
        }
    }
    
    private func handlePauseVideoChange(newValue: Bool) {
        guard post.mediaType == .video else { return }
        if scrollPosition == post.id || viewModel.posts.first?.id == post.id && scrollPosition == nil {
            if newValue == true {
                videoCoordinator.pause()
            } else {
                videoCoordinator.play()
            }
        }
    }
    
    private func handleOnAppear() {
        if checkLikes{
            Task{
                post.didLike = try await PostService.shared.checkIfUserLikedPost(post)
            }
        }
        if post.mediaType == .video {
            if let firstPost = viewModel.posts.first, firstPost.id == post.id && scrollPosition == nil {
                videoCoordinator.replay()
            }
        }
        
        if viewModel.startingPostId == post.id, post.mediaType == .photo {
            self.currentImageIndex = viewModel.startingImageIndex
            viewModel.startingPostId = ""
            viewModel.startingImageIndex = 0
        } else if viewModel.startingPostId == post.id, post.mediaType == .video {
            Task { videoCoordinator.play() }
        }
    }
    
    private func sliderEditingChanged(_ editingStarted: Bool) {
        if editingStarted {
            videoCoordinator.pause()
        } else {
            videoCoordinator.seekToTime(seconds: videoCoordinator.currentTime)
            videoCoordinator.play()
        }
    }
}

//MARK: Photo Library Access
func requestPhotoLibraryAccess(completion: @escaping (Bool) -> Void) {
    PHPhotoLibrary.requestAuthorization { status in
        switch status {
        case .authorized:
            completion(true)
        case .denied, .restricted, .notDetermined:
            completion(false)
        case .limited:
            completion(true)
        @unknown default:
            completion(false)
        }
    }
}

#Preview {
    FeedCell(
        post: .constant(DeveloperPreview.posts[0]),
        viewModel: FeedViewModel(),
        scrollPosition: .constant(""),
        pauseVideo: .constant(true),
        hideFeedOptions: true
    )
}

extension UIImage {
    static func clearCircle(radius: CGFloat, lineWidth: CGFloat, color: UIColor = .clear) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(CGSize(width: radius * 2, height: radius * 2), false, 0.0)
        defer { UIGraphicsEndImageContext() }
        guard let context = UIGraphicsGetCurrentContext() else { return nil }

        context.setLineWidth(lineWidth)
        context.setStrokeColor(color.cgColor)
        let rectangle = CGRect(x: lineWidth / 2, y: lineWidth / 2, width: radius * 2 - lineWidth, height: radius * 2 - lineWidth)
        context.addEllipse(in: rectangle)
        context.strokePath()

        return UIGraphicsGetImageFromCurrentImageContext()?.withRenderingMode(.alwaysOriginal)
    }
}

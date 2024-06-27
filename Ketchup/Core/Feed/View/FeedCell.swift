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
    @StateObject private var videoCoordinator: VideoPlayerCoordinator
    @ObservedObject var viewModel: FeedViewModel
    @State private var expandCaption = false
    @State private var showComments = false
    @State private var showShareView = false
    @State private var showCollections = false
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
    
    init(post: Binding<Post>, viewModel: FeedViewModel, scrollPosition: Binding<String?>, pauseVideo: Binding<Bool>, hideFeedOptions: Bool) {
        _post = post
        if post.wrappedValue.mediaType == .video {
            _videoCoordinator = StateObject(wrappedValue: VideoPlayerCoordinatorPool.shared.coordinator(for: post.wrappedValue.id))
        } else {
            _videoCoordinator = StateObject(wrappedValue: VideoPlayerCoordinator()) // Dummy coordinator for non-video posts
        }
        _viewModel = ObservedObject(initialValue: viewModel)
        _scrollPosition = scrollPosition
        _pauseVideo = pauseVideo
        self.hideFeedOptions = hideFeedOptions
    }
    
    var drag: some Gesture {
        DragGesture(minimumDistance: 50)
            .onChanged { _ in self.isDragging = true }
            .onEnded { endedGesture in
                if (endedGesture.location.x - endedGesture.startLocation.x) > 0 {
                    self.dragDirection = "left"
                    if self.currentImageIndex > 0 {
                        self.currentImageIndex -= 1
                    } else if hideFeedOptions {
                        dismiss()
                    }
                } else {
                    self.dragDirection = "right"
                    if self.currentImageIndex < post.mediaUrls.count - 1 {
                        self.currentImageIndex += 1
                    }
                }
                self.isDragging = false
            }
    }
    
    var body: some View {
        ZStack {
            if post.mediaType == .video {
                VideoPlayerView(coordinator: videoCoordinator, videoGravity: .resizeAspectFill)
                    .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
                    .containerRelativeFrame([.horizontal, .vertical])
                    .onTapGesture {
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
            } else if post.mediaType == .photo {
                ZStack(alignment: .top) {
                    KFImage(URL(string: post.mediaUrls[currentImageIndex]))
                        .resizable()
                        .scaledToFill()
                        .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
                        .cornerRadius(20)
                        .containerRelativeFrame([.horizontal, .vertical])
                    
                    VStack {
                        HStack(spacing: 6) {
                            if post.mediaUrls.count > 1 {
                                ForEach(0..<post.mediaUrls.count, id: \.self) { index in
                                    Circle()
                                        .fill(index == currentImageIndex ? Color("Colors/AccentColor") : Color.white)
                                        .frame(width: 10, height: 10)
                                }
                            }
                        }
                        .padding(.top, 130)
                    }
                }
            }
            
            ZStack(alignment: .bottom) {
                VStack {
                    Spacer()
                    HStack(alignment: .bottom) {
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
                                }
                            }
                            
                            if let timestamp = post.timestamp {
                                Text(getTimeElapsedString(from: timestamp))
                                    .font(.custom("MuseoSansRounded-300", size: 10))
                                    .foregroundColor(Color("Colors/HingeGray"))
                            }
                            Text(post.caption)
                                .lineLimit(expandCaption ? 50 : 1)
                                .font(.custom("MuseoSansRounded-300", size: 16))
                            
                            if !expandCaption {
                                Text("See more...")
                                    .font(.custom("MuseoSansRounded-300", size: 10))
                            } else {
                                NavigationLink(destination: RestaurantProfileView(restaurantId: post.restaurant.id)) {
                                    Text("View Restaurant")
                                }
                                .modifier(StandardButtonModifier(width: 175))
                            }
                        }
                        .padding(10)
                        .background(RoundedRectangle(cornerRadius: 10).fill(Color.black.opacity(0.3)))
                        .onTapGesture { withAnimation(.snappy) { expandCaption.toggle() } }
                        .font(.custom("MuseoSansRounded-300", size: 16))
                        .foregroundStyle(.white)
                        .padding(.horizontal)
                        
                        Spacer()
                        
                        VStack(spacing: 28) {
                            NavigationLink(value: post.user) {
                                UserCircularProfileImageView(profileImageUrl: post.user.profileImageUrl, size: .medium)
                            }
                            
                            Button {
                                videoCoordinator.pause()
                                showingOptionsSheet = true
                            } label: {
                                ZStack {
                                    Rectangle().fill(.clear).frame(width: 28, height: 28)
                                    Image(systemName: "ellipsis").resizable().scaledToFill().frame(width: 6, height: 6).foregroundStyle(.white)
                                }
                            }
                            
                            if let user = Auth.auth().currentUser?.uid, post.user.id != user {
                                Button {
                                    showingRepostSheet.toggle()
                                } label: {
                                    VStack {
                                        Image(systemName: "arrow.2.squarepath").resizable().scaledToFill().frame(width: 28, height: 28).foregroundStyle(.white).rotationEffect(.degrees(90))
                                        Text("\(post.repostCount)").font(.custom("MuseoSansRounded-300", size: 10)).fontWeight(.bold)
                                    }
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
                                FeedCellActionButtonView(imageName: didLike ? "heart.fill" : "heart.fill", value: post.likes, tintColor: didLike ? Color("Colors/AccentColor") : .white)
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
                                Image(systemName: "arrowshape.turn.up.right.fill").resizable().scaledToFill().frame(width: 28, height: 28).foregroundStyle(.white)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                
                if post.mediaType == .video {
                    let totalTime = videoCoordinator.duration.isFinite ? max(videoCoordinator.duration, 0) : 0
                    Slider(value: $videoCoordinator.currentTime, in: 0...totalTime, onEditingChanged: sliderEditingChanged)
                        .onAppear {
                            let clearCircleImage = UIImage.clearCircle(radius: 15, lineWidth: 1, color: .clear)
                            UISlider.appearance().setThumbImage(clearCircleImage, for: .normal)
                        }
                        .offset(y: 40)
                }
            }
            .padding(.bottom, viewModel.isContainedInTabBar ? 115 : 70)
        }
        .onTapGesture(count: 2) {
            withAnimation {
                if post.didLike {
                    Task { await viewModel.unlike(post) }
                } else {
                    Task { await viewModel.like(post) }
                }
            }
        }
        .gesture(drag)
        .onChange(of: scrollPosition) { oldValue, newValue in
            if post.mediaType == .video {
                if newValue == post.id {
                    videoCoordinator.replay()
                } else {
                    videoCoordinator.pause()
                }
            }
        }
        .onChange(of: pauseVideo) { oldValue, newValue in
            if post.mediaType == .video {
                if scrollPosition == post.id || (viewModel.posts.first?.id == post.id && scrollPosition == nil) {
                    if newValue {
                        videoCoordinator.pause()
                    } else {
                        videoCoordinator.play()
                    }
                }
            }
        }
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
            PostOptionsSheet(post: post, viewModel: viewModel)
                .presentationDetents([.height(UIScreen.main.bounds.height * 0.15)])
        }
        .sheet(isPresented: $showingRepostSheet) {
            RepostView(viewModel: viewModel, post: post)
                .presentationDetents([.height(UIScreen.main.bounds.height * 0.35)])
        }
        .onAppear {
            if post.id == viewModel.startingPostId {
                self.currentImageIndex = viewModel.startingImageIndex
                viewModel.startingPostId = ""
                viewModel.startingImageIndex = 0
                if post.mediaType == .video {
                    videoCoordinator.replay()
                }
            }
        }
    }
    
    private func handleLikeTapped() {
        Task { didLike ? await viewModel.unlike(post) : await viewModel.like(post) }
    }
    
    private func formattedTime(time: Int?) -> String {
        guard let time = time else {
            return "Not specified"
        }
        
        let hours = time / 60
        let minutes = time % 60
        var timeString = ""
        
        if hours > 0 {
            timeString += "\(hours)h"
        }
        
        if minutes > 0 {
            timeString += " \(minutes)m"
        }
        
        return timeString.isEmpty ? "Not specified" : timeString
    }
    
    func sliderEditingChanged(_ editingStarted: Bool) {
        if post.mediaType == .video {
            if editingStarted {
                videoCoordinator.pause()
            } else {
                videoCoordinator.seekToTime(seconds: videoCoordinator.currentTime)
                videoCoordinator.play()
            }
        }
    }
}

//MARK: Photo Library Access
func requestPhotoLibraryAccess(completion: @escaping (Bool) -> Void) {
    PHPhotoLibrary.requestAuthorization { status in
        switch status {
        case .authorized:
            completion(true)
        case .denied, .restricted:
            completion(false)
        case .notDetermined:
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

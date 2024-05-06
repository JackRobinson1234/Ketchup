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
struct FeedCell: View {
    @Binding var post: Post
    @StateObject var videoCoordinator = VideoPlayerCoordinator()
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
    
    @State private var currentImageIndex = 0
    
    @State var isDragging = false
    @State var dragDirection = "left"
    var drag: some Gesture {
        DragGesture(minimumDistance: 50)
            .onChanged { _ in self.isDragging = true }
            .onEnded { endedGesture in
                if (endedGesture.location.x - endedGesture.startLocation.x) > 0 {
                    self.dragDirection = "left"
                    if self.currentImageIndex > 0 {
                        self.currentImageIndex -= 1
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
        //MARK: Loading Screen
        ZStack {
            
            if post.mediaType == "video" {
                if videoConfigured {
                    VideoPlayerView(coordinator: videoCoordinator)
                        .containerRelativeFrame([.horizontal, .vertical])
                }
                else {
                    ProgressView()
                        .containerRelativeFrame([.horizontal, .vertical])
                }
            } else if post.mediaType == "photo" {
                
                ZStack {
                    KFImage(URL(string: post.mediaUrls[currentImageIndex]))
                        .resizable()
                        .scaledToFill()
                        .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
                        .cornerRadius(20)
                        .containerRelativeFrame([.horizontal, .vertical])
                    
                    VStack {
                        HStack {
                            Spacer()
                            
                            Text("\(currentImageIndex + 1) of \(post.mediaUrls.count)")
                                .font(.caption)
                                .fontWeight(.bold)
                                .padding(8)
                                .background(Color.black.opacity(0.5))
                                .cornerRadius(10)
                                .foregroundColor(.white)
                                .padding(.top, 10)
                            
                            Spacer()
                        }
                        
                        
                        Spacer()
                    }
                    .frame(width: UIScreen.main.bounds.width, height: 650)
                    
                   
                    
                    
                }
            }

            VStack {
                Spacer()
                //MARK: Black Background
                ZStack(alignment: .bottom) {
                    Rectangle()
                        .fill(LinearGradient(colors: [.clear, .black.opacity(0.15)],
                                             startPoint: .top,
                                             endPoint: .bottom))
                    
                    
                    HStack(alignment: .bottom) {
                        
                        // MARK: Caption Box
                        
                        VStack(alignment: .leading, spacing: 7) {
                            HStack{
                                //MARK:  restaurant profile image
                                if let restaurant = post.restaurant {
                                    NavigationLink(value: restaurant) {
                                        RestaurantCircularProfileImageView(imageUrl: restaurant.profileImageUrl, size: .large)
                                    }
                                    
                                    //MARK: Restaurant Name
                                    VStack (alignment: .leading) {
                                        NavigationLink(value: restaurant) {
                                            Text("\(restaurant.name)")
                                                .font(.title3)
                                                .bold()
                                                .multilineTextAlignment(.leading)
                                        }
                                        //MARK: Address
                                        Text("\(restaurant.city ?? ""), \(restaurant.state ?? "")")
                                            //MARK: Recipe Fullname
                                        NavigationLink(value: post.user) {
                                            Text("by \(post.user.fullName)")
                                                .font(.subheadline)
                                                .fontWeight(.semibold)
                                                .foregroundStyle(.white)
                                                .bold()
                                                .multilineTextAlignment(.leading)
                                        }
                                    }
                                    //MARK: Recipe Scenario
                                } else if let recipe = post.recipe{
                                    VStack (alignment: .leading) {
                                        Button{showRecipe.toggle()} label: {
                                            Text("\(recipe.name)")
                                                .font(.title3)
                                                .bold()
                                                .multilineTextAlignment(.leading)
                                        }
                                        //MARK: recipe fullname
                                        NavigationLink(value: post.user) {
                                            Text("by \(post.user.fullName)")
                                                .font(.subheadline)
                                                .fontWeight(.semibold)
                                                .foregroundStyle(.white)
                                                .bold()
                                                .multilineTextAlignment(.leading)
                                        }
                                    }
                                }
                            }
                            
                            
                            //MARK: caption
                            Text(post.caption)
                                .lineLimit(expandCaption ? 50 : 1)
                            
                            //MARK: see more
                            if !expandCaption{
                                Text("See more...")
                                    .font(.footnote)
                            }
                            else {
                                Text("Cuisine: \(post.cuisine ?? "")")
                                
                                //MARKL  price
                                Text("Price: \(post.price ?? "")")
                                
                                //MARK: Menu Button
                                
                                if let restaurant = post.restaurant {
                                    NavigationLink(destination: RestaurantProfileView(restaurantId: restaurant.id, currentSection: .menu)) {
                                        Text("View Menu")
                                    }
                                    .modifier(StandardButtonModifier(width: 175))
                                    //MARK: Show recipe
                                } else if post.recipe != nil {
                                    Button{
                                        showRecipe.toggle()
                                        Task{
                                            await videoCoordinator.pause()
                                        }
                                    } label: {
                                        Text("View Recipe")
                                    }
                                    .modifier(StandardButtonModifier(width: 175))
                                    
                                }
                            }
                        }
                        
                        //controls box size
                        .padding(10)
                        .background(Color.black.opacity(0.3))
                        .onTapGesture { withAnimation(.snappy) { expandCaption.toggle() } }
                        .font(.subheadline)
                        .foregroundStyle(.white)
                        .padding(.horizontal)
                        
                        Spacer()
                        //MARK: Right hand VStack
                        VStack(spacing: 28) {
                            //MARK: user profile image
                            NavigationLink(value: post.user) {
                                ZStack(alignment: .bottom) {
                                    UserCircularProfileImageView(profileImageUrl: post.user.profileImageUrl, size: .medium)
                                    Image(systemName: "plus.circle.fill")
                                        .foregroundStyle(.pink)
                                        .offset(y: 8)
                                }
                            }
                            //MARK: Collection Button
                            Button {
                                Task{
                                    await videoCoordinator.pause()
                                }
                                showCollections.toggle()
                            } label: {
                                FeedCellActionButtonView(imageName: "folder.fill.badge.plus")
                            }
                            //MARK: Like button
                            Button {
                                handleLikeTapped()
                            } label: {
                                FeedCellActionButtonView(imageName: didLike ? "heart.fill": "heart.fill",
                                                         value: post.likes,
                                                         tintColor: didLike ? .red : .white)
                            }
                            //MARK: comment button
                            Button {
                                Task{
                                    await videoCoordinator.pause()
                                }
                                showComments.toggle()
                            } label: {
                                FeedCellActionButtonView(imageName: "ellipsis.bubble.fill", value: post.commentCount)
                            }
                            // Bookmark button
                            
                            //MARK: share button
                            Button {
                                Task{
                                    await videoCoordinator.pause()
                                }
                                showShareView.toggle()
                                
                            } label: {
                                FeedCellActionButtonView(imageName: "arrowshape.turn.up.right.fill",
                                                         value: post.shareCount)
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.bottom, viewModel.isContainedInTabBar ? 115 : 50)
                }
            }
            .gesture(drag)
            //MARK: Scroll Position replay/ pause
            .onChange(of: scrollPosition) {oldValue, newValue in
                if newValue == post.id {
                    Task {
                        await videoCoordinator.replay()
                    }
                } else {
                    Task {
                        await videoCoordinator.pause()
                    }
                }
            }
            //MARK: Scroll Position play/pause
            .onChange(of: pauseVideo) {oldValue, newValue in
                if scrollPosition == post.id || viewModel.posts.first?.id == post.id && scrollPosition == nil{
                    if newValue == true {
                        Task {
                            await videoCoordinator.pause()
                        }
                    } else {
                        Task {
                            await videoCoordinator.play()
                        }
                    }
                }
            }
            //MARK: Configure Player
            .onAppear {
                if !videoConfigured {
                    Task{
                        if let videoURL = post.mediaUrls.first {
                            await videoCoordinator.configurePlayer(url: URL(string: videoURL), fileExtension: "mp4")
                        }
                        videoConfigured = true
                        if viewModel.posts.first?.id == post.id && scrollPosition == nil {
                            await videoCoordinator.replay()
                        }
                    }
                } else {
                    Task {
                        await videoCoordinator.replay()
                    }
                }
            }
            .onDisappear{
                Task{
                    await videoCoordinator.pause()
                }
            }
            //MARK: sheets
            //overlays the comments if showcomments is true
            .sheet(isPresented: $showComments) {
                CommentsView(post: post)
                    .presentationDetents([.height(UIScreen.main.bounds.height * 0.65)])
                    .onDisappear{Task{ await videoCoordinator.play()}}
            }
            .sheet(isPresented: $showShareView) {
                ShareView(post: post)
                    .presentationDetents([.height(UIScreen.main.bounds.height * 0.15)])
                    .onDisappear{Task { await videoCoordinator.play()}}
            }
            .sheet(isPresented: $showRecipe) {
                RecipeView(post: post)
                    .onDisappear{Task { await videoCoordinator.play()}}
            }
            .sheet(isPresented: $showCollections) {
                AddItemCollectionList(user: viewModel.user, post: post)
            }
            //MARK: Tap to play/pause
            .onTapGesture {
                if let player = videoCoordinator.videoPlayerManager.queuePlayer{
                    switch player.timeControlStatus {
                    case .paused:
                        Task{await videoCoordinator.play()}
                    case .waitingToPlayAtSpecifiedRate:
                        break
                    case .playing:
                        Task{ await videoCoordinator.pause()}
                    @unknown default:
                        break
                    }
                }
            }
        }
    }
    //MARK: like and unlike functionality
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
}
//MARK: Photo Library Acess
func requestPhotoLibraryAccess(completion: @escaping (Bool) -> Void) {
    PHPhotoLibrary.requestAuthorization { status in
        switch status {
        case .authorized:
            // User has granted access
            completion(true)
        case .denied, .restricted:
            // User has denied or restricted access
            completion(false)
        case .notDetermined:
            // User has not yet made a decision
            completion(false)
        case .limited:
            completion(true)
        @unknown default:
            // Handle future cases
            completion(false)
        }
    }
}




#Preview {
    FeedCell(
        post: .constant(DeveloperPreview.posts[0]),
        videoCoordinator: VideoPlayerCoordinator(),
             viewModel: FeedViewModel()
        ,scrollPosition: .constant(""),
        pauseVideo: .constant(true)
    )
}

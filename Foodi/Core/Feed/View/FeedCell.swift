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
    @State private var videoConfigured = false
    private var didLike: Bool { return post.didLike }
    @Binding var scrollPosition: String?
    @Binding var pauseVideo: Bool
    
    var body: some View {
        ZStack {
            if videoConfigured {
                VideoPlayerView(coordinator: videoCoordinator)
                    .containerRelativeFrame([.horizontal, .vertical])
            }
            else {
                ProgressView()
                    .containerRelativeFrame([.horizontal, .vertical])
            }
            
            VStack {
                Spacer()
                
                ZStack(alignment: .bottom) {
                    Rectangle()
                        .fill(LinearGradient(colors: [.clear, .black.opacity(0.15)],
                                             startPoint: .top,
                                             endPoint: .bottom))
                    
                    
                    HStack(alignment: .bottom) {
                        
                        // MARK: Caption Box
                        
                        VStack(alignment: .leading, spacing: 7) {
                            HStack{
                                //MARK: Restaurant Scenario
                                // restaurant profile image
                                if let restaurant = post.restaurant {
                                    NavigationLink(value: restaurant) {
                                        RestaurantCircularProfileImageView(imageUrl: restaurant.profileImageUrl, size: .large)
                                    }
                                    
                                    //restaurant name
                                    VStack (alignment: .leading) {
                                        NavigationLink(value: restaurant) {
                                            Text("\(restaurant.name)")
                                                .font(.title3)
                                                .bold()
                                                .multilineTextAlignment(.leading)
                                        }
                                        //address
                                        Text("\(restaurant.city ?? ""), \(restaurant.state ?? "")")
                                        
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
                            
                            
                            //caption
                            Text(post.caption)
                                .lineLimit(expandCaption ? 50 : 1)
                            
                            //see more
                            if !expandCaption{
                                Text("See more...")
                                    .font(.footnote)
                            }
                            else {
                                
                                Text("Cuisine: \(post.cuisine ?? "")")
                                
                                // price
                                Text("Price: \(post.price ?? "")")
                                
                                //Menu Button
                                
                                if let restaurant = post.restaurant {
                                    NavigationLink(destination: RestaurantProfileView(restaurantId: restaurant.id, currentSection: .menu)) {
                                        Text("View Menu")
                                    }
                                    .modifier(StandardButtonModifier(width: 175))
                                } else if let recipe = post.recipe {
                                    
                                    
                                    
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
                            //user profile image
                            NavigationLink(value: post.user) {
                                ZStack(alignment: .bottom) {
                                    UserCircularProfileImageView(profileImageUrl: post.user.profileImageUrl, size: .medium)
                                    Image(systemName: "plus.circle.fill")
                                        .foregroundStyle(.pink)
                                        .offset(y: 8)
                                }
                            }
                            //like button
                            Button {
                                handleLikeTapped()
                            } label: {
                                FeedCellActionButtonView(imageName: "heart.fill",
                                                         value: post.likes,
                                                         tintColor: didLike ? .red : .white)
                            }
                            //comment button
                            Button {
                                Task{
                                    await videoCoordinator.pause()
                                }
                                showComments.toggle()
                            } label: {
                                FeedCellActionButtonView(imageName: "ellipsis.bubble.fill", value: post.commentCount)
                            }
                            // Bookmark button
                            
                            //share button
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
            //MARK: CLICKING CONTROLS
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
    // like and unlike functionality
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
             viewModel: FeedViewModel(
                postService: PostService()             )
        ,scrollPosition: .constant(""),
        pauseVideo: .constant(true)
    )
}


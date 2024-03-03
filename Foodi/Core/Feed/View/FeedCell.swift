//
//  FeedCell.swift
//  Foodi
//
//  Created by Jack Robinson on 2/1/24.
//

import SwiftUI
import AVKit
import Photos
struct FeedCell: View {
    @Binding var post: Post
    var player: AVPlayer
    @ObservedObject var viewModel: FeedViewModel
    @State private var expandCaption = false
    @State private var showComments = false
    @State private var showShareView = false
        
    private var didLike: Bool { return post.didLike }
    
    var body: some View {
        ZStack {
            VideoPlayer(player: player)
                .containerRelativeFrame([.horizontal, .vertical])
                    
            VStack {
                Spacer()
                
                ZStack(alignment: .bottom) {
                    Rectangle()
                        .fill(LinearGradient(colors: [.clear, .black.opacity(0.15)],
                                             startPoint: .top,
                                             endPoint: .bottom))
                    
                    
                    HStack(alignment: .bottom) {
                        
                        // MARK: LEFT (POST META-DATA) VSTACK
                        
                        VStack(alignment: .leading, spacing: 7) {
                            HStack{
                                // restaurant profile image
                                if let restaurant = post.restaurant{
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
                                        Text("📍 \(restaurant.city ?? ""), \(restaurant.state ?? "")")
                                        
                                        NavigationLink(value: post.user) {
                                            Text("by \(post.user.fullname)")
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
                                if let restaurant = post.restaurant{
                                    Text("Cuisine: \(restaurant.cuisine ?? "")")
                                    
                                    // price
                                    Text("Price: \(restaurant.price ?? "")")
                                    
                                    //Menu Button
                                    
                                    NavigationLink(destination: RestaurantProfileView(restaurantId: restaurant.id, currentSection: .menu)) {
                                        Text("View Menu")
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
                        .padding()
                        
                        Spacer()
                        //MARK: Right hand Vstack
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
                                player.pause()
                                showComments.toggle()
                            } label: {
                                FeedCellActionButtonView(imageName: "ellipsis.bubble.fill", value: post.commentCount)
                            }
                            // Bookmark button
                            
                            //share button
                            Button {
                                player.pause()
                                showShareView.toggle()
                                
                            } label: {
                                FeedCellActionButtonView(imageName: "arrowshape.turn.up.right.fill",
                                                         value: post.shareCount)
                            }
                        }
                        .padding()
                    }
                    .padding(.bottom, viewModel.isContainedInTabBar ? 90 : 22)
                }
            }
            //MARK: CLICKING CONTROLS
            //overlays the comments if showcomments is true
            .sheet(isPresented: $showComments) {
                CommentsView(post: post)
                    .presentationDetents([.height(UIScreen.main.bounds.height * 0.65)])
                    .onDisappear{player.play()}
            }
            .sheet(isPresented: $showShareView) {
                ShareView(post: post)
                    .presentationDetents([.height(UIScreen.main.bounds.height * 0.15)])
                    .onDisappear{player.play()}
            }
            .onTapGesture {
                switch player.timeControlStatus {
                case .paused:
                    player.play()
                case .waitingToPlayAtSpecifiedRate:
                    break
                case .playing:
                    player.pause()
                @unknown default:
                    break
                }
            }
        }
    }
    // like and unlike functionality
    private func handleLikeTapped() {
        Task { didLike ? await viewModel.unlike(post) : await viewModel.like(post) }
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
        player: AVPlayer(),
             viewModel: FeedViewModel(
                postService: PostService()
             )
    )
}

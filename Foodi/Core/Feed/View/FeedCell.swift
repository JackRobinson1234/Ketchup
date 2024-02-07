//
//  FeedCell.swift
//  Foodi
//
//  Created by Jack Robinson on 2/1/24.
//

import SwiftUI
import AVKit

struct FeedCell: View {
    @Binding var post: Post
    var player: AVPlayer
    @ObservedObject var viewModel: FeedViewModel
    @State private var expandCaption = false
    @State private var showComments = false
        
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
                                NavigationLink(value: post.restaurant) {
                                    RestaurantCircularProfileImageView(restaurant: post.restaurant, size: .large)
                                }
                                //restaurant name
                                VStack (alignment: .leading) {
                                NavigationLink(value: post.restaurant) {
                                    Text("\(post.restaurant?.name ?? "")")
                                        .font(.title3)
                                        .bold()
                                        .multilineTextAlignment(.leading)
                                }
                                //address
                                Text("📍 \(post.restaurant?.city ?? ""), \(post.restaurant?.state ?? "")")
                                
                                    NavigationLink(value: post.user) {
                                        Text("by \(post.user?.fullname ?? "")")
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                            .foregroundStyle(.white)
                                            .bold()
                                            .multilineTextAlignment(.leading)
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
                                //cuisine
                                Text("Cuisine: \(post.restaurant?.cuisine ?? "")")
                                
                                // price
                                Text("Price: \(post.restaurant?.price ?? "")")
                                
                                //Menu Button
                                if post.restaurant != nil {
                                    NavigationLink(destination: RestaurantProfileView(restaurant: post.restaurant!, currentSection: .menu)) {
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
                                    UserCircularProfileImageView(user: post.user, size: .medium)
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
                            Button {
                                
                            } label: {
                                FeedCellActionButtonView(imageName: "bookmark.fill",
                                                         value: post.saveCount,
                                                         height: 28,
                                                         width: 22,
                                                         tintColor: .white)
                            }
                            //share button
                            Button {
                                
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

#Preview {
    FeedCell(
        post: .constant(DeveloperPreview.posts[0]),
        player: AVPlayer(),
             viewModel: FeedViewModel(
                postService: PostService()
             )
    )
}

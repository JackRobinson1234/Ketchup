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
                        VStack(alignment: .leading, spacing: 7) {
                            HStack{
                                NavigationLink(value: post.restaurant) {
                                    RestaurantCircularProfileImageView(restaurant: post.restaurant, size: .large)
                                }
                                VStack (alignment: .leading){
                                NavigationLink(value: post.restaurant) {
                                    Text("\(post.restaurant?.name ?? "")")
                                        .font(.title3)
                                        .bold()
                                }
                                
                                Text("\(post.restaurant?.city ?? ""), \(post.restaurant?.state ?? "")")
                                
                                    NavigationLink(value: post.user) {
                                        Text("by \(post.user?.fullname ?? "")")
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                            .foregroundStyle(.white)
                                            .bold()
                                    }
                                }
                            }
                            
                            Text(post.caption)
                                .lineLimit(expandCaption ? 50 : 2)
                        }
                        .background(Color.white.opacity(0.2))
                        .onTapGesture { withAnimation(.snappy) { expandCaption.toggle() } }
                        .font(.subheadline)
                        .foregroundStyle(.white)
                        .padding()
                        
                        Spacer()
                        
                        VStack(spacing: 28) {
                            NavigationLink(value: post.user) {
                                ZStack(alignment: .bottom) {
                                    UserCircularProfileImageView(user: post.user, size: .medium)
                                    Image(systemName: "plus.circle.fill")
                                        .foregroundStyle(.pink)
                                        .offset(y: 8)
                                }
                            }
                            
                            Button {
                                handleLikeTapped()
                            } label: {
                                FeedCellActionButtonView(imageName: "heart.fill",
                                                         value: post.likes,
                                                         tintColor: didLike ? .red : .white)
                            }
                            
                            Button {
                                player.pause()
                                showComments.toggle()
                            } label: {
                                FeedCellActionButtonView(imageName: "ellipsis.bubble.fill", value: post.commentCount)
                            }
                            
                            Button {
                                
                            } label: {
                                FeedCellActionButtonView(imageName: "bookmark.fill",
                                                         value: post.saveCount,
                                                         height: 28,
                                                         width: 22,
                                                         tintColor: .white)
                            }
                            
                            Button {
                                
                            } label: {
                                FeedCellActionButtonView(imageName: "arrowshape.turn.up.right.fill",
                                                         value: post.shareCount)
                            }
                        }
                        .padding()
                    }
                    .padding(.bottom, viewModel.isContainedInTabBar ? 90 : 12)
                }
                
            }
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

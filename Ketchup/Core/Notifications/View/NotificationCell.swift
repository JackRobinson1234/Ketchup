//
//  NotificationCell.swift
//  Foodi
//
//  Created by Jack Robinson on 2/1/24.
//
import SwiftUI
import Kingfisher

struct NotificationCell: View {
    @ObservedObject var viewModel: NotificationsViewModel
    var notification: Notification
    @State private var isFollowed: Bool = false
    @State private var showRestaurant = false
    @State private var selectedRestaurantId: String? = nil
    @State private var post: Post?
    @State private var showPost: Bool = false

    var body: some View {
        HStack {
            userProfileImage
            notificationContent
            Spacer()
            actionButton
        }
        .padding(.horizontal)
        .onAppear(perform: checkFollowStatus)
        .fullScreenCover(isPresented: $showRestaurant, content: restaurantProfileView)
        .fullScreenCover(isPresented: $showPost, content: postView)
    }
    
    private var userProfileImage: some View {
        NavigationLink(value: notification.user) {
            UserCircularProfileImageView(profileImageUrl: notification.user?.profileImageUrl, size: .medium)
        }
    }
    
    private var notificationContent: some View {
        VStack(alignment: .leading, spacing: 4) {
            notificationText
            timestampText
        }
    }
    
    private var notificationText: some View {
        Button(action: handleNotificationTap) {
            Text(fullNotificationMessage)
                .font(.custom("MuseoSansRounded-300", size: 16))
                .foregroundColor(.black)
                .multilineTextAlignment(.leading)
        }
    }
    
    private var fullNotificationMessage: AttributedString {
        var atUsername = AttributedString("@\(notification.username ?? "")")
        atUsername.foregroundColor = .black
        atUsername.font = .custom("MuseoSansRounded-300", size: 16).weight(.semibold)
        
        var message = AttributedString(notification.type.notificationMessage)
        message.foregroundColor = .black
        message.font = .custom("MuseoSansRounded-300", size: 16)
        
        var additionalText = AttributedString(notification.type != .postWentWithMention ? (notification.text ?? "") : "")
        additionalText.foregroundColor = .black
        additionalText.font = .custom("MuseoSansRounded-300", size: 16)
        
        return atUsername + message + additionalText
    }
    
    private var timestampText: some View {
        Text(notification.timestamp.timestampString())
            .foregroundColor(.gray)
            .font(.custom("MuseoSansRounded-300", size: 10))
    }
    
    private var actionButton: some View {
        Group {
            if notification.type == .follow {
                followButton
            } else if let postThumbnail = notification.postThumbnail, !postThumbnail.isEmpty {
                postThumbnailButton(postThumbnail)
            }
        }
    }
    
    private var followButton: some View {
        Button(action: handleFollowAction) {
            Text(isFollowed ? "Following" : "Follow")
                .font(.custom("MuseoSansRounded-300", size: 16))
                .fontWeight(.semibold)
                .frame(width: 110)
                .padding(.vertical, 8)
                .foregroundColor(isFollowed ? Color("Colors/AccentColor") : .white)
                .background(isFollowed ? Color.clear : Color.red)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color("Colors/AccentColor"), lineWidth: isFollowed ? 1 : 0)
                )
        }
    }
    
    private func postThumbnailButton(_ thumbnail: String) -> some View {
        Button(action: handlePostThumbnailTap) {
            KFImage(URL(string: thumbnail))
                .resizable()
                .scaledToFill()
                .frame(width: 48, height: 48)
                .clipShape(RoundedRectangle(cornerRadius: 6))
        }
    }
    
    private func checkFollowStatus() {
        if notification.type == .follow {
            Task {
                self.isFollowed = await viewModel.checkIfUserIsFollowed(userId: notification.uid)
            }
        }
    }
    
    private func handleNotificationTap() {
        fetchPostIfNeeded()
    }
    
    private func handleFollowAction() {
        Task {
            isFollowed ? try await viewModel.unfollow(userId: notification.uid) : try await viewModel.follow(userId: notification.uid)
            self.isFollowed.toggle()
        }
    }
    
    private func handlePostThumbnailTap() {
        fetchPostIfNeeded()
    }
    
    private func fetchPostIfNeeded() {
        if let postId = notification.postId {
            Task {
                self.post = try await PostService.shared.fetchPost(postId: postId)
                showPost.toggle()
            }
        }
    }
    
    @ViewBuilder
    private func restaurantProfileView() -> some View {
        NavigationStack {
            if let selectedRestaurantId = selectedRestaurantId {
                RestaurantProfileView(restaurantId: selectedRestaurantId)
            }
        }
    }
    
    @ViewBuilder
    private func postView() -> some View {
        NavigationStack {
            if let post = post {
                if post.mediaType == .written {
                    writtenPostView(post)
                } else {
                    SecondaryFeedView(viewModel: FeedViewModel(posts: [post]), hideFeedOptions: true)
                }
            }
        }
    }
    
    private func writtenPostView(_ post: Post) -> some View {
        NavigationView {
            WrittenFeedCell(viewModel: FeedViewModel(posts: [post]), post: .constant(post), scrollPosition: .constant(nil), pauseVideo: .constant(false), selectedPost: .constant(nil), checkLikes: true)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: { showPost = false }) {
                            Image(systemName: "chevron.left")
                                .foregroundStyle(.black)
                                .background(
                                    Circle()
                                        .fill(Color.gray.opacity(0.5))
                                        .frame(width: 30, height: 30)
                                )
                        }
                    }
                }
        }
    }
}

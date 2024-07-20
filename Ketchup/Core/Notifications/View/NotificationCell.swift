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
    @State var isFollowed: Bool = false
    @State var showRestaurant = false
    @State var selectedRestaurantId: String? = nil
    @State var post: Post?
    @State var showPost: Bool = false

    var body: some View {
        HStack {
            NavigationLink(value: notification.user) {
                UserCircularProfileImageView(profileImageUrl: notification.user?.profileImageUrl, size: .medium)
                VStack(alignment: .leading) {
                    HStack(spacing: 0) {
                        notificationText
                    }
                    Text("\(notification.timestamp.timestampString())")
                        .foregroundColor(.gray)
                        .font(.custom("MuseoSansRounded-300", size: 10))
                }
                .multilineTextAlignment(.leading)
            }
            Spacer()
            trailingContent
        }
        .onAppear {
            if notification.type == .follow {
                Task {
                    self.isFollowed = await viewModel.checkIfUserIsFollowed(userId: notification.uid)
                }
            }
        }
        .padding(.horizontal)
        .fullScreenCover(isPresented: $showRestaurant, content: {
            NavigationStack {
                if let selectedRestaurantId = selectedRestaurantId {
                    RestaurantProfileView(restaurantId: selectedRestaurantId)
                }
            }
        })
        .fullScreenCover(isPresented: $showPost, content: {
            NavigationStack {
                if let post = post {
                    let feedViewModel = FeedViewModel(posts: [post])
                    SecondaryFeedView(viewModel: feedViewModel, hideFeedOptions: true)
                }
            }
        })
    }

    private var notificationText: some View {
        Group {
            switch notification.type {
            case .postLike, .comment, .reviewLike:
                postInteractionNotificationText
            case .follow:
                followNotificationText
            case .commentMention, .postCaptionMention, .postWentWithMention:
                mentionNotificationText
            }
        }
    }

    private var postInteractionNotificationText: some View {
        Button {
            if let postId = notification.postId {
                Task {
                    self.post = try await PostService.shared.fetchPost(postId: postId)
                    showPost.toggle()
                }
            }
        } label: {
            Text(notification.user?.username ?? "")
                .font(.custom("MuseoSansRounded-300", size: 16))
                .foregroundStyle(.primary)
                .fontWeight(.semibold) +
            Text(notification.type.notificationMessage)
                .font(.custom("MuseoSansRounded-300", size: 16))
                .foregroundStyle(.primary) +
            Text(notification.type == .reviewLike ? (notification.restaurantName ?? "") : "")
                .font(.custom("MuseoSansRounded-300", size: 16))
                .foregroundStyle(.primary)
        }
    }

    private var followNotificationText: some View {
        Text(notification.user?.username ?? "")
            .font(.custom("MuseoSansRounded-300", size: 16))
            .foregroundStyle(.primary)
            .fontWeight(.semibold) +
        Text(notification.type.notificationMessage)
            .font(.custom("MuseoSansRounded-300", size: 16))
            .foregroundStyle(.primary)
    }

    private var mentionNotificationText: some View {
        Button {
            if let postId = notification.postId {
                Task {
                    self.post = try await PostService.shared.fetchPost(postId: postId)
                    showPost.toggle()
                }
            }
        } label: {
            Text(notification.user?.username ?? "")
                .font(.custom("MuseoSansRounded-300", size: 16))
                .foregroundStyle(.primary)
                .fontWeight(.semibold) +
            Text(notification.type.notificationMessage)
                .font(.custom("MuseoSansRounded-300", size: 16))
                .foregroundStyle(.primary) +
            Text(notification.restaurantName != nil ? " at \(notification.restaurantName!): " : ": ")
                .font(.custom("MuseoSansRounded-300", size: 16))
                .foregroundStyle(.primary) +
            Text(notification.text ?? "")
                .font(.custom("MuseoSansRounded-300", size: 16))
                .foregroundStyle(.primary)
        }
    }

    private var trailingContent: some View {
        Group {
            if notification.type == .follow {
                followButton
            } else {
                postThumbnail
            }
        }
    }

    private var followButton: some View {
        Button(action: {
            Task {
                isFollowed ? try await viewModel.unfollow(userId: notification.uid) : try await viewModel.follow(userId: notification.uid)
                self.isFollowed.toggle()
            }
        }, label: {
            Text(isFollowed ? "Following" : "Follow")
                .font(.custom("MuseoSansRounded-300", size: 16))
                .fontWeight(.semibold)
                .frame(width: 110)
                .padding(.vertical, 8)
                .foregroundColor(isFollowed ? Color("Colors/AccentColor") : .white)
                .background(isFollowed ? Color.clear : Color.red)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .overlay {
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color("Colors/AccentColor"), lineWidth: isFollowed ? 1 : 0)
                }
        })
    }

    private var postThumbnail: some View {
        Group {
            if let postThumbnail = notification.postThumbnail {
                Button {
                    if let postId = notification.postId {
                        Task {
                            self.post = try await PostService.shared.fetchPost(postId: postId)
                            showPost.toggle()
                        }
                    }
                } label: {
                    KFImage(URL(string: postThumbnail))
                        .resizable()
                        .scaledToFill()
                        .frame(width: 48, height: 48)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
            }
        }
    }
}

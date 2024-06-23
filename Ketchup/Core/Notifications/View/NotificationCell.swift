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
                        if let restaurantName = notification.restaurantName, let text = notification.text {
                            Button {
                                if let restaurantId = notification.restaurantId {
                                    print("Setting selectedRestaurantId to \(restaurantId)")
                                    self.selectedRestaurantId = restaurantId
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                        self.showRestaurant.toggle()
                                    }
                                }
                            } label: {
                                VStack {
                                    Text(notification.user?.username ?? "")
                                        .font(.custom("MuseoSans-500", size: 16))
                                        .foregroundStyle(.primary)
                                        .fontWeight(.semibold) +
                                    Text(notification.type.notificationMessage)
                                        .font(.custom("MuseoSans-500", size: 16))
                                        .foregroundStyle(.primary) +
                                    Text("\(restaurantName): ")
                                        .font(.custom("MuseoSans-500", size: 16))
                                        .foregroundStyle(.primary) +
                                    Text(text)
                                        .font(.custom("MuseoSans-500", size: 16))
                                        .foregroundStyle(.primary)
                                }
                                .multilineTextAlignment(.leading)
                            }
                        } else {
                            VStack {
                                Text(notification.user?.username ?? "")
                                    .font(.custom("MuseoSans-500", size: 16))
                                    .foregroundStyle(.primary)
                                    .fontWeight(.semibold) +
                                Text(notification.type.notificationMessage)
                                    .font(.custom("MuseoSans-500", size: 16))
                                    .foregroundStyle(.primary)
                            }
                            .multilineTextAlignment(.leading)
                        }
                    }
                    Text("\(notification.timestamp.timestampString())")
                        .foregroundColor(.gray)
                        .font(.custom("MuseoSans-500", size: 12))
                }
                .multilineTextAlignment(.leading)
            }
            Spacer()
            if notification.type == .follow {
                Button(action: {
                    Task {
                        isFollowed ? try await viewModel.unfollow(userId: notification.uid) : try await viewModel.follow(userId: notification.uid)
                        self.isFollowed.toggle()
                    }
                }, label: {
                    Text(isFollowed ? "Following" : "Follow")
                        .font(.custom("MuseoSans-500", size: 16))
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
            } else {
                if let postThumbnail = notification.postThumbnail {
                    Button {
                        if let postId = notification.postId {
                            Task {
                                print("Fetching post with ID \(postId)")
                                self.post = try await PostService.shared.fetchPost(postId: postId)
                                print("Fetched post: \(String(describing: self.post))")
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
        .onAppear {
            if notification.type == .follow {
                Task {
                    self.isFollowed = await viewModel.checkIfUserIsFollowed(userId: notification.uid)
                }
            }
        }
        .padding(.horizontal)
        .sheet(isPresented: Binding(
            get: { showRestaurant && selectedRestaurantId != nil },
            set: { showRestaurant = $0 }
        )) {
            NavigationStack {
                if let selectedRestaurantId = selectedRestaurantId {
                    let _ =  print("Showing RestaurantProfileView for \(selectedRestaurantId)")
                    RestaurantProfileView(restaurantId: selectedRestaurantId)
                }
            }
        }
        .sheet(isPresented: Binding(
            get: { showPost && post != nil },
            set: { showPost = $0 }
        )) {
            NavigationStack {
                if let post = post {
                    let _ = print("Showing FeedView for post: \(post)")
                    let feedViewModel = FeedViewModel(posts: [post])
                    FeedView(videoCoordinator: VideoPlayerCoordinator(), viewModel: feedViewModel, hideFeedOptions: true)
                }
            }
        }
    }
}

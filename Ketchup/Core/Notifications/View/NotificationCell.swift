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
            }
            VStack(alignment: .leading) {
                HStack(spacing: 0) {
                    if let restaurantName = notification.restaurantName, let text = notification.text {
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
                            VStack {
                                Text(notification.user?.username ?? "")
                                    .font(.custom("MuseoSansRounded-300", size: 16))
                                    .foregroundStyle(.black)
                                    .fontWeight(.semibold) +
                                Text(notification.type.notificationMessage)
                                    .font(.custom("MuseoSansRounded-300", size: 16))
                                    .foregroundStyle(.black) +
                                Text(notification.type != .postWentWithMention ? " \(text)" : "")
                                    .font(.custom("MuseoSansRounded-300", size: 16))
                                    .foregroundStyle(.black)
                            }
                            .multilineTextAlignment(.leading)
                        }
                    } else {
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
                            VStack {
                                Text(notification.user?.username ?? "")
                                    .font(.custom("MuseoSansRounded-300", size: 16))
                                    .foregroundStyle(.black)
                                    .fontWeight(.semibold) +
                                Text(notification.type.notificationMessage)
                                    .font(.custom("MuseoSansRounded-300", size: 16))
                                    .foregroundStyle(.black)
                            }
                            .multilineTextAlignment(.leading)
                        }
                    }
                }
                Text("\(notification.timestamp.timestampString())")
                    .foregroundColor(.gray)
                    .font(.custom("MuseoSansRounded-300", size: 10))
            }
            .multilineTextAlignment(.leading)
            Spacer()
            if notification.type == .follow {
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
            } else {
                if let postThumbnail = notification.postThumbnail, !postThumbnail.isEmpty {
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
        .fullScreenCover(isPresented: Binding(
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
        .fullScreenCover(isPresented: Binding(
            get: { showPost && post != nil },
            set: { showPost = $0 }
        )) {
            NavigationStack {
                if let post = post {
                    let _ = print("Showing FeedView for post: \(post)")
                    let feedViewModel = FeedViewModel(posts: [post])
                    
                    if post.mediaType == .written {
                        NavigationView {
                            WrittenFeedCell(viewModel: feedViewModel, post: .constant(post), scrollPosition: .constant(nil), pauseVideo: .constant(false), selectedPost: .constant(nil), checkLikes: true)
                                .toolbar {
                                    ToolbarItem(placement: .navigationBarLeading) {
                                        Button(action: {
                                            showPost = false
                                        }) {
                                            Image(systemName: "chevron.left")
                                                .foregroundStyle(.black)
                                                .background(
                                                    Circle()
                                                        .fill(Color.gray.opacity(0.5)) // Adjust the opacity as needed
                                                        .frame(width: 30, height: 30) // Adjust the size as needed
                                                )
                                        }
                                    }
                                }
                        }
                    } else {
                        SecondaryFeedView(viewModel: feedViewModel, hideFeedOptions: true)
                    }
                }
            }
        }
    }
}

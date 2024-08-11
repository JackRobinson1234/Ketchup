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
    @ObservedObject var feedViewModel: FeedViewModel
    var body: some View {
        HStack {
            NavigationLink(value: notification.user) {
                UserCircularProfileImageView(profileImageUrl: notification.user?.profileImageUrl, size: .medium)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                notificationContent
                timestampText
            }
            
            Spacer()
            
            actionButton
        }
        .padding(.horizontal)
        .onAppear(perform: checkFollowStatus)
        .fullScreenCover(isPresented: Binding(
            get: { showRestaurant && selectedRestaurantId != nil },
            set: { showRestaurant = $0 }
        )) {
            restaurantProfileView
        }
        .fullScreenCover(isPresented: Binding(
            get: { showPost && post != nil },
            set: { showPost = $0 }
        )) {
            postView
        }
    }
    
    private var notificationContent: some View {
        Button {
            handleNotificationTap()
        } label: {
            Text(fullNotificationMessage)
                .font(.custom("MuseoSansRounded-300", size: 16))
                .foregroundColor(.black)
                .multilineTextAlignment(.leading)
        }
    }
    
    
    private var fullNotificationMessage: AttributedString {
            let username = notification.user?.username ?? ""
            let message = notification.type.notificationMessage
            let additionalText = notification.type != .postWentWithMention ? (notification.text ?? "") : ""
            
            let fullText = "@\(username)\(message)\(additionalText.isEmpty ? "" : " \(additionalText)")"
            
            var result = AttributedString(fullText)
            result.font = .custom("MuseoSansRounded-300", size: 16)
            result.foregroundColor = .black
            
            // Make the main username bold and black
            if let usernameRange = result.range(of: "@\(username)") {
                result[usernameRange].font = .custom("MuseoSansRounded-300", size: 16).weight(.semibold)
                result[usernameRange].foregroundColor = .black
            }
            
            // Parse and color additional mentions
            let pattern = "@\\w+"
            guard let regex = try? NSRegularExpression(pattern: pattern) else {
                return result
            }
            
            let nsRange = NSRange(fullText.startIndex..., in: fullText)
            let matches = regex.matches(in: fullText, range: nsRange)
            
            for match in matches {
                guard let range = Range(match.range, in: fullText),
                      let attributedRange = Range(range, in: result) else { continue }
                
                let matchedUsername = String(fullText[range].dropFirst())  // Remove '@' from the matched string
                
                // Color in red only if it's not the main username
                if matchedUsername != username {
                    result[attributedRange].foregroundColor = .red
                }
            }
            
            return result
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
        if let postId = notification.postId {
            fetchPost(postId: postId)
        } else if let restaurantId = notification.restaurantId {
            self.selectedRestaurantId = restaurantId
            self.showRestaurant = true
        }
    }
    
    private func handleFollowAction() {
        Task {
            isFollowed ? try await viewModel.unfollow(userId: notification.uid) : try await viewModel.follow(userId: notification.uid)
            self.isFollowed.toggle()
        }
    }
    
    private func handlePostThumbnailTap() {
        if let postId = notification.postId {
            fetchPost(postId: postId)
        }
    }
    
    private func fetchPost(postId: String) {
        Task {
            print("Fetching post with ID \(postId)")
            self.post = try await PostService.shared.fetchPost(postId: postId)
            print("Fetched post: \(String(describing: self.post))")
            if let post{
                feedViewModel.posts = [post]
            }
            if let commentId = notification.commentId{
                feedViewModel.selectedCommentId = commentId
            }
            showPost = true
        
        }
    }
    
    @ViewBuilder
    private var restaurantProfileView: some View {
        NavigationStack {
            if let selectedRestaurantId = selectedRestaurantId {
                let _ = print("Showing RestaurantProfileView for \(selectedRestaurantId)")
                RestaurantProfileView(restaurantId: selectedRestaurantId)
            }
        }
    }
    
    @ViewBuilder
    private var postView: some View {
        NavigationStack {
            if let post = post {
               
                
                if post.mediaType == .written {
                    NavigationView {
                        WrittenFeedCell(viewModel: feedViewModel, post: .constant(post), scrollPosition: .constant(nil), pauseVideo: .constant(false), selectedPost: .constant(nil), checkLikes: true)
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
                } else {
                    SecondaryFeedView(viewModel: feedViewModel, hideFeedOptions: true)
                }
            }
        }
    }
}

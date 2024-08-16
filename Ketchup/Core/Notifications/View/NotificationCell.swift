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
    @ObservedObject var collectionsViewModel: CollectionsViewModel
    var body: some View {
        HStack(spacing: 12) {
            NavigationLink(value: notification.user) {
                UserCircularProfileImageView(profileImageUrl: notification.user?.profileImageUrl, size: .medium)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                notificationContent
                timestampText
            }
            
            Spacer()
            
            actionButton
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .background(Color.white)
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
        .fullScreenCover(item: $collectionsViewModel.selectedCollection) { collection in
            CollectionView(collectionsViewModel: collectionsViewModel)
                .onDisappear{
                    collectionsViewModel.selectedCollection = nil
                }
            
        }
    }
    
    private var notificationContent: some View {
        Button {
            handleNotificationTap()
        } label: {
            Text(fullNotificationMessage)
                .font(.custom("MuseoSansRounded-300", size: 14))
                .foregroundColor(.black)
                .multilineTextAlignment(.leading)
        }
    }
    
    
        private var fullNotificationMessage: AttributedString {
                let username = notification.user?.username ?? ""
                var message = ""
                
                switch notification.type {
                case .postBookmark:
                    if let restaurantName = notification.restaurantName {
                        message = " created a bookmark from your post of \(restaurantName)"
                    } else {
                        message = " bookmarked your post"
                    }
                default:
                    message = notification.type.notificationMessage
                }
                
                let additionalText = notification.type != .postWentWithMention ? (notification.text ?? "") : ""
                
                let fullText = "@\(username)\(message)\(additionalText.isEmpty ? "" : " \(additionalText)")"
                
                var result = AttributedString(fullText)
                result.font = .custom("MuseoSansRounded-300", size: 14)
                result.foregroundColor = .black
                
                if let usernameRange = result.range(of: "@\(username)") {
                    result[usernameRange].font = .custom("MuseoSansRounded-700", size: 14)
                }
                
                if let restaurantName = notification.restaurantName,
                   let restaurantRange = result.range(of: "\"\(restaurantName)\"") {
                    result[restaurantRange].font = .custom("MuseoSansRounded-700", size: 14)
                }
        
        if let usernameRange = result.range(of: "@\(username)") {
            result[usernameRange].font = .custom("MuseoSansRounded-700", size: 14)
        }
        
        let pattern = "@\\w+"
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return result
        }
        
        let nsRange = NSRange(fullText.startIndex..., in: fullText)
        let matches = regex.matches(in: fullText, range: nsRange)
        
        for match in matches {
            guard let range = Range(match.range, in: fullText),
                  let attributedRange = Range(range, in: result) else { continue }
            
            let matchedUsername = String(fullText[range].dropFirst())
            
            if matchedUsername != username {
                result[attributedRange].foregroundColor = Color("Colors/AccentColor")
            }
        }
        
        return result
    }
    
    private var timestampText: some View {
        Text(notification.timestamp.timestampString())
            .foregroundColor(.gray)
            .font(.custom("MuseoSansRounded-300", size: 12))
    }
    
    private var actionButton: some View {
        Group {
            if notification.type == .follow {
                followButton
            } else if let postThumbnail = notification.postThumbnail, !postThumbnail.isEmpty {
                postThumbnailButton(postThumbnail)
            } else if let collectionImages = notification.collectionCoverImage {
                collectionButton(collectionImages)
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
                .frame(width: 44, height: 44)
                .clipShape(RoundedRectangle(cornerRadius: 4))
        }
    }
    private func collectionButton(_ thumbnail: [String]) -> some View {
        Button(action: handleCollectionTap) {
            CollageImage(tempImageUrls: thumbnail, width: 44)
                
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
        } else if notification.collectionId != nil {
            handleCollectionTap()
        }
    }
    
    private func handleFollowAction() {
        Task {
            isFollowed ? try await viewModel.unfollow(userId: notification.uid) : try await viewModel.follow(userId: notification.uid)
            self.isFollowed.toggle()
        }
    }
    private func handleCollectionTap() {
        if let collectionId = notification.collectionId {
            Task {
                collectionsViewModel.selectedCollection = try await CollectionService.shared.fetchCollection(withId: collectionId)
            }
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
    private func fetchCollection(collectionId: String) {
        Task {
            print("Fetching collection with ID \(collectionId)")
            
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

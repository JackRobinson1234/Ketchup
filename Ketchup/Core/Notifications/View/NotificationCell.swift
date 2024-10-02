//
//  NotificationCell.swift
//  Foodi
//
//  Created by Jack Robinson on 2/1/24.
//
import SwiftUI
import Kingfisher
import Combine
import Foundation

struct NotificationCell: View {
    @ObservedObject var viewModel: NotificationsViewModel
    var notification: Notification
    @State private var isFollowed: Bool = false
    @State private var showRestaurant = false
    @State private var selectedRestaurantId: String? = nil
    @State private var post: Post?
    @State private var showPost: Bool = false
    @State private var showUserProfile = false
    @ObservedObject var feedViewModel: FeedViewModel
    @ObservedObject var collectionsViewModel: CollectionsViewModel
    @State private var inviteStatus: InviteStatus
    @State private var showRejectAlert: Bool = false

    // New state variables for Poll
    @State private var showPoll: Bool = false
    @State private var poll: Poll?
    @ObservedObject var pollViewModel: PollViewModel  // Add this line

        init(viewModel: NotificationsViewModel, notification: Notification, feedViewModel: FeedViewModel, collectionsViewModel: CollectionsViewModel, pollViewModel: PollViewModel) {
            self.viewModel = viewModel
            self.notification = notification
            self.feedViewModel = feedViewModel
            self.collectionsViewModel = collectionsViewModel
            self.pollViewModel = pollViewModel  // Initialize here
            self._inviteStatus = State(initialValue: notification.inviteStatus ?? .pending)
        }

    var body: some View {
        HStack(spacing: 12) {
            Button(action: {
                showUserProfile = true
            }) {
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
        .onAppear{
            checkFollowStatus()
            checkInviteStatus()
        }
        .fullScreenCover(isPresented: Binding(
            get: { showPoll  },
            set: { showPoll = $0 }
        ))  {
            pollDetailView
        }
        .fullScreenCover(isPresented: Binding(
            get: { showUserProfile  },
            set: { showUserProfile = $0 }
        ))  {
            if let user = notification.user {
                NavigationStack {
                    ProfileView(uid: user.id)
                }
            }
        }
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
                .onDisappear {
                    collectionsViewModel.selectedCollection = nil
                }
        }
        // New fullScreenCover for Poll view
       
        .alert("Reject Invitation", isPresented: $showRejectAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Reject", role: .destructive) {
                rejectInvite()
            }
        } message: {
            Text("Are you sure you want to reject the invitation to collaborate on '\(notification.text ?? "this collection")'? This action cannot be undone.")
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

    private func checkInviteStatus() {
        Task {
            if let collectionId = notification.collectionId {
                inviteStatus = await viewModel.checkCollectionStatus(collectionId: collectionId)
            }
        }
    }

    private var fullNotificationMessage: AttributedString {
        let username = notification.user?.username ?? ""
        let message = generateMessage(for: notification)
        let additionalText = shouldAppendAdditionalText(notification) ? (notification.text ?? "") : ""
        let fullText = "@\(username)\(message)\(additionalText.isEmpty ? "" : " \(additionalText)")"

        var result = AttributedString(fullText)
        result.font = .custom("MuseoSansRounded-300", size: 14)
        result.foregroundColor = .black

        applyBoldFontToUsername(&result, username: username)
        applyBoldFontToRestaurantName(&result)
        applyAccentColorToMentions(&result, fullText: fullText, username: username)

        return result
    }

    private func generateMessage(for notification: Notification) -> String {
        switch notification.type {
        case .welcomeReferral:
            return " referred you to Ketchup. Welcome!"
        case .newReferral:
            return " joined Ketchup using your referral!"
        case .postBookmark:
            if let restaurantName = notification.restaurantName {
                return " created a bookmark from your post of \(restaurantName)"
            } else {
                return " bookmarked your post"
            }
        case .collectionInvite:
            return " invited you to collaborate on \(notification.text ?? "a collection")"
        case .newCollectionItem:
            return " added \(notification.text ?? "an item") to \(notification.collectionName ?? "a collection")"
        case .collectionInviteAccepted:
            return " accepted your invitation to collaborate on \(notification.text ?? "a collection")"
        case .badgeUpgrade:
            return " \(notification.type.notificationMessage) \(notification.badgeName ?? "new") badge to \(notification.newTier ?? "a new tier")"
        default:
            return notification.type.notificationMessage
        }
    }
    @ViewBuilder
    private var pollDetailView: some View {
        NavigationStack {
            if let pollIndex = pollViewModel.polls.firstIndex(where: { $0.id == poll?.id }),
               let poll = pollViewModel.polls[safe: pollIndex] {
                PollView(
                    poll: Binding<Poll>(
                        get: { poll },
                        set: { pollViewModel.polls[pollIndex] = $0 }
                    ),
                    pollViewModel: pollViewModel,
                    feedViewModel: feedViewModel
                )
                .navigationBarItems(leading: Button("Close") {
                    showPoll = false
                })
            } else if let poll = poll {
                // If poll is not in the polls array yet
                PollView(
                    poll: .constant(poll),
                    pollViewModel: pollViewModel,
                    feedViewModel: feedViewModel
                )
                .navigationBarItems(leading: Button("Close") {
                    showPoll = false
                })
            } else {
                Text("Poll not found")
                    .onAppear {
                        showPoll = false
                    }
            }
        }
    }
    private func shouldAppendAdditionalText(_ notification: Notification) -> Bool {
        return ![.postWentWithMention, .newCollectionItem, .welcomeReferral, .newReferral].contains(notification.type)
    }

    private func applyBoldFontToUsername(_ result: inout AttributedString, username: String) {
        if let usernameRange = result.range(of: "@\(username)") {
            result[usernameRange].font = .custom("MuseoSansRounded-700", size: 14)
        }
    }

    private func applyBoldFontToRestaurantName(_ result: inout AttributedString) {
        if let restaurantName = notification.restaurantName,
           let restaurantRange = result.range(of: "\"\(restaurantName)\"") {
            result[restaurantRange].font = .custom("MuseoSansRounded-700", size: 14)
        }
    }

    private func applyAccentColorToMentions(_ result: inout AttributedString, fullText: String, username: String) {
        let pattern = "@\\w+"
        if let regex = try? NSRegularExpression(pattern: pattern) {
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
        }
    }

    private var timestampText: some View {
        Text(notification.timestamp.timestampString())
            .foregroundColor(.gray)
            .font(.custom("MuseoSansRounded-300", size: 12))
    }

    @ViewBuilder
    private var actionButton: some View {
        switch notification.type {
        case .follow, .newUser, .welcomeReferral, .newReferral:
            followButton
        case .collectionInvite:
            inviteActionButtons
        case .collectionInviteAccepted:
            collectionButton(notification.collectionCoverImage ?? [])
        case .badgeUpgrade:
            if let image = notification.postThumbnail {
                Image(image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 44, height: 44)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            }
        default:
            if let postThumbnail = notification.postThumbnail, !postThumbnail.isEmpty {
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

    private var inviteActionButtons: some View {
        Group {
            switch inviteStatus {
            case .pending:
                HStack(spacing: 8) {
                    Button(action: acceptInvite) {
                        Image(systemName: "checkmark")
                            .foregroundColor(.green)
                    }
                    Button(action: { showRejectAlert = true }) {
                        Image(systemName: "x.circle")
                            .foregroundColor(.red)
                    }
                }
            case .accepted:
                Text("Accepted")
                    .foregroundColor(.green)
                    .font(.custom("MuseoSansRounded-300", size: 14))
            case .rejected:
                Text("Rejected")
                    .foregroundColor(.red)
                    .font(.custom("MuseoSansRounded-300", size: 14))
            }
        }
    }

    private func checkFollowStatus() {
        if notification.type == .follow || notification.type == .newUser || notification.type == .welcomeReferral || notification.type == .newReferral {
            Task {
                self.isFollowed = await viewModel.checkIfUserIsFollowed(userId: notification.uid)
            }
        }
    }

    private func handleNotificationTap() {
        switch notification.type {
        case .collectionInvite, .collectionInviteAccepted, .newCollectionItem:
            handleCollectionTap()
        default:
            if let pollId = notification.pollId {
                fetchPoll(pollId: pollId)
            } else if let postId = notification.postId {
                fetchPost(postId: postId)
            } else if let restaurantId = notification.restaurantId {
                self.selectedRestaurantId = restaurantId
                self.showRestaurant = true
            } else {
                showUserProfile = true
            }
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
            self.post = try await PostService.shared.fetchPost(postId: postId)
            if let post = self.post {
                feedViewModel.posts = [post]
            }
            if let commentId = notification.commentId {
                feedViewModel.selectedCommentId = commentId
            }
            showPost = true
        }
    }

    // New function to fetch the poll
    private func fetchPoll(pollId: String) {
        Task {
            do {
                if let poll = try await pollViewModel.fetchPoll(withId: pollId) {
                    self.poll = poll
                    self.showPoll = true
                    if let commentId = notification.commentId {
                        feedViewModel.selectedCommentId = commentId
                    }
                }
                
            } catch {
                print("Failed to fetch poll: \(error.localizedDescription)")
            }
        }
    }
    private func acceptInvite() {
        Task {
            if let collectionId = notification.collectionId {
                await viewModel.acceptCollectionInvite(notificationId: notification.id, collectionId: collectionId)
                inviteStatus = .accepted
            }
        }
    }

    private func rejectInvite() {
        Task {
            if let collectionId = notification.collectionId {
                await viewModel.rejectCollectionInvite(notificationId: notification.id, collectionId: collectionId)
                inviteStatus = .rejected
            }
        }
    }

    @ViewBuilder
    private var restaurantProfileView: some View {
        NavigationStack {
            if let selectedRestaurantId = selectedRestaurantId {
                RestaurantProfileView(restaurantId: selectedRestaurantId)
            }
        }
    }

    @ViewBuilder
    private var postView: some View {
        NavigationStack {
            if let post = post {
                if let mediaUrls = post.mixedMediaUrls, post.mediaType == .written || mediaUrls.isEmpty{
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
                    if #available(iOS 17, *) {
                        SecondaryFeedView(viewModel: feedViewModel, hideFeedOptions: true, checkLikes: true)
                    } else {
                        IOS16SecondaryFeedView(viewModel: feedViewModel, hideFeedOptions: true, checkLikes: true)
                    }
                }
            }
        }
    }
}
extension Swift.Collection {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

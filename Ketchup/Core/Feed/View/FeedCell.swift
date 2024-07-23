//
//  FeedCell.swift
//  Foodi
//
//  Created by Jack Robinson on 2/1/24.
//

//
//  FeedCell.swift
//  Foodi
//
//  Created by Jack Robinson on 2/1/24.
//

import SwiftUI
import AVKit
import Photos
import Kingfisher
import FirebaseAuth
import UIKit
struct FeedCell: View {
    @Binding var post: Post
    @StateObject var videoCoordinator: VideoPlayerCoordinator
    @ObservedObject var viewModel: FeedViewModel
    @State private var expandCaption = false
    @State private var showComments = false
    @State private var showShareView = false
    @State private var showRecipe = false
    @State private var showCollections = false
    @State private var videoConfigured = false
    private var didLike: Bool { return post.didLike }
    @Binding var scrollPosition: String?
    @Binding var pauseVideo: Bool
    @State private var showingOptionsSheet = false
    @State private var showingRepostSheet = false
    @State private var currentImageIndex = 0
    @State var isDragging = false
    @State var dragDirection = "left"
    var hideFeedOptions: Bool
    @Environment(\.dismiss) var dismiss
    @State var showHeartOverlay = false
    @State private var offset: CGFloat = 0
    @GestureState private var dragOffset: CGFloat = 0
    @State private var showRatingDetails = false
    @State private var isTaggedSheetPresented = false
    @State private var parsedCaption: AttributedString?
    var checkLikes: Bool
    var overallRating: Double? {
        let ratings = [post.foodRating, post.atmosphereRating, post.valueRating, post.serviceRating].compactMap { $0 }
        guard !ratings.isEmpty else { return nil }
        return ratings.reduce(0, +) / Double(ratings.count)
    }
    private var didBookmark: Bool {
        return post.didBookmark
    }
    init(post: Binding<Post>,
         viewModel: FeedViewModel,
         scrollPosition: Binding<String?>,
         pauseVideo: Binding<Bool>,
         hideFeedOptions: Bool,
         checkLikes: Bool = false) {
        
        self._post = post
        self.viewModel = viewModel
        self._scrollPosition = scrollPosition
        self._pauseVideo = pauseVideo
        self.hideFeedOptions = hideFeedOptions
        self.checkLikes = checkLikes
        
        if post.wrappedValue.mediaType == .video {
            let coordinator = VideoPrefetcher.shared.getPlayerItem(for: post.wrappedValue)
            self._videoCoordinator = StateObject(wrappedValue: coordinator)
        } else {
            // Initialize with a dummy coordinator for non-video posts
            self._videoCoordinator = StateObject(wrappedValue: VideoPlayerCoordinator())
        }
    }
    
    var drag: some Gesture {
        DragGesture(minimumDistance: 5)
            .onChanged { _ in self.isDragging = true }
            .onEnded { endedGesture in
                if (endedGesture.location.x - endedGesture.startLocation.x) > 0 {
                    self.dragDirection = "left"
                    if self.currentImageIndex > 0 {
                        withAnimation(.easeInOut) {
                            self.currentImageIndex -= 1
                        }
                    } else {
                        viewModel.initialPrimaryScrollPosition = scrollPosition
                        dismiss()
                    }
                } else {
                    self.dragDirection = "right"
                    if self.currentImageIndex < post.mediaUrls.count - 1 {
                        withAnimation(.easeInOut) {
                            self.currentImageIndex += 1
                        }
                    }
                }
                self.isDragging = false
            }
    }

    var body: some View {
            ZStack {
                Color("Colors/HingeGray")
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    Spacer()
                    ZStack {
                        if post.mediaType == .video {
                            ZoomableVideoPlayer(videoCoordinator: videoCoordinator)
                            //VideoPlayerView(coordinator: videoCoordinator, videoGravity: .resizeAspectFill)
                                .overlay(taggedUsersOverlay)
                                .clipShape(RoundedRectangle(cornerRadius: 20))
                                .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.width * 1.333)
                        } else if post.mediaType == .photo {
                            GeometryReader { geometry in
                                TabView(selection: $currentImageIndex) {
                                    ForEach(0..<post.mediaUrls.count, id: \.self) { index in
                                        ZoomableImage(imageURL: post.mediaUrls[index])
                                            .tag(index)
                                    }
                                }
                                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                                .overlay(taggedUsersOverlay)
                                .overlay(imageIndexIndicator)
                            }
                            .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.width * 1.333)
                        }
                    }
                    Spacer()
                }
                .overlay(videoSliderOverlay)
                .padding(.bottom, 137)
            }
            .padding(.top, 35)
            .overlay(heartOverlay)
            .onTapGesture(count: 2) {
                handleLikeTapped()
            }
            .onTapGesture {
                toggleVideoPlayback()
            }
            // Remove the .gesture(drag) here as it's now handled in ZoomableImage
            .gesture(drag)
            .onAppear {
                handleOnAppear()
            }
            .onDisappear {
                videoCoordinator.pause()
            }
            .sheet(isPresented: $showComments) {
                CommentsView(post: $post)
                    .presentationDetents([.height(UIScreen.main.bounds.height * 0.65)])
                    .onDisappear { Task { videoCoordinator.play() } }
            }
            .sheet(isPresented: $showShareView) {
                ShareView(post: post, currentImageIndex: currentImageIndex)
                    .presentationDetents([.height(UIScreen.main.bounds.height * 0.15)])
                    .onDisappear { Task { videoCoordinator.play() } }
            }
            .sheet(isPresented: $showCollections) {
                if let currentUser = AuthService.shared.userSession {
                    AddItemCollectionList(post: post)
                }
            }
            .gesture(drag)
            .sheet(isPresented: $showingOptionsSheet) {
                PostOptionsSheet(post: $post, viewModel: viewModel)
                    .presentationDetents([.height(UIScreen.main.bounds.height * 0.15)])
            }
            .sheet(isPresented: $showingRepostSheet) {
                RepostView(viewModel: viewModel, post: post)
                    .presentationDetents([.height(UIScreen.main.bounds.height * 0.35)])
            }
            .onChange(of: scrollPosition) { oldValue, newValue in
                handleScrollPositionChange(newValue: newValue)
            }
            .onChange(of: pauseVideo) { oldValue, newValue in
                handlePauseVideoChange(newValue: newValue)
            }
            .overlay(
                GeometryReader { geometry in
                    VStack {
                        Spacer()
                        captionAndRatingsBox
                            .animation(.spring(), value: expandCaption)
                            
                    }
                    .padding(.bottom, 50)
                }
            )
            .sheet(isPresented: $isTaggedSheetPresented) {
                TaggedUsersSheetView(taggedUsers: post.taggedUsers)
            }
        }

        private var captionAndRatingsBox: some View {
            VStack(alignment: .leading, spacing: 7) {
                
                actionButtons
                
                HStack {
                    let restaurant = post.restaurant
                    NavigationLink(value: restaurant) {
                        RestaurantRectangleProfileImageView(imageUrl: restaurant.profileImageUrl, size: .large)
                    }
                    VStack(alignment: .leading) {
                        NavigationLink(value: restaurant) {
                            Text("\(restaurant.name)")
                                .font(.custom("MuseoSansRounded-300", size: 20))
                                .bold()
                                .multilineTextAlignment(.leading)
                                .minimumScaleFactor(0.5) // Add this line
                                .lineLimit(1) // Ensure single-line
                        }
                        Text("\(restaurant.city ?? ""), \(restaurant.state ?? "")")
                            .minimumScaleFactor(0.5) // Add this line
                            .lineLimit(1) // Ensure single-line
                        NavigationLink(value: post.user) {
                            Text("by \(post.user.fullname)")
                                .font(.custom("MuseoSansRounded-300", size: 16))
                                .fontWeight(.semibold)
                                .foregroundStyle(Color("Colors/AccentColor"))
                                .bold()
                                .multilineTextAlignment(.leading)
                                .minimumScaleFactor(0.5) // Add this line
                                .lineLimit(1) // Ensure single-line
                        }
                        .disabled(post.user.username == "ketchup_media")
                    }
                    Spacer()
                    if let overallRating = overallRating {
                        ScrollFeedOverallRatingView(rating: overallRating, font: .black)
                    }
                    
                    
                }
                
                
                
                
                
                // Overall rating
                
                Button(action: {
                    withAnimation(.spring()) { expandCaption.toggle() }
                }) {
                    VStack(alignment: .leading, spacing: 7){
                        if let parsed = parsedCaption {
                            Text(parsed)
                                .font(.custom("MuseoSansRounded-300", size: 16))
                                .lineLimit(expandCaption ? 50 : 1)
                                .font(.custom("MuseoSansRounded-300", size: 16))
                                .multilineTextAlignment(.leading)
                        } else {
                            Text(post.caption)
                                .font(.custom("MuseoSansRounded-300", size: 16))
                                .onAppear {
                                    parsedCaption = parseCaption(post.caption)
                                }
                                .lineLimit(expandCaption ? 50 : 1)
                                .font(.custom("MuseoSansRounded-300", size: 16))
                                .multilineTextAlignment(.leading)
                        }

                        
                        if !expandCaption {
                            Text("See more...")
                                .font(.custom("MuseoSansRounded-300", size: 10))
                                .foregroundColor(Color("Colors/AccentColor"))
                            
                        }
                        else {
                            // Other ratings
                            if !post.taggedUsers.isEmpty {
                                Button(action: {
                                    isTaggedSheetPresented.toggle()
                                }) {
                                    HStack {
                                        Text("Went with:")
                                            .font(.custom("MuseoSansRounded-300", size: 16))
                                            .bold()
                                        
                                        // Display profile images of the first three tagged users
                                        ForEach(post.taggedUsers.prefix(3), id: \.id) { user in
                                            UserCircularProfileImageView(profileImageUrl: user.profileImageUrl, size: .xxSmall)
                                        }
                                        
                                        // If there are more than three users, display the count of additional users
                                        if post.taggedUsers.count > 3 {
                                            VStack {
                                                Spacer()
                                                Text("and \(post.taggedUsers.count - 3) others")
                                                    .font(.custom("MuseoSansRounded-300", size: 12))
                                            }
                                        }
                                        
                                        Spacer()
                                    }
                                    .frame(height: 15)
                                }
                                .padding(.vertical, 3)
                            }
                                
                            
                            VStack(alignment: .leading, spacing: 5) {
                                if let foodRating = post.foodRating {
                                    RatingSlider(rating: foodRating, label: "Food", isOverall: false, fontColor: .black)
                                }
                                if let atmosphereRating = post.atmosphereRating {
                                    RatingSlider(rating: atmosphereRating, label: "Atmosphere", isOverall: false, fontColor: .black)
                                }
                                if let valueRating = post.valueRating {
                                    RatingSlider(rating: valueRating, label: "Value", isOverall: false, fontColor: .black)
                                }
                                if let serviceRating = post.serviceRating {
                                    RatingSlider(rating: serviceRating, label: "Service", isOverall: false, fontColor: .black)
                                }
                            }
                            
                            
                            if let timestamp = post.timestamp {
                                Text(getTimeElapsedString(from: timestamp))
                                    .font(.custom("MuseoSansRounded-300", size: 10))
                                    .foregroundColor(.black)
                            }
                            
                            
                            
                            Text("See less...")
                                .font(.custom("MuseoSansRounded-300", size: 10))
                                .foregroundColor(Color("Colors/AccentColor"))
                        }
                    }
                }
                

            }
            .padding(.horizontal)
            .padding(.top, 10)
            .font(.custom("MuseoSansRounded-300", size: 16))
            .foregroundStyle(.black)
            .background(Color("Colors/HingeGray"))
            .frame(width: UIScreen.main.bounds.width)
        }


    private var actionButtons: some View {
        HStack(spacing: 25) {
            
            Button {
                handleLikeTapped()
            } label: {
                InteractionButtonView(icon: didLike ? "heart.fill" : "heart", count: post.likes, color: didLike ? Color("Colors/AccentColor") : .gray)
            }
            
            Button {
                videoCoordinator.pause()
                showComments.toggle()
            } label: {
                InteractionButtonView(icon: "ellipsis.bubble", count: post.commentCount)
            }
            
            if viewModel.showBookmarks{
                Button {
                    handleBookmarkTapped()
                } label: {
                    InteractionButtonView(icon: didBookmark ? "bookmark.fill" : "bookmark", color: didBookmark ? Color("Colors/AccentColor") : .gray, width: 20, height: 20)
                }
            }
            if viewModel.showBookmarks{
                Button {
                    videoCoordinator.pause()
                    showCollections.toggle()
                } label: {
                    InteractionButtonView(icon: "folder.badge.plus", width: 24, height: 24)
                }
            }
            
            Button {
                videoCoordinator.pause()
                showShareView.toggle()
            } label: {
                InteractionButtonView(icon: "arrowshape.turn.up.right", width: 22, height: 22)
            }
            
            Button {
                videoCoordinator.pause()
                showingOptionsSheet = true
            } label: {
                ZStack {
                    Rectangle()
                        .fill(.clear)
                        .frame(width: 20, height: 28)
                    Image(systemName: "ellipsis")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 5, height: 5)
                        .foregroundColor(.gray)
                }
            }
            
        }
    }
    
    private var videoSlider: some View {
        let totalTime = videoCoordinator.duration.isFinite ? max(videoCoordinator.duration, 0) : 0
        return Slider(value: $videoCoordinator.currentTime, in: 0...totalTime, onEditingChanged: sliderEditingChanged)
            .onAppear {
                let clearCircleImage = UIImage.clearCircle(radius: 15, lineWidth: 1, color: .clear)
                UISlider.appearance().setThumbImage(clearCircleImage, for: .normal)
            }
            .offset(y: 40)
    }
    
    private var heartOverlay: some View {
        ZStack {
            if showHeartOverlay {
                Image(systemName: "heart.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .foregroundStyle(Color("Colors/AccentColor"))
                    .transition(.opacity)
            }
        }
    }
    private func parseCaption(_ input: String) -> AttributedString {
        var result = AttributedString(input)
        let pattern = "@\\w+"
        
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return result
        }
        
        let nsRange = NSRange(input.startIndex..., in: input)
        let matches = regex.matches(in: input, range: nsRange)
        
        for match in matches.reversed() {
            guard let range = Range(match.range, in: input) else { continue }
            
            let fullMatch = String(input[range])
            let username = String(fullMatch.dropFirst()) // Remove @ from username
            
            if let user = post.captionMentions.first(where: { $0.username.lowercased() == username.lowercased() }),
               let attributedRange = Range(range, in: result) {
                result[attributedRange].foregroundColor = Color("Colors/AccentColor")
                result[attributedRange].link = URL(string: "user://\(user.id)")
            }
        }
        
        return result
    }
    private func handleLikeTapped() {
        Task {
            didLike ? await viewModel.unlike(post) : await viewModel.like(post)
            if didLike {
                withAnimation {
                    showHeartOverlay = true
                }
                Debouncer(delay: 1.0).schedule {
                    withAnimation {
                        showHeartOverlay = false
                    }
                }
            }
        }
    }
    
    private func toggleVideoPlayback() {
        guard post.mediaType == .video else { return }
        let player = videoCoordinator.player
        switch player.timeControlStatus {
        case .paused:
            videoCoordinator.play()
        case .waitingToPlayAtSpecifiedRate:
            break
        case .playing:
            videoCoordinator.pause()
        @unknown default:
            break
        }
    }
    
    private func handleScrollPositionChange(newValue: String?) {
        guard post.mediaType == .video else { return }
        if newValue == post.id {
            videoCoordinator.replay()
        } else {
            videoCoordinator.pause()
        }
    }
    
    private func handlePauseVideoChange(newValue: Bool) {
        guard post.mediaType == .video else { return }
        if scrollPosition == post.id || viewModel.posts.first?.id == post.id && scrollPosition == nil {
            if newValue == true {
                videoCoordinator.pause()
            } else {
                videoCoordinator.play()
            }
        }
    }
    
    private func handleOnAppear() {
        if checkLikes{
            Task{
                post.didLike = try await PostService.shared.checkIfUserLikedPost(post)
            }
        }
        if post.mediaType == .video {
            if let firstPost = viewModel.posts.first, firstPost.id == post.id && scrollPosition == nil {
                videoCoordinator.replay()
            }
        }
        
        if viewModel.startingPostId == post.id, post.mediaType == .photo {
            self.currentImageIndex = viewModel.startingImageIndex
            viewModel.startingPostId = ""
            viewModel.startingImageIndex = 0
        } else if viewModel.startingPostId == post.id, post.mediaType == .video {
            Task { videoCoordinator.play() }
        }
    }
    
    private func sliderEditingChanged(_ editingStarted: Bool) {
        if editingStarted {
            videoCoordinator.pause()
        } else {
            videoCoordinator.seekToTime(seconds: videoCoordinator.currentTime)
            videoCoordinator.play()
        }
    }
    private func handleBookmarkTapped() {
        Task {
            if post.didBookmark {
                await viewModel.unbookmark(post)
            } else {
                await viewModel.bookmark(post)
            }
        }
    }
    private var taggedUsersOverlay: some View {
            Group {
                if !post.taggedUsers.isEmpty {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Button {
                                isTaggedSheetPresented.toggle()
                            } label: {
                                Image(systemName: "person.2.circle.fill")
                                    .symbolRenderingMode(.palette)
                                    .foregroundStyle(.white, .red)
                                    .font(.system(size: 30))
                            }
                        }
                    }
                    .padding()
                }
            }
        }

        private var imageIndexIndicator: some View {
            Group {
                if post.mediaUrls.count > 1 {
                    VStack {
                        HStack(spacing: 6) {
                            ForEach(0..<post.mediaUrls.count, id: \.self) { index in
                                Circle()
                                    .fill(index == currentImageIndex ? Color("Colors/AccentColor") : Color.gray)
                                    .frame(width: 10, height: 10)
                            }
                        }
                        .padding(.top, 30)
                        Spacer()
                    }
                }
            }
        }

        private var videoSliderOverlay: some View {
            Group {
                if post.mediaType == .video {
                    VStack {
                        videoSlider
                            .padding(.top, 40)
                        Spacer()
                    }
                }
            }
        }

        private var captionAndRatingsOverlay: some View {
            GeometryReader { geometry in
                VStack {
                    Spacer()
                    captionAndRatingsBox
                        .animation(.spring(), value: expandCaption)
                }
                .padding(.bottom, 50)
            }
        }
}

//MARK: Photo Library Access
func requestPhotoLibraryAccess(completion: @escaping (Bool) -> Void) {
    PHPhotoLibrary.requestAuthorization { status in
        switch status {
        case .authorized:
            completion(true)
        case .denied, .restricted, .notDetermined:
            completion(false)
        case .limited:
            completion(true)
        @unknown default:
            completion(false)
        }
    }
}

#Preview {
    FeedCell(
        post: .constant(DeveloperPreview.posts[0]),
        viewModel: FeedViewModel(),
        scrollPosition: .constant(""),
        pauseVideo: .constant(true),
        hideFeedOptions: true
    )
}

extension UIImage {
    static func clearCircle(radius: CGFloat, lineWidth: CGFloat, color: UIColor = .clear) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(CGSize(width: radius * 2, height: radius * 2), false, 0.0)
        defer { UIGraphicsEndImageContext() }
        guard let context = UIGraphicsGetCurrentContext() else { return nil }

        context.setLineWidth(lineWidth)
        context.setStrokeColor(color.cgColor)
        let rectangle = CGRect(x: lineWidth / 2, y: lineWidth / 2, width: radius * 2 - lineWidth, height: radius * 2 - lineWidth)
        context.addEllipse(in: rectangle)
        context.strokePath()

        return UIGraphicsGetImageFromCurrentImageContext()?.withRenderingMode(.alwaysOriginal)
    }
}

struct ScrollFeedOverallRatingView: View {
    let rating: Double?
    var font: Color? = .primary
    var body: some View {
        if let rating = rating {
            VStack(spacing: 4) {
                ZStack {
                    Circle()
                        .stroke(lineWidth: 6) // Thicker stroke
                        .opacity(0.3)
                        .foregroundColor(Color.gray)

                    Circle()
                        .trim(from: 0.0, to: CGFloat(min(rating / 10, 1.0)))
                        .stroke(Color("Colors/AccentColor"), style: StrokeStyle(lineWidth: 6, lineCap: .round, lineJoin: .round)) // Thicker stroke
                        .rotationEffect(Angle(degrees: 270.0))
                        .animation(.linear, value: rating)

                    Text(String(format: "%.1f", rating))
                        .font(.custom("MuseoSansRounded-500", size: 24)) // Larger font size
                        .foregroundColor(font) // Apply the font color
                }
                .frame(width: 60, height: 60) // Larger size
            }
        }
    }
}

struct ZoomableImage: View {
    let imageURL: String

    var body: some View {
        ZoomableScrollView {
            KFImage(URL(string: imageURL))
                .resizable()
                .scaledToFit()
        }
    }
}

struct ZoomableScrollView<Content: View>: UIViewRepresentable {
    private var content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    func makeUIView(context: Context) -> UIScrollView {
        let scrollView = UIScrollView()
        scrollView.delegate = context.coordinator
        scrollView.maximumZoomScale = 5
        scrollView.minimumZoomScale = 1
        scrollView.bouncesZoom = true
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false

        let hostedView = context.coordinator.hostingController.view!
        hostedView.translatesAutoresizingMaskIntoConstraints = true
        hostedView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        hostedView.frame = scrollView.bounds
        scrollView.addSubview(hostedView)

        return scrollView
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(hostingController: UIHostingController(rootView: self.content))
    }

    func updateUIView(_ uiView: UIScrollView, context: Context) {
        context.coordinator.hostingController.rootView = self.content
        assert(context.coordinator.hostingController.view.superview == uiView)
    }

    class Coordinator: NSObject, UIScrollViewDelegate {
        var hostingController: UIHostingController<Content>
        private var initialZoomScale: CGFloat = 1.0

        init(hostingController: UIHostingController<Content>) {
            self.hostingController = hostingController
        }

        func viewForZooming(in scrollView: UIScrollView) -> UIView? {
            return hostingController.view
        }

        func scrollViewWillBeginZooming(_ scrollView: UIScrollView, with view: UIView?) {
            initialZoomScale = scrollView.zoomScale
        }

        func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
            if scale != initialZoomScale {
                withAnimation(.easeInOut(duration: 0.3)) {
                    scrollView.setZoomScale(1.0, animated: true)
                }
            }
        }

        func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
            if scrollView.zoomScale != 1.0 {
                withAnimation(.easeInOut(duration: 0.3)) {
                    scrollView.setZoomScale(1.0, animated: true)
                }
            }
        }
    }
}
struct ZoomableVideoPlayer: View {
    @ObservedObject var videoCoordinator: VideoPlayerCoordinator

    var body: some View {
        ZoomableScrollView {
            VideoPlayerView(coordinator: videoCoordinator, videoGravity: .resizeAspectFill)
        }
    }
}

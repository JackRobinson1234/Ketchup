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
    @StateObject var videoCoordinator = VideoPlayerCoordinator()
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
    
    var drag: some Gesture {
        DragGesture(minimumDistance: 50)
            .onChanged { _ in self.isDragging = true }
            .onEnded { endedGesture in
                if (endedGesture.location.x - endedGesture.startLocation.x) > 0 {
                    self.dragDirection = "left"
                    if self.currentImageIndex > 0 {
                        self.currentImageIndex -= 1
                    }
                } else {
                    self.dragDirection = "right"
                    if self.currentImageIndex < post.mediaUrls.count - 1 {
                        self.currentImageIndex += 1
                    }
                }
                self.isDragging = false
            }
    }
    
    
    var body: some View {
        //MARK: Loading Screen
        ZStack {
            if post.mediaType == "video" {
                if post.fromInAppCamera {
                    VideoPlayerView(coordinator: videoCoordinator, videoGravity: .resizeAspectFill)
                        .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
                        .containerRelativeFrame([.horizontal, .vertical])
                        .onTapGesture {
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
                } else {
                    VideoPlayerView(coordinator: videoCoordinator, videoGravity: .resizeAspect)
                        .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
                        .containerRelativeFrame([.horizontal, .vertical])
                        .onTapGesture {
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
                }
            } else if post.mediaType == "photo" {
                
                ZStack (alignment: .top){
                    if post.fromInAppCamera {
                        KFImage(URL(string: post.mediaUrls[currentImageIndex]))
                            .resizable()
                            .scaledToFill()
                            .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
                            .cornerRadius(20)
                            .containerRelativeFrame([.horizontal, .vertical])
                    } else {
                        KFImage(URL(string: post.mediaUrls[currentImageIndex]))
                            .resizable()
                            //.scaledToFit()
                            .scaledToFill()
                            .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
                            .cornerRadius(20)
                            .containerRelativeFrame([.horizontal, .vertical])
                    }
                    
                    VStack {
                        
                        HStack(spacing: 6) {
                            if post.mediaUrls.count > 1 {
                                ForEach(0..<post.mediaUrls.count, id: \.self) { index in
                                    Circle()
                                        .fill(index == currentImageIndex ? Color("Colors/AccentColor") : Color.white)
                                        .frame(width: 10, height: 10)
                                }
                            }
                        }
                        .padding(.top, 130)
                    
                    }
                }
            }
            ZStack (alignment: .bottom){
                VStack {
                    Spacer()
                    
                    HStack(alignment: .bottom) {
                        
                        // MARK: Caption Box
                        
                        VStack(alignment: .leading, spacing: 7) {
                            HStack{
                                //MARK:  restaurant profile image
                                if let restaurant = post.restaurant {
                                    NavigationLink(value: restaurant) {
                                        RestaurantCircularProfileImageView(imageUrl: restaurant.profileImageUrl, size: .large)
                                    }
                                    
                                    //MARK: Restaurant Name
                                    VStack (alignment: .leading) {
                                        NavigationLink(value: restaurant) {
                                            Text("\(restaurant.name)")
                                                .font(.title3)
                                                .bold()
                                                .multilineTextAlignment(.leading)
                                        }
                                        //MARK: Address
                                        Text("\(restaurant.city ?? ""), \(restaurant.state ?? "")")
                                        //MARK: Recipe Fullname
                                        NavigationLink(value: post.user) {
                                            Text("by \(post.user.fullname)")
                                                .font(.subheadline)
                                                .fontWeight(.semibold)
                                                .foregroundStyle(.white)
                                                .bold()
                                                .multilineTextAlignment(.leading)
                                        }
                                    }
                                    //MARK: Recipe Scenario
                                } else if let recipe = post.cookingTitle{
                                    VStack (alignment: .leading) {
                                        HStack(){
                                            if post.recipeId != nil{
                                                Button{
                                                    showRecipe.toggle()
                                                } label: {
                                                    VStack(spacing: 0){
                                                        Image("WhiteChefHat")
                                                            .resizable()
                                                            .scaledToFit()
                                                            .frame(width: 60, height: 60)
                                                        
                                                    }
                                                }
                                            }
                                            VStack(alignment: .leading){
                                                //MARK: recipe fullname
                                                
                                                Text("\(recipe)")
                                                    .font(.title3)
                                                    .bold()
                                                    .multilineTextAlignment(.leading)
                                                NavigationLink(value: post.user) {
                                                    Text("by \(post.user.fullname)")
                                                        .font(.subheadline)
                                                        .fontWeight(.semibold)
                                                        .foregroundStyle(.white)
                                                        .bold()
                                                        .multilineTextAlignment(.leading)
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                            
                            
                            //MARK: caption
                            Text(post.caption)
                                .lineLimit(expandCaption ? 50 : 1)
                                .font(.subheadline)
                            
                            //MARK: see more
                            if !expandCaption{
                                Text("See more...")
                                    .font(.footnote)
                            }
                            else {
                                //MARK: Menu Button
                                
                                if let restaurant = post.restaurant {
                                    NavigationLink(destination: RestaurantProfileView(restaurantId: restaurant.id, currentSection: .menu)) {
                                        Text("View Restaurant")
                                    }
                                    .modifier(StandardButtonModifier(width: 175))
                                    //MARK: Show recipe
                                } 
                                else if post.recipeId != nil {
                                    Button{
                                        showRecipe.toggle()
                                        Task{
                                            videoCoordinator.pause()
                                        }
                                    } label: {
                                        Text("View Recipe")
                                    }
                                    .modifier(StandardButtonModifier(width: 175))
                                    
                                }
                            }
                        }
                        
                        //controls box size
                        .padding(10)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.black.opacity(0.3))
                        )
                        .onTapGesture { withAnimation(.snappy) { expandCaption.toggle() } }
                        .font(.subheadline)
                        .foregroundStyle(.white)
                        .padding(.horizontal)
                        
                        
                        Spacer()
                        //MARK: Right hand VStack
                        VStack(spacing: 28) {
                            //MARK: user profile image
                            NavigationLink(value: post.user) {
                                UserCircularProfileImageView(profileImageUrl: post.user.profileImageUrl, size: .medium)
                            }
                            
                            //MARK: Delete/ Report
                            Button {
                                videoCoordinator.pause()
                                showingOptionsSheet = true
                            } label: {
                                ZStack{
                                    Rectangle()
                                        .fill(.clear)
                                        .frame(width: 28, height: 28)
                                    Image(systemName: "ellipsis")
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 6, height: 6)
                                        .foregroundStyle(.white)
                                }
                            }
                            //MARK: Repost Button
                            if let user = Auth.auth().currentUser?.uid,  post.user.id != user {
                                Button {
                                    showingRepostSheet.toggle()
                                } label: {
                                    VStack {
                                        Image(systemName: "arrow.2.squarepath")
                                        
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 28, height: 28)
                                            .foregroundStyle(.white)
                                            .rotationEffect(.degrees(90))
                                        Text("\(post.repostCount)")
                                            .font(.caption)
                                            .fontWeight(.bold)
                                        
                                        
                                    }
                                    .foregroundStyle(.white)
                                }
                            }
                            //MARK: Collection Button
                            Button {
                                videoCoordinator.pause()
                                showCollections.toggle()
                            } label: {
                                FeedCellActionButtonView(imageName: "folder.fill.badge.plus")
                            }
                            //MARK: Like button
                            Button {
                                handleLikeTapped()
                            } label: {
                                FeedCellActionButtonView(imageName: didLike ? "heart.fill": "heart.fill",
                                                         value: post.likes,
                                                         tintColor: didLike ? Color("Colors/AccentColor") : .white)
                            }
                            //MARK: comment button
                            Button {
                                videoCoordinator.pause()
                                showComments.toggle()
                            } label: {
                                FeedCellActionButtonView(imageName: "ellipsis.bubble.fill", value: post.commentCount)
                            }
                            // Bookmark button
                            
                            //MARK: share button
                            Button {
                                videoCoordinator.pause()
                                showShareView.toggle()
                            } label: {
                                Image(systemName: "arrowshape.turn.up.right.fill")
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 28, height: 28)
                                    .foregroundStyle(.white)
                            }
                        }
                        .padding(.horizontal)
                        
                        
                    }
                    
                }
                if post.mediaType == "video" {
                    let totalTime = videoCoordinator.duration.isFinite ? max(videoCoordinator.duration, 0) : 0
                    Slider(value: $videoCoordinator.currentTime, in: 0...totalTime, onEditingChanged: sliderEditingChanged)
                        .onAppear {
                            let clearCircleImage = UIImage.clearCircle(radius: 15, lineWidth: 1, color: .clear) // Adjust radius and line width as needed
                                UISlider.appearance().setThumbImage(clearCircleImage, for: .normal)
                        }
                        .offset(y: 40)
                }
            }
            .padding(.bottom, viewModel.isContainedInTabBar ? 115 : 70)
        }
        
        .gesture(drag)
        //MARK: Scroll Position replay/ pause
        .onChange(of: scrollPosition) {oldValue, newValue in
            if newValue == post.id {
                videoCoordinator.replay()
            } else {
                videoCoordinator.pause()
            }
        }
        //MARK: Scroll Position play/pause
        .onChange(of: pauseVideo) {oldValue, newValue in
            if scrollPosition == post.id || viewModel.posts.first?.id == post.id && scrollPosition == nil{
                if newValue == true {
                    videoCoordinator.pause()
                } else {
                    
                    videoCoordinator.play()
                    
                }
            }
        }
        //MARK: Configure Player
        .onAppear {
            Task{
                if let videoURL = post.mediaUrls.first {
                    videoCoordinator.configurePlayer(url: URL(string: videoURL), postId: post.id)
                }
                if viewModel.posts.first?.id == post.id && scrollPosition == nil {
                    videoCoordinator.replay()
                }
            }
        }
        .onDisappear{
            videoCoordinator.pause()
        }
        //MARK: sheets
        //overlays the comments if showcomments is true
        .sheet(isPresented: $showComments) {
            CommentsView(post: $post)
                .presentationDetents([.height(UIScreen.main.bounds.height * 0.65)])
                .onDisappear{Task{ videoCoordinator.play()}}
        }
        .sheet(isPresented: $showShareView) {
            ShareView(post: post, currentImageIndex: currentImageIndex)
                .presentationDetents([.height(UIScreen.main.bounds.height * 0.15)])
                .onDisappear{Task {videoCoordinator.play()}}
        }
                    .sheet(isPresented: $showRecipe) {
                        NewRecipeView(post: post)
                            .onDisappear{Task {videoCoordinator.play()}}
                    }
        .sheet(isPresented: $showCollections) {
            if let currentUser = AuthService.shared.userSession {
                AddItemCollectionList(user: currentUser, post: post)
            }
        }
        .sheet(isPresented: $showingOptionsSheet) {
            PostOptionsSheet(post: post, viewModel: viewModel)
                .presentationDetents([.height(UIScreen.main.bounds.height * 0.15)])
        }
        .sheet(isPresented: $showingRepostSheet){
            RepostView(viewModel: viewModel, post: post)
                .presentationDetents([.height(UIScreen.main.bounds.height * 0.35)])
        }
        //MARK: Tap to play/pause
        
    }
    //MARK: like and unlike functionality
    private func handleLikeTapped() {
        Task { didLike ? await viewModel.unlike(post) : await viewModel.like(post) }
    }
    private func formattedTime(time: Int?) -> String {
        guard let time = time else {
            return "Not specified"
        }
        
        let hours = time / 60
        let minutes = time % 60
        var timeString = ""
        
        if hours > 0 {
            timeString += "\(hours)h"
        }
        
        if minutes > 0 {
            timeString += " \(minutes)m"
        }
        
        return timeString.isEmpty ? "Not specified" : timeString
    }
    func sliderEditingChanged(_ editingStarted: Bool) {
        if editingStarted {
            videoCoordinator.pause()
        } else {
            videoCoordinator.seekToTime(seconds: videoCoordinator.currentTime)
            videoCoordinator.play()
        }
    }
    
}
//MARK: Photo Library Acess
func requestPhotoLibraryAccess(completion: @escaping (Bool) -> Void) {
    PHPhotoLibrary.requestAuthorization { status in
        switch status {
        case .authorized:
            // User has granted access
            completion(true)
        case .denied, .restricted:
            // User has denied or restricted access
            completion(false)
        case .notDetermined:
            // User has not yet made a decision
            completion(false)
        case .limited:
            completion(true)
        @unknown default:
            // Handle future cases
            completion(false)
        }
    }
}




#Preview {
    FeedCell(
        post: .constant(DeveloperPreview.posts[0]),
        videoCoordinator: VideoPlayerCoordinator(),
        viewModel: FeedViewModel()
        ,scrollPosition: .constant(""),
        pauseVideo: .constant(true)
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

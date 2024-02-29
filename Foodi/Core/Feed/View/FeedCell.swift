//
//  FeedCell.swift
//  Foodi
//
//  Created by Jack Robinson on 2/1/24.
//

import SwiftUI
import AVKit
import Photos
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
                        
                        // MARK: LEFT (POST META-DATA) VSTACK
                        
                        VStack(alignment: .leading, spacing: 7) {
                            HStack{
                                // restaurant profile image
                                NavigationLink(value: post.restaurant) {
                                    RestaurantCircularProfileImageView(imageUrl: post.restaurant.profileImageUrl, size: .large)
                                }
                                //restaurant name
                                VStack (alignment: .leading) {
                                NavigationLink(value: post.restaurant) {
                                    Text("\(post.restaurant.name)")
                                        .font(.title3)
                                        .bold()
                                        .multilineTextAlignment(.leading)
                                }
                                //address
                                Text("📍 \(post.restaurant.city ?? ""), \(post.restaurant.state ?? "")")
                                
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
                            //caption
                            Text(post.caption)
                                .lineLimit(expandCaption ? 50 : 1)
                            
                            //see more
                            if !expandCaption{
                                Text("See more...")
                                    .font(.footnote)
                            }
                            else {
                                //cuisine
                                Text("Cuisine: \(post.restaurant.cuisine ?? "")")
                                
                                // price
                                Text("Price: \(post.restaurant.price ?? "")")
                                
                                //Menu Button
                                
                                NavigationLink(destination: RestaurantProfileView(restaurantId: post.restaurant.id, currentSection: .menu)) {
                                        Text("View Menu")
                                    }
                                    .modifier(StandardButtonModifier(width: 175))
                                
                            }
                        }
                        //controls box size
                        .padding(10)
                        .background(Color.black.opacity(0.3))
                        .onTapGesture { withAnimation(.snappy) { expandCaption.toggle() } }
                        .font(.subheadline)
                        .foregroundStyle(.white)
                        .padding()
                        
                        Spacer()
                        //MARK: Right hand Vstack
                        VStack(spacing: 28) {
                            //user profile image
                            NavigationLink(value: post.user) {
                                ZStack(alignment: .bottom) {
                                    UserCircularProfileImageView(profileImageUrl: post.user.profileImageUrl, size: .medium)
                                    Image(systemName: "plus.circle.fill")
                                        .foregroundStyle(.pink)
                                        .offset(y: 8)
                                }
                            }
                            //like button
                            Button {
                                handleLikeTapped()
                            } label: {
                                FeedCellActionButtonView(imageName: "heart.fill",
                                                         value: post.likes,
                                                         tintColor: didLike ? .red : .white)
                            }
                            //comment button
                            Button {
                                player.pause()
                                showComments.toggle()
                            } label: {
                                FeedCellActionButtonView(imageName: "ellipsis.bubble.fill", value: post.commentCount)
                            }
                            // Bookmark button
                            
                            //share button
                            Button {
                                requestPhotoLibraryAccess { granted in
                                    if granted {
                                        print("Access to photo library granted.")
                                        // Now you can proceed with saving the video to the photo library
                                    } else {
                                        print("Access to photo library denied or not determined.")
                                        // You might want to inform the user or handle the denial case appropriately
                                    }
                                }
                                
                            } label: {
                                FeedCellActionButtonView(imageName: "arrowshape.turn.up.right.fill",
                                                         value: post.shareCount)
                            }
                        }
                        .padding()
                    }
                    .padding(.bottom, viewModel.isContainedInTabBar ? 90 : 22)
                }
            }
            //MARK: CLICKING CONTROLS
            //overlays the comments if showcomments is true
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
    // like and unlike functionality
    private func handleLikeTapped() {
        Task { didLike ? await viewModel.unlike(post) : await viewModel.like(post) }
    }
}

private func downloadVideo(url: URL) {
    let task = URLSession.shared.downloadTask(with: url) { (tempLocalURL, response, error) in
        if let tempLocalURL = tempLocalURL, error == nil {
            let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let destinationURL = documentsDirectory.appendingPathComponent("downloadedVideo.mp4")
            
            do {
                try FileManager.default.moveItem(at: tempLocalURL, to: destinationURL)
                print("Video downloaded to: \(destinationURL)")
                
                // Save the video to the photo library
                PHPhotoLibrary.shared().performChanges({
                    PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: destinationURL)
                }) { (success, error) in
                    if success {
                        print("Video saved to photo library.")
                    } else {
                        print("Error saving video to photo library: \(error?.localizedDescription ?? "")")
                    }
                }
                
            } catch {
                print("Error moving file: \(error.localizedDescription)")
            }
        } else {
            print("Error downloading video: \(error?.localizedDescription ?? "")")
        }
    }
    
    task.resume()
}

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
        player: AVPlayer(),
             viewModel: FeedViewModel(
                postService: PostService()
             )
    )
}

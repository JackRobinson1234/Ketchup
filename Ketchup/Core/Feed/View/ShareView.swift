//
//  ShareView.swift
//  Foodi
//
//  Created by Jack Robinson on 3/1/24.
//

import SwiftUI
import Kingfisher
import Photos
struct ShareView: View {
    @StateObject var downloadViewModel: DownloadViewModel = .init()
    @State var isShowingMessageView: Bool = false
    @State var isShowingRestrictedAlert: Bool = false
    @State private var downloadedMediaData: Data?
    @State private var preppingMessage: Bool = false
    var post: Post
    var currentImageIndex: Int?
    
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 30) {
            VStack{
                if downloadViewModel.downloadSuccess{
                    Image(systemName: "checkmark")
                        .foregroundStyle(.green)
                        .font(.system(size: 30))
                    Text("Saved!")
                        .font(.subheadline)
                        .padding(.top,1)
                    
                } else if downloadViewModel.downloadFailure {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(Color("Colors/AccentColor"))
                        .font(.system(size: 50))
                    Text("Save Failed")
                        .font(.subheadline)
                        .padding(.top,1)
                } else {
                    Button(action: {
                        PHPhotoLibrary.requestAuthorization { status in
                                       if status == .authorized {
                                           // Photo access granted, proceed with downloading the video
                                           let mediaURL: String?
                                           if post.mediaType == "photo", let index = currentImageIndex, post.mediaUrls.indices.contains(index) {
                                               mediaURL = post.mediaUrls[index]
                                           } else {
                                               mediaURL = post.mediaUrls.first
                                           }
                                           
                                           if let mediaURL = mediaURL, let url = URL(string: mediaURL) {
                                                   if post.mediaType == "photo" {
                                                       downloadViewModel.downloadMedia(url: url, mediaType: .photo)
                                                   } else if post.mediaType == "video" {
                                                       downloadViewModel.downloadMedia(url: url, mediaType: .video)
                                                   }
                                           }
                                       } else {
                                           // Handle denied or restricted access
                                           isShowingRestrictedAlert = true
                                           print("Photo library access denied or restricted.")
                                       }
                                   }
                               })
               {
                            if downloadViewModel.isDownloading {
                                if downloadViewModel.progress == 0 {
                                    ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .blue))
                                        .frame(width: 40, height: 40)
                                }
                                else {
                                    ProgressView(value: downloadViewModel.progress)
                                        .frame(width: 40, height: 40)
                                }
                                
                            } else {
                                Image(systemName: "square.and.arrow.down")
                                    .font(.system(size: 40))
                                    .foregroundStyle(.blue)
                            }
                        }
                    Text("Save \(post.mediaType)")
                        .font(.subheadline)
                        .padding(.top,1)
                    
                }
            }
            VStack{
                
                Button(action: {
                    let mediaURL: String?
                    if post.mediaType == "photo", let index = currentImageIndex, post.mediaUrls.indices.contains(index) {
                        mediaURL = post.mediaUrls[index]
                    } else {
                        mediaURL = post.mediaUrls.first
                    }
                    
                    if let mediaURL = mediaURL, let url = URL(string: mediaURL) {
                        Task {
                            preppingMessage = true
                            await downloadMedia(url: url)
                            isShowingMessageView.toggle()
                        }
                    }
                }) {
                    if !preppingMessage{
                        Image(systemName: "message.fill")
                            .font(.title)
                            .foregroundStyle(.white)
                            .background(
                                Circle()
                                    .foregroundColor(.green)
                                    .frame(width: 50, height: 50)
                            )
                    } else {
                        ProgressView()
                    }
                }
                Text("Messages")
                    .font(.subheadline)
                    .padding(.top, 7)
                
            }
            VStack{
            //Debug: Needs to be transferable
                if let image = (URL(string: post.thumbnailUrl)) {
                    ShareLink(item: image, preview: SharePreview("Big Ben", image: image)) {
                        VStack{
                            Image(systemName: "ellipsis.circle")
                                .foregroundColor(.blue)
                                .font(.system(size: 40))
                            Text("More")
                                .font(.subheadline)
                                .padding(.top, 1)
                        }
                    }
                    
                }
            }
            
            Spacer()
        }
        .alert(isPresented: $isShowingRestrictedAlert) {
            Alert(
                title: Text("Access Restricted"),
                message: Text("Access to photo library is restricted. Please enable access in settings."),
                primaryButton: .default(Text("Open Settings"), action: {
                    guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else {
                        return
                    }
                    UIApplication.shared.open(settingsURL)
                }),
                secondaryButton: .cancel(Text("Cancel"))
            )
        }
        
        .sheet(isPresented: $isShowingMessageView) {
            if let mediaData = downloadedMediaData {
                if let restaurant = post.restaurant, let city = restaurant.city{
                    MessageComposeView(messageBody: "I'm absolutely frothing to try this restaurant called \(restaurant.name) in \(city) that I found on Ketchup!", mediaData: mediaData, mediaType: post.mediaType)
                        .onDisappear{preppingMessage = false}
                } else if let recipe = post.cookingTitle {
                    MessageComposeView(messageBody: "Dude. We need to make this \(recipe) recipe that I found on Ketchup!", mediaData: mediaData, mediaType: post.mediaType)
                        .onDisappear{preppingMessage = false}
                }
            } else {
                NavigationStack{
                    ProgressView()
                        .modifier(BackButtonModifier())
                }
            }
        }
        
        .padding()
                
    }
    private func downloadMedia(url: URL) async {
            Task {
                do {
                    let (data, _) = try await URLSession.shared.data(from: url)
                    downloadedMediaData = data
                    //isShowingMessageView = true // Show the message compose view after download
                } catch {
                    print("Error downloading Media:", error.localizedDescription)
                }
            }
        }
    
}

#Preview {
    ShareView(post: DeveloperPreview.posts[0])
}

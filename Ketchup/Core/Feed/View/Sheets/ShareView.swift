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
    var currentMediaIndex: Int
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 30) {
            VStack {
                if downloadViewModel.downloadSuccess {
                    Image(systemName: "checkmark")
                        .foregroundStyle(.green)
                        .font(.system(size: 30))
                    Text("Saved!")
                        .font(.custom("MuseoSansRounded-500", size: 16))
                        .padding(.top, 1)
                } else if downloadViewModel.downloadFailure {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(Color("Colors/AccentColor"))
                        .font(.system(size: 50))
                    Text("Save Failed")
                        .font(.custom("MuseoSansRounded-500", size: 16))
                        .padding(.top, 1)
                } else {
                    Button(action: {
                        downloadViewModel.downloadMedia(post: post, currentMediaIndex: currentMediaIndex)
                    }) {
                        if downloadViewModel.isDownloading {
                            if downloadViewModel.progress == 0 {
                                ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .blue))
                                    .frame(width: 40, height: 40)
                            } else {
                                ProgressView(value: downloadViewModel.progress)
                                    .frame(width: 40, height: 40)
                            }
                        } else {
                            Image(systemName: "square.and.arrow.down")
                                .font(.system(size: 30))
                                .foregroundStyle(.blue)
                        }
                    }
                    
                    Text("Save \(post.mediaType == .mixed ? post.mixedMediaUrls?[currentMediaIndex].type.text ?? "Media" : post.mediaType.text)")
                        .font(.custom("MuseoSansRounded-500", size: 16))
                        .padding(.top, 1)
                }
            }
            VStack{
                Button(action: {
                    let mediaURL: String?
                    if post.mediaType == .mixed {
                        mediaURL = post.mixedMediaUrls?[currentMediaIndex].url
                    } else {
                        mediaURL = post.mediaUrls[currentMediaIndex]
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
                            .font(.custom("MuseoSansRounded-300", size: 20))
                            .foregroundStyle(.white)
                            .background(
                                Circle()
                                    .foregroundColor(.green)
                                    .frame(width: 40, height: 40)
                            )
                    } else {
                        ProgressView()
                    }
                }
                Text("Messages")
                    .font(.custom("MuseoSansRounded-500", size: 16))
                    .padding(.top, 7)
                
            }
            VStack{
               
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
                if let city = post.restaurant.city {
                    let mediaType = post.mediaType == .mixed ? post.mixedMediaUrls?[currentMediaIndex].type : post.mediaType
                    MessageComposeView(messageBody: "I need to try this restaurant called \(post.restaurant.name) in \(city) that I found on Ketchup!", mediaData: mediaData, mediaType: mediaType ?? .photo)
                        .onDisappear { preppingMessage = false }
                }
            } else {
                NavigationStack {
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
                //print("Error downloading Media:", error.localizedDescription)
            }
        }
    }
}


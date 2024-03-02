//
//  ShareView.swift
//  Foodi
//
//  Created by Jack Robinson on 3/1/24.
//

import SwiftUI

struct ShareView: View {
    @StateObject var downloadViewModel: DownloadViewModel = .init()
    var post: Post
    
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
                        .foregroundColor(.red)
                        .font(.system(size: 50))
                    Text("Save Failed")
                        .font(.subheadline)
                        .padding(.top,1)
                } else {
                    Button(action: {
                        if let url = URL(string: post.videoUrl) {
                            downloadViewModel.downloadVideo(url: url)
                        }}) {
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
                    Text("Save Video")
                        .font(.subheadline)
                        .padding(.top,1)
                    
                }
            }
            VStack{
                
                Button(action: {
                    // Handle message action
                }) {
                    Image(systemName: "message.fill")
                        .font(.title)
                        .foregroundStyle(.white)
                        .background(
                            Circle()
                                .foregroundColor(.green)
                                .frame(width: 50, height: 50)
                        )
                }
                Text("Messages")
                    .font(.subheadline)
                    .padding(.top, 7)
                
            }
            VStack{
                Button(action: {
                    // Handle more actions
                }) {
                    Image(systemName: "ellipsis.circle")
                        .foregroundColor(.blue)
                        .font(.system(size: 40))
                }
                Text("More")
                    .font(.subheadline)
                    .padding(.top, 1)
                    
            }
            
            Spacer()
        }
                .padding()
                
    }
}

#Preview {
    ShareView(post: DeveloperPreview.posts[0])
}

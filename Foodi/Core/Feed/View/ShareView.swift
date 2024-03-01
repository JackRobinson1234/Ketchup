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
                Button(action: {
                    if let url = URL(string: post.videoUrl) {
                        downloadViewModel.downloadVideo(url: url)
                    }}) {
                    Image(systemName: "square.and.arrow.down")
                        .font(.system(size: 40))
                    
                }
                Text("Save Video")
                    .font(.subheadline)
                    .padding(.top,1)
                    
                
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
                        .foregroundColor(.green)
                        .font(.system(size: 50))
                }
                Text("More")
                    .font(.subheadline)
                    
            }
            
            Spacer()
        }
                .padding()
                .background(Color.white)
                .cornerRadius(10)
                .shadow(radius: 5)
    }
}

#Preview {
    ShareView(post: DeveloperPreview.posts[0])
}

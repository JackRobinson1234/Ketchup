//
//  RepostView.swift
//  Foodi
//
//  Created by Jack Robinson on 5/26/24.
//

import SwiftUI
import Kingfisher
struct RepostView: View {
    @ObservedObject var viewModel: FeedViewModel
    @Environment(\.dismiss) var dismiss
    @State var post: Post
    private let spacing: CGFloat = 8
    private var width: CGFloat {
            (UIScreen.main.bounds.width - (spacing * 2)) / 3
        }
    let cornerRadius: CGFloat = 5

    var body: some View {
        NavigationStack{
            VStack{
                KFImage(URL(string: post.thumbnailUrl))
                    .resizable()
                    .scaledToFill()
                    .frame(width: width, height: 160)
                    .cornerRadius(cornerRadius)
                    .clipped()
                    .overlay(
                        VStack{
                            HStack {
                                Spacer()
                                Image(systemName: "arrow.2.squarepath")
                                    .foregroundStyle(.white)
                                    .font(.custom("MuseoSansRounded-300", size: 16))
                            }
                            
                            Spacer()
                            HStack{
                                VStack (alignment: .leading) {
                                    
                                    Text("\(post.restaurant.name)")
                                            .lineLimit(2)
                                            .truncationMode(.tail)
                                            .foregroundColor(.white)
                                            .font(.custom("MuseoSansRounded-300", size: 10))
                                            .bold()
                                            .shadow(color: .black, radius: 2, x: 0, y: 1)
                                    
                                    
                                }
                            }
                        }
                            .padding(4)
                    )
                    .padding()
                Button{
                    handleRepostTapped()
                    viewModel.showRepostAlert = true
                    dismiss()
                } label: {
                    if post.didRepost == false {
                        HStack(spacing: 0) {
                            Image(systemName: "arrow.2.squarepath")
                                .foregroundStyle(.white)
                                .font(.custom("MuseoSansRounded-300", size: 10))
                            Text("Repost to my profile")
                                .modifier(StandardButtonModifier())
                        }
                    } else {
                        HStack(spacing: 0) {
                            Image(systemName: "x.circle")
                                .foregroundStyle(.white)
                                .font(.custom("MuseoSansRounded-300", size: 10))
                            Text("Remove repost from my profile")
                                .modifier(StandardButtonModifier())
                        }
                    }
                }
            }
            .onAppear{
               Task{ post.didRepost = try await PostService.shared.checkIfUserReposted(post)
                }
            }
            .modifier(BackButtonModifier())
        }
        
    }
    private func handleRepostTapped() {
        Task {
            post.didRepost ? await viewModel.removeRepost(post) : await viewModel.repost(post)
        }
    }
}



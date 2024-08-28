//
//  PostGridView.swift
//  Foodi
//
//  Created by Jack Robinson on 2/1/24.
//

import SwiftUI
import Kingfisher
import AVKit
struct PostGridView: View {
    @ObservedObject var feedViewModel: FeedViewModel
    @State private var selectedPost: Post?
    @Environment(\.dismiss) var dismiss
    private let feedTitleText: String?
    private let showNames: Bool
    private let spacing: CGFloat = 8
    private var width: CGFloat {
        (UIScreen.main.bounds.width - (spacing * 2)) / 3
    }
    let cornerRadius: CGFloat = 5
    private var items: [GridItem] {
        [
            GridItem(.flexible(), spacing: 2),
            GridItem(.flexible(), spacing: 2),
            GridItem(.flexible(), spacing: 2),
        ]
    }
    @State var selectedWrittenPost: Post?
    @Binding var scrollPosition: String?
    @Binding var scrollTarget: String?
    init(feedViewModel: FeedViewModel, feedTitleText: String?, showNames: Bool, scrollPosition: Binding<String?>, scrollTarget: Binding<String?>) {
        self.feedViewModel = feedViewModel
        self.feedTitleText = feedTitleText
        self.showNames = showNames
        self._scrollPosition = scrollPosition
        self._scrollTarget = scrollTarget
    }
    var body: some View {
        if !feedViewModel.posts.isEmpty {
            LazyVGrid(columns: items, spacing: spacing / 2) {
                ForEach(feedViewModel.posts) { post in
                    Button {
                        feedViewModel.startingPostId = post.id
                        if post.mediaType == .written || ((post.mixedMediaUrls?.isEmpty ?? true) && post.mediaUrls.isEmpty) {
                            selectedWrittenPost = post
                        } else {
                            selectedPost = post
                        }
                    } label: {
                        ZStack {
                            if post.mediaType != .written, !post.thumbnailUrl.isEmpty {
                                KFImage(URL(string: post.thumbnailUrl))
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: width, height: 160)
                                    .cornerRadius(cornerRadius)
                                    .clipped()
                                    .overlay(
                                        VStack(alignment: .leading) {
                                            HStack {
                                                Spacer()
                                                if post.repost {
                                                    Image(systemName: "arrow.2.squarepath")
                                                        .foregroundStyle(.white)
                                                        .font(.custom("MuseoSansRounded-300", size: 16))
                                                }
                                            }
                                            Spacer()
                                        }
                                    )
                            } else {
                                VStack {
                                    if let profileImageUrl = post.restaurant.profileImageUrl {
                                        RestaurantCircularProfileImageView(imageUrl: profileImageUrl, size: .large)
                                        
                                    }
                                    if !post.caption.isEmpty {
                                        Image(systemName: "line.3.horizontal")
                                            .resizable()
                                            .foregroundStyle(.gray)
                                            .aspectRatio(contentMode: .fit)
                                            .frame(width: 45, height: 15)
                                    }
                                }
                                .frame(width: width, height: 160)
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(cornerRadius)
                                .clipped()
                            }
                            
                            VStack(alignment: .leading) {
                                Spacer()
                                HStack {
                                    if showNames {
                                        Text("\(post.restaurant.name)")
                                            .lineLimit(2)
                                            .truncationMode(.tail)
                                            .foregroundColor(.white)
                                            .font(.custom("MuseoSansRounded-300", size: 10))
                                            .bold()
                                            .shadow(color: .black, radius: 2, x: 0, y: 1)
                                            .multilineTextAlignment(.leading)
                                    }
                                    Spacer()
                                }
                            }
                            .padding(4)
                        }
                    }
                }
            }
            .padding(spacing / 2)
            .fullScreenCover(item: $selectedPost) { post in
                if post.mediaType != .written {
                    NavigationStack {
                        SecondaryFeedView(viewModel: feedViewModel, hideFeedOptions: true, initialScrollPosition: post.id, titleText: feedTitleText ?? "Posts", checkLikes: true)
                    }
                    .presentationDetents([.height(UIScreen.main.bounds.height * 0.5)])
                }
            }
            .sheet(item: $selectedWrittenPost) { post in
                NavigationStack {
                    ScrollView {
                        WrittenFeedCell(viewModel: feedViewModel, post: .constant(post), scrollPosition: .constant(nil), pauseVideo: .constant(false), selectedPost: .constant(nil), checkLikes: true)
                    }
                    .modifier(BackButtonModifier())
                    .navigationDestination(for: PostRestaurant.self) { restaurant in
                        RestaurantProfileView(restaurantId: restaurant.id)
                    }
                }
                .presentationDetents([.height(UIScreen.main.bounds.height * 0.5)])
            }
        } else {
            HStack {
                Spacer()
                Text("No Posts to Show")
                    .foregroundStyle(.gray)
                    .font(.custom("MuseoSansRounded-300", size: 16))
                Spacer()
            }
            .padding()
        }
    }
    
    private func calculateAverageRating(for post: Post) -> Double? {
        var totalSum = 0.0
        var totalCount = 0
        
        if let foodRating = post.foodRating {
            totalSum += foodRating
            totalCount += 1
        }
        if let atmosphereRating = post.atmosphereRating {
            totalSum += atmosphereRating
            totalCount += 1
        }
        if let valueRating = post.valueRating {
            totalSum += valueRating
            totalCount += 1
        }
        if let serviceRating = post.serviceRating {
            totalSum += serviceRating
            totalCount += 1
        }
        
        if totalCount > 0 {
            return (totalSum / Double(totalCount)).rounded(to: 1)
        } else {
            return nil
        }
    }
}

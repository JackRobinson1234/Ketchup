//
//  WrittenFeedCell.swift
//  Ketchup
//
//  Created by Jack Robinson on 6/25/24.
//

import SwiftUI
import Kingfisher
struct WrittenFeedCell: View {
    @ObservedObject var viewModel: FeedViewModel
    @Binding var post: Post
    @State private var showComments = false
    @State private var showShareView = false
    @State private var showCollections = false
    @State private var expandCaption = false
    @State private var showingOptionsSheet = false
    @State private var showingRepostSheet = false
    @State private var currentImageIndex = 0
    @Binding var scrollPosition: String?
    private var didLike: Bool { return post.didLike }
    private let pictureWidth: CGFloat = 240
    private let pictureHeight: CGFloat = 300
    
    var body: some View {
        
            VStack{
                
                HStack{
                    NavigationLink(value: post.user) {
                        UserCircularProfileImageView(profileImageUrl: post.user.profileImageUrl, size: .medium)
                    }
                    NavigationLink(value: post.user) {
                        VStack(alignment: .leading){
                            Text("@\(post.user.username)")
                                .font(.custom("MuseoSansRounded-300", size: 14))
                                .foregroundStyle(.primary)
                                .multilineTextAlignment(.leading)
                            Text("\(post.user.fullname)")
                                .font(.custom("MuseoSansRounded-300", size: 16))
                                .fontWeight(.semibold)
                                .foregroundStyle(.primary)
                                .bold()
                                .multilineTextAlignment(.leading)
                        }
                    }
                    Spacer()
                    if let timestamp = post.timestamp{
                        Text(getTimeElapsedString(from: timestamp))
                            .font(.custom("MuseoSansRounded-300", size: 12))
                            .foregroundColor(.gray)
                    }
                }
                if post.mediaType == .photo{
                    ScrollView(.horizontal, showsIndicators: false){
                        LazyHStack{
                            ForEach(Array(post.mediaUrls.enumerated()), id: \.element) { index, url in
                                VStack {
                                    Button {
                                        viewModel.startingImageIndex = index
                                        viewModel.scrollPosition = post.id
                                        viewModel.startingPostId = post.id
                                        viewModel.feedViewOption = .feed
                                    } label: {
                                        KFImage(URL(string: url))
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(width: pictureWidth, height: pictureHeight)
                                            .clipped()
                                            .cornerRadius(10)
                                    }
                                }
                                .scrollTransition(.animated, axis: .horizontal) { content, phase in
                                    content
                                        .opacity(phase.isIdentity ? 1.0 : 0.8)
                                }
                            }
                            
                        }
                        .frame(height: pictureHeight)
                        .scrollTargetLayout()
                        
                    }
                    
                    .scrollTargetBehavior(.viewAligned)
                    .safeAreaPadding(.horizontal, ((UIScreen.main.bounds.width - pictureWidth) / 2))
                }
                HStack{
                    VStack(alignment: .leading){
                        Text(post.restaurant.name)
                            .font(.custom("MuseoSansRounded-300", size: 16))
                            .bold()
                        Text("\(post.restaurant.city ?? ""), \(post.restaurant.state ?? "")")
                            .font(.custom("MuseoSansRounded-300", size: 14))
                    }
                    Spacer()
                }
                ScrollView(.horizontal, showsIndicators: false){
                    HStack (spacing: 6){
                        RatingView(rating: post.overallRating, label: "Overall")
                        Divider().frame(height: 20)
                        RatingView(rating: post.foodRating, label: "Food")
                        Divider().frame(height: 20)
                        RatingView(rating: post.atmosphereRating, label: "Atmosphere")
                        Divider().frame(height: 20)
                        RatingView(rating: post.valueRating, label: "Value")
                        Divider().frame(height: 20)
                        RatingView(rating: post.serviceRating, label: "Service")
                        
                    }
                }
                HStack {
                    Text(post.caption)
                        .font(.custom("MuseoSansRounded-300", size: 16))
                        //.lineLimit(expandCaption ? 50 : 1)
                    Spacer()
                    
                }
                //MARK: Buttons
                HStack{
                    
                    Button {
                        //videoCoordinator.pause()
                        showComments.toggle()
                    } label: {
                        InteractionButtonView(icon: "ellipsis.bubble", count: post.commentCount)
                    }
                    
                    Button {
                        handleLikeTapped()
                    } label: {
                        InteractionButtonView(icon: didLike ? "heart.fill": "heart", count: post.likes, color: didLike ? Color("Colors/AccentColor"): .gray)
                    }
                    
                    Button {
                        showingRepostSheet.toggle()
                    } label: {
                        HStack(spacing: 3){
                            Image(systemName: "arrow.2.squarepath")
                                .resizable()
                                .scaledToFill()
                                .frame(width: 18, height: 18)
                                .foregroundStyle(.gray)
                                .rotationEffect(.degrees(90))
                            Text("\(post.repostCount)")
                                .font(.custom("MuseoSansRounded-300", size: 14))
                                .foregroundStyle(.gray)
                        }
                        .padding(.trailing, 10)
                        
                    }
                    
                    Button {
                        //videoCoordinator.pause()
                        showCollections.toggle()
                    } label: {
                        InteractionButtonView(icon: "folder.badge.plus")
                    }
                    
                    Button {
                        // videoCoordinator.pause()
                        showShareView.toggle()
                    } label: {
                        InteractionButtonView(icon: "arrowshape.turn.up.right")
                        
                    }
                    
                    Button {
                        //videoCoordinator.pause()
                        showingOptionsSheet = true
                    } label: {
                        ZStack{
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
                    Spacer()
                }
                Divider()
            }
            .padding()
            
        
        .sheet(isPresented: $showComments) {
            CommentsView(post: $post)
                .presentationDetents([.height(UIScreen.main.bounds.height * 0.65)])
            //.onDisappear{Task{ videoCoordinator.play()}}
        }
        .sheet(isPresented: $showShareView) {
            ShareView(post: post, currentImageIndex: currentImageIndex)
                .presentationDetents([.height(UIScreen.main.bounds.height * 0.15)])
            //onDisappear{Task {videoCoordinator.play()}}
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
    }
    private func handleLikeTapped() {
        Task { didLike ? await viewModel.unlike(post) : await viewModel.like(post) }
    }
}

struct RatingView: View {
    var rating: Rating
    var label: String
    
    var body: some View {
        HStack(spacing: 2){
            rating.image
                .resizable()
                .frame(width: 20, height: 20)
            // Adjusted for better visibility
            
            Text(label)
                .font(.custom("MuseoSansRounded-300", size: 14))
                .foregroundColor(.primary)
            
        }
    }
}

struct InteractionButtonView: View {
    var icon: String
    var count: Int?
    var color: Color = .gray
    
    var body: some View {
        HStack (spacing: 3){
            Image(systemName: icon)
                .resizable()
                .scaledToFill()
                .frame(width: 18, height: 18)
                .foregroundColor(color)
            if let count{
                Text("\(count)")
                    .font(.custom("MuseoSansRounded-300", size: 14))
                    .foregroundColor(.gray)
            }
        }
        .padding(.trailing, 10)
    }
}

#Preview {
    WrittenFeedCell(viewModel: FeedViewModel(), post: .constant(DeveloperPreview.posts[0]),  scrollPosition: .constant(""))
}

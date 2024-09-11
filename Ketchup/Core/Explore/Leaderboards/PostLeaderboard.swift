//
//  PostLeaderboard.swift
//  Ketchup
//
//  Created by Jack Robinson on 9/7/24.
//

import SwiftUI
import Kingfisher

struct PostLeaderboard: View {
    @ObservedObject var viewModel: LeaderboardViewModel
    @State private var selectedPost: Post?
    @State private var selectedWrittenPost: Post?
    @StateObject var feedViewModel = FeedViewModel()
    
    private let spacing: CGFloat = 8
    private var width: CGFloat {
        (UIScreen.main.bounds.width - (spacing * 2)) / 3
    }
    let cornerRadius: CGFloat = 5
    
    var topImage: String? = nil
    var title: String
    @Environment(\.dismiss) var dismiss
    @State private var canSwitchTab = true
    @State var state: String? = nil
    @State var city: String? = nil
    @State var surrounding: String? = nil
    var body: some View {
        NavigationStack {
            VStack {
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(alignment: .leading, spacing: 4) {
                        headerView
                        timePeriodSelector
                        dateRangeView
                        if viewModel.isLoading && viewModel.posts.isEmpty {
                            FastCrossfadeFoodImageView()
                        } else {
                            postsListView
                        }
                    }
                }
                .refreshable {
                    await refreshPosts()
                }
            }
            .edgesIgnoringSafeArea(.top)
            .onAppear {
                Task {
                    await refreshPosts()
                }
            }
        }
        .fullScreenCover(item: $selectedPost) { post in
            postDetailView(for: post)
        }
        .sheet(item: $selectedWrittenPost) { post in
            writtenPostView(for: post)
        }
    }
    
    private var headerView: some View {
        ZStack(alignment: .bottomLeading) {
            if let imageURL = topImage {
                ListingImageCarouselView(images: [imageURL])
                    .overlay(
                        LinearGradient(
                            gradient: Gradient(stops: [
                                .init(color: Color.clear, location: 0.4),
                                .init(color: Color.black.opacity(0.7), location: 0.8),
                                .init(color: Color.black.opacity(0.9), location: 1.0)
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }
            
            VStack {
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .foregroundStyle(.white)
                            .background(
                                Circle()
                                    .fill(Color.gray)
                                    .frame(width: 30, height: 30)
                            )
                    }
                    Spacer()
                }
                .padding(40)
                .padding(.top, 15)
                Spacer()
            }
            
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Top Posts: \(title)")
                        .font(.custom("MuseoSansRounded-300", size: 20))
                        .fontWeight(.semibold)
                        .multilineTextAlignment(.leading)
                        .foregroundStyle(.white)
                }
                .padding([.horizontal, .bottom])
                
                Spacer()
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    private var timePeriodSelector: some View {
        HStack(spacing: 10) {
            Spacer()
            Button {
                if canSwitchTab {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        viewModel.timePeriod = .month
                    }
                    canSwitchTab = false
                    Task {
                        await refreshPosts()
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        canSwitchTab = true
                    }
                }
            } label: {
                Text("Month")
                    .font(.custom("MuseoSansRounded-500", size: 18))
                    .foregroundColor(viewModel.timePeriod == .month ? Color("Colors/AccentColor") : .gray)
                    .padding(.bottom, 5)
                    .overlay(
                        Rectangle()
                            .frame(height: 2)
                            .foregroundColor(viewModel.timePeriod == .month ? Color("Colors/AccentColor") : .clear)
                            .offset(y: 12)
                    )
            }
            .disabled(viewModel.timePeriod == .month || !canSwitchTab)
            
            Button {
                if canSwitchTab {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        viewModel.timePeriod = .week
                    }
                    canSwitchTab = false
                    Task {
                        await refreshPosts()
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        canSwitchTab = true
                    }
                }
            } label: {
                Text("Week")
                    .font(.custom("MuseoSansRounded-500", size: 18))
                    .foregroundColor(viewModel.timePeriod == .week ? Color("Colors/AccentColor") : .gray)
                    .padding(.bottom, 5)
                    .overlay(
                        Rectangle()
                            .frame(height: 2)
                            .foregroundColor(viewModel.timePeriod == .week ? Color("Colors/AccentColor") : .clear)
                            .offset(y: 12)
                    )
            }
            .disabled(viewModel.timePeriod == .week || !canSwitchTab)
            Spacer()
        }
        .padding(.vertical)
    }
    
    private var dateRangeView: some View {
        HStack {
            Spacer()
            if viewModel.timePeriod == .week {
                Text(getDateRangeForCurrentWeek())
                    .font(.custom("MuseoSansRounded-500", size: 14))
                    .foregroundStyle(.black)
            } else {
                Text(getCurrentMonth())
                    .font(.custom("MuseoSansRounded-500", size: 14))
                    .foregroundStyle(.black)
            }
            Spacer()
        }
    }
    
    private var postsListView: some View {
        ForEach(Array(viewModel.posts.enumerated()), id: \.element.id) { index, post in
            postCell(for: post, index: index)
                .onAppear {
                    if post == viewModel.posts.last {
                        Task {
                            try? await viewModel.fetchMorePosts(state: state, city: city, geohash: surrounding)
                        }
                    }
                }
        }
    }
    
    private func postCell(for post: Post, index: Int) -> some View {
        Button {
            feedViewModel.posts = viewModel.posts
            feedViewModel.startingPostId = post.id
            if post.mediaType == .written || ((post.mixedMediaUrls?.isEmpty ?? true) && post.mediaUrls.isEmpty) {
                selectedWrittenPost = post
            } else {
                selectedPost = post
            }
        } label: {
            HStack(spacing: 8) {
                Text("\(index + 1).")
                    .font(.custom("MuseoSansRounded-700", size: 16))
                    .foregroundColor(.black)
                    .bold()
                    .frame(width: 30)
                
                HStack(spacing: 8) {
                    ZStack {
                        if post.mediaType != .written, !post.thumbnailUrl.isEmpty {
                            KFImage(URL(string: post.thumbnailUrl))
                                .resizable()
                                .scaledToFill()
                                .frame(width: 80, height: 80)
                                .cornerRadius(cornerRadius)
                                .clipped()
                        } else {
                            VStack {
                                if let profileImageUrl = post.restaurant.profileImageUrl {
                                    RestaurantCircularProfileImageView(imageUrl: profileImageUrl, size: .medium)
                                }
                                if !post.caption.isEmpty {
                                    Image(systemName: "line.3.horizontal")
                                        .resizable()
                                        .foregroundStyle(.gray)
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 45, height: 15)
                                }
                            }
                            .frame(width: 80, height: 80)
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(cornerRadius)
                            .clipped()
                        }
                    }
                    
                    VStack(alignment: .leading) {
                        Text(post.restaurant.name)
                            .lineLimit(1)
                            .truncationMode(.tail)
                            .font(.custom("MuseoSansRounded-700", size: 14))
                            .foregroundColor(.black)
                        Text("\(post.restaurant.city ?? ""), \(post.restaurant.state ?? "")")
                            .lineLimit(1)
                            .truncationMode(.tail)
                            .font(.custom("MuseoSansRounded-300", size: 12))
                            .foregroundColor(.gray)
                        Text("by @\(post.user.username)")
                            .lineLimit(1)
                            .truncationMode(.tail)
                            .font(.custom("MuseoSansRounded-300", size: 12))
                            .foregroundColor(.gray)
                        
                        Text("Rating: \(calculateOverallRating(for: post))")
                            .font(.custom("MuseoSansRounded-300", size: 12))
                            .foregroundColor(.gray)
                        
                        HStack(spacing: 1) {
                            Image(systemName: "heart")
                                .font(.footnote)
                                .foregroundColor(.gray)
                            Text("\(post.likes)")
                                .font(.custom("MuseoSansRounded-300", size: 12))
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }
        }
    }
    
    private func postDetailView(for post: Post) -> some View {
        NavigationStack {
            SecondaryFeedView(viewModel: feedViewModel, hideFeedOptions: true, initialScrollPosition: post.id, titleText: "Trending Posts", checkLikes: true)
        }
        .presentationDetents([.height(UIScreen.main.bounds.height * 0.5)])
    }
    
    private func writtenPostView(for post: Post) -> some View {
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
    
    private func refreshPosts() async {
        viewModel.resetPagination()
        try? await viewModel.fetchMorePosts(state: state, city: city, geohash: surrounding)
    }
    
    private func calculateOverallRating(for post: Post) -> String {
        var ratings: [Double] = []
        if let foodRating = post.foodRating, foodRating != 0 { ratings.append(foodRating) }
        if let atmosphereRating = post.atmosphereRating, atmosphereRating != 0 { ratings.append(atmosphereRating) }
        if let valueRating = post.valueRating, valueRating != 0 { ratings.append(valueRating) }
        if let serviceRating = post.serviceRating, serviceRating != 0 { ratings.append(serviceRating) }
        
        if ratings.isEmpty {
            return "N/A"
        } else {
            let average = ratings.reduce(0, +) / Double(ratings.count)
            return String(format: "%.1f", average)
        }
    }
    
    private func getCurrentMonth() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM yyyy"
        return dateFormatter.string(from: Date())
    }
    
    private func getDateRangeForCurrentWeek() -> String {
        let calendar = Calendar.current
        let today = Date()
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today))!
        let endOfWeek = calendar.date(byAdding: .day, value: 6, to: startOfWeek)!
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM/dd"
        let startString = dateFormatter.string(from: startOfWeek)
        let endString = dateFormatter.string(from: endOfWeek)
        return "\(startString)-\(endString)"
    }
}

//
//  ProfileMapView.swift
//  Ketchup
//
//  Created by Jack Robinson on 7/2/24.
//

import SwiftUI
import _MapKit_SwiftUI
import Kingfisher

struct ProfileMapView: View {
    var posts: [Post]
    @StateObject var feedViewModel = FeedViewModel()
    @State var selectedPost: Post?
    @State var selectedWrittenPost: Post?
    @State var selectedLocation: LocationWithPosts?
    @Environment(\.dismiss) var dismiss
    var groupedPosts: [CLLocationCoordinate2D: [Post]] {
        Dictionary(grouping: posts) { post in
            post.restaurant.geoPoint.map { CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude) } ?? CLLocationCoordinate2D()
        }
    }
    
    var body: some View {
        if !posts.isEmpty {
            Map(initialPosition: .automatic) {
                ForEach(Array(groupedPosts.keys), id: \.self) { coordinate in
                    let postsAtLocation = groupedPosts[coordinate] ?? []
                    Annotation(postsAtLocation.first?.restaurant.name ?? "", coordinate: coordinate) {
                        Button {
                            if postsAtLocation.count > 1 {
                                feedViewModel.posts = postsAtLocation
                                selectedLocation = LocationWithPosts(coordinate: coordinate, posts: postsAtLocation)
                                
                            } else if let singlePost = postsAtLocation.first {
                                if singlePost.mediaType == .written {
                                    selectedWrittenPost = singlePost
                                } else {
                                    feedViewModel.posts = [singlePost]
                                    selectedPost = singlePost
                                }
                            }
                        } label: {
                            if postsAtLocation.count > 1 {
                                MultiPostAnnotationView(count: postsAtLocation.count)
                            } else if let singlePost = postsAtLocation.first {
                                SinglePostAnnotationView(post: singlePost)
                            }
                        }
                    }
                }
            }
            .mapStyle(.standard(pointsOfInterest: .excludingAll))
            .frame(height: UIScreen.main.bounds.height * 0.7)
            .cornerRadius(10)
            .sheet(item: $selectedLocation) { locationWithPosts in
                NavigationStack{
                    ScrollView{
                        ProfileFeedView(viewModel: feedViewModel, scrollPosition: .constant(nil), scrollTarget: .constant(nil))
                    }
                    .modifier(BackButtonModifier())
                }
            }
            .fullScreenCover(item: $selectedPost) { post in
                NavigationStack {
                    SecondaryFeedView(viewModel: feedViewModel, hideFeedOptions: true, titleText: "Posts")
                }
            }
            .sheet(item: $selectedWrittenPost) { post in
                NavigationStack {
                    ScrollView {
                        WrittenFeedCell(viewModel: feedViewModel, post: .constant(post), scrollPosition: .constant(nil), pauseVideo: .constant(false), selectedPost: .constant(nil))
                    }
                    .modifier(BackButtonModifier())
                    .navigationDestination(for: PostRestaurant.self) { restaurant in
                        RestaurantProfileView(restaurantId: restaurant.id)
                    }
                }
            }
        }
    }
}
struct MultiPostAnnotationView: View {
    let count: Int
    
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.white)
                .frame(width: 40, height: 40)
                .shadow(radius: 2)
            
            Text("\(count)")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.black)
        }
    }
}

struct SinglePostAnnotationView: View {
    let post: Post
    
    var body: some View {
        if post.mediaType == .written {
            ZStack {
                Rectangle()
                    .foregroundStyle(.white)
                    .frame(width: 38, height: 38)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                Image(systemName: "line.3.horizontal")
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(Color("Colors/AccentColor"))
                    .frame(width: 20, height: 20)
            }
        } else {
            PostAnnotationView(post: post)
        }
    }
}


struct PostListItem: View {
    let post: Post
    
    var body: some View {
        HStack {
            if let url = URL(string: post.thumbnailUrl) {
                KFImage(url)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 50, height: 50)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            } else {
                Image(systemName: post.mediaType == .written ? "doc.text" : "photo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 50, height: 50)
                    .foregroundColor(.gray)
            }
            
            VStack(alignment: .leading) {
                Text(post.restaurant.name)
                    .font(.headline)
                Text(post.caption)
                    .font(.subheadline)
                    .lineLimit(1)
            }
        }
    }
}
struct LocationWithPosts: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
    let posts: [Post]
}
struct PostAnnotationView: View {
    let post: Post
    
    var body: some View {
        VStack(spacing: 0) {
            ZStack() {
                // Square background with point
                Rectangle()
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                
                // Thumbnail image
                if let url = URL(string: post.thumbnailUrl) {
                    KFImage(url)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 40, height: 40)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        
                } else {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 44, height: 44)
                }
            }
            
        }
    }
}

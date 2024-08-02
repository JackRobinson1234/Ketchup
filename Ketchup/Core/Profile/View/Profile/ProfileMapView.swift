//
//  ProfileMapView.swift
//  Ketchup
//
//  Created by Jack Robinson on 7/2/24.
//

import SwiftUI
import _MapKit_SwiftUI
import Kingfisher
import ClusterMap
import ClusterMapSwiftUI
struct ProfileMapView: View {
    @StateObject var viewModel = ProfileMapViewModel()
    @ObservedObject var feedViewModel: FeedViewModel
    @State var selectedPost: Post?
    @State var selectedWrittenPost: Post?
    @State var selectedLocation: LocationWithPosts?
    @Environment(\.dismiss) var dismiss
    @StateObject var newFeedViewModel = FeedViewModel()
    @State var selectedCluster: PostClusterAnnotation?
    
    // Filter posts to exclude those with restaurant IDs starting with "construction"
    var filteredPosts: [Post] {
        feedViewModel.posts.filter { !$0.restaurant.id.starts(with: "construction") }
    }
    
    var groupedPosts: [CLLocationCoordinate2D: [Post]] {
        Dictionary(grouping: filteredPosts) { post in
            post.restaurant.geoPoint.map { CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude) } ?? CLLocationCoordinate2D()
        }
    }
    
    var body: some View {
        if !filteredPosts.isEmpty {
            Map(initialPosition: .automatic) {
                ForEach(viewModel.annotations, id: \.self) { item in
                                        Annotation(item.post.restaurant.name, coordinate: item.coordinate) {
                                            Button {
                                                print("DEBUG: Single post annotation tapped")
                                                selectedWrittenPost = item.post
                                            } label: {
                                                SinglePostAnnotationView(post: item.post)
                                            }
                                        }
                }
                ForEach(viewModel.clusters) { cluster in
                    Annotation("", coordinate: cluster.coordinate) {
                        PostClusterCell(cluster: cluster)
                            .onTapGesture {
                                newFeedViewModel.posts = cluster.memberAnnotations.map { $0.post}
                                print("DEBUG: Cluster tapped - \(cluster.count) posts")
                                selectedCluster = cluster
                            }
                    }
                }
            }
            
            .readSize(onChange: { newValue in
                viewModel.mapSize = newValue
            })
            .onAppear{
                viewModel.setPosts(posts: filteredPosts)
            }
            .onMapCameraChange { context in
                viewModel.currentRegion = context.region
            }
            .onMapCameraChange(frequency: .onEnd) { context in
                Task.detached { await viewModel.reloadAnnotations() }
            }
            .mapStyle(.standard(pointsOfInterest: .excludingAll))
            .frame(height: UIScreen.main.bounds.height * 0.5)
            .cornerRadius(10)
            .sheet(item: $selectedCluster) { locationWithPosts in
                NavigationStack{
                    ScrollView{
                        ProfileFeedView(viewModel: newFeedViewModel, scrollPosition: .constant(nil), scrollTarget: .constant(nil))
                    }
                    .modifier(BackButtonModifier())
                    
                }
                .onDisappear {
                    updateOriginalFeedViewModel()
                }
            }
           
            .fullScreenCover(item: $selectedPost) { post in
                NavigationStack {
                    SecondaryFeedView(viewModel: newFeedViewModel, hideFeedOptions: true, titleText: "Posts")
                }
                .onDisappear {
                    updateOriginalFeedViewModel()
                }
            }
            .sheet(item: $selectedWrittenPost) { post in
                NavigationStack {
                    ScrollView {
                        WrittenFeedCell(viewModel: newFeedViewModel, post: .constant(post), scrollPosition: .constant(nil), pauseVideo: .constant(false), selectedPost: .constant(nil), checkLikes: true)
                    }
                    .modifier(BackButtonModifier())
                    .navigationDestination(for: PostRestaurant.self) { restaurant in
                        RestaurantProfileView(restaurantId: restaurant.id)
                    }
                    
                }
                .onDisappear {
                    updateOriginalFeedViewModel()
                }
            }
        } else {
            HStack{
                Spacer()
                Text("No Posts to Show")
                    .foregroundStyle(.gray)
                    .font(.custom("MuseoSansRounded-300", size: 16))
                Spacer()
            }
        }
    }
    private func updateOriginalFeedViewModel() {
        for (index, post) in feedViewModel.posts.enumerated() {
            if let updatedPost = newFeedViewModel.posts.first(where: { $0.id == post.id }) {
                feedViewModel.posts[index] = updatedPost
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

class ProfileMapViewModel: ObservableObject {
    let clusterManager = ClusterManager<PostMapAnnotation>()
    @Published var posts = [Post]()
    var annotations: [PostMapAnnotation] = []
    var clusters: [PostClusterAnnotation] = []
    var mapSize: CGSize = .zero
    @Published var currentRegion: MKCoordinateRegion = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 34.0549, longitude: -118.2426), span: MKCoordinateSpan(latitudeDelta: 0.03, longitudeDelta: 0.03))
    func setPosts(posts: [Post]) {
        self.posts = posts
        let postAnnotations: [PostMapAnnotation] = self.posts.compactMap {post in
            if let coordinates = post.coordinates {
                return PostMapAnnotation(coordinate: coordinates, post: post)
            } else {
                return nil
            }
        }

        Task{
            await clusterManager.add(postAnnotations)
            await reloadAnnotations()
        }

    }
    func reloadAnnotations() async {
        async let changes = clusterManager.reload(mapViewSize: mapSize, coordinateRegion: currentRegion)
        await applyChanges(changes)
    }
    @MainActor
    private func applyChanges(_ difference: ClusterManager<PostMapAnnotation>.Difference) {
        for removal in difference.removals {
            switch removal {
            case .annotation(let annotation):
                annotations.removeAll { $0 == annotation }
            case .cluster(let clusterAnnotation):
                clusters.removeAll { $0.id == clusterAnnotation.id }
            }
        }
        for insertion in difference.insertions {
            switch insertion {
            case .annotation(let newItem):
                annotations.append(newItem)
            case .cluster(let newItem):
                clusters.append(PostClusterAnnotation(
                    id: newItem.id,
                    coordinate: newItem.coordinate,
                    count: newItem.memberAnnotations.count,
                    memberAnnotations: newItem.memberAnnotations
                ))
            }
        }
        print(annotations.count)
        print(clusters.count)
    }
}
struct PostMapAnnotation: CoordinateIdentifiable, Identifiable, Hashable, Equatable {
    let id = UUID()
    var coordinate: CLLocationCoordinate2D
    var post: Post
}
struct PostClusterAnnotation: Identifiable {
    var id = UUID()
    var coordinate: CLLocationCoordinate2D
    var count: Int
    var memberAnnotations: [PostMapAnnotation]
}
//struct ProfileMapView: View {
//    @StateObject var viewModel = ProfileMapViewModel()
//    @ObservedObject var feedViewModel: FeedViewModel
//    @State var selectedPost: Post?
//    @State var selectedWrittenPost: Post?
//    @State var selectedLocation: LocationWithPosts?
//    @Environment(\.dismiss) var dismiss
//    @StateObject var newFeedViewModel = FeedViewModel()
//    @State private var selectedCluster: PostClusterAnnotation?
//    
//    // Filter posts to exclude those with restaurant IDs starting with "construction"
//    var filteredPosts: [Post] {
//        feedViewModel.posts.filter { !$0.restaurant.id.starts(with: "construction") }
//    }
//    
//    //    var groupedPosts: [CLLocationCoordinate2D: [Post]] {
//    //        Dictionary(grouping: filteredPosts) { post in
//    //            post.restaurant.geoPoint.map { CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude) } ?? CLLocationCoordinate2D()
//    //        }
//    //    }
//    
//    var body: some View {
//        if !filteredPosts.isEmpty {
//            GeometryReader(content: { geometryProxy in
//                Map(initialPosition: .automatic) {
//                    ForEach(viewModel.annotations, id: \.self) { item in
//                        Annotation(item.post.restaurant.name, coordinate: item.coordinate) {
//                            Button{
//                                selectedWrittenPost = item.post
//                            } label: {
//                                SinglePostAnnotationView(post: item.post)
//                            }
//                        }
//                        ForEach(viewModel.clusters) { cluster in
//                            Annotation("", coordinate: cluster.coordinate){
//                                PostClusterCell(cluster: cluster)
//                                    .onTapGesture {
//                                        newFeedViewModel.posts = cluster.memberAnnotations.map { $0.post }
//                                        selectedCluster = cluster
//                                    }
//                            }
//                        }
//                        
//                    }
//                }
////                .readSize(onChange: { newValue in
////                    viewModel.mapSize = newValue
////                })
////                .onAppear{
////                    viewModel.setPosts(posts: filteredPosts)
////                }
////                .onMapCameraChange { context in
////                    viewModel.currentRegion = context.region
////                }
////                .onMapCameraChange(frequency: .onEnd) { context in
////                    Task.detached { await viewModel.reloadAnnotations() }
////                }
//                .mapStyle(.standard(pointsOfInterest: .excludingAll))
//                .frame(height: UIScreen.main.bounds.height * 0.5)
//                .cornerRadius(10)
//                .sheet(item: $selectedCluster) { locationWithPosts in
//                    NavigationStack{
//                        ScrollView{
//                            ProfileFeedView(viewModel: newFeedViewModel, scrollPosition: .constant(nil), scrollTarget: .constant(nil))
//                        }
//                        .modifier(BackButtonModifier())
//                        
//                    }
//                    .onDisappear {
//                        updateOriginalFeedViewModel()
//                    }
//                }
//                .fullScreenCover(item: $selectedPost) { post in
//                    NavigationStack {
//                        SecondaryFeedView(viewModel: newFeedViewModel, hideFeedOptions: true, titleText: "Posts")
//                    }
//                    .onDisappear {
//                        updateOriginalFeedViewModel()
//                    }
//                }
//                .sheet(item: $selectedWrittenPost) { post in
//                    NavigationStack {
//                        ScrollView {
//                            WrittenFeedCell(viewModel: newFeedViewModel, post: .constant(post), scrollPosition: .constant(nil), pauseVideo: .constant(false), selectedPost: .constant(nil), checkLikes: true)
//                        }
//                        .modifier(BackButtonModifier())
//                        .navigationDestination(for: PostRestaurant.self) { restaurant in
//                            RestaurantProfileView(restaurantId: restaurant.id)
//                        }
//                        
//                    }
//                    .onDisappear {
//                        updateOriginalFeedViewModel()
//                    }
//                }
//            }
//            )
//        } else {
//            HStack{
//                Spacer()
//                Text("No Posts to Show")
//                    .foregroundStyle(.gray)
//                    .font(.custom("MuseoSansRounded-300", size: 16))
//                Spacer()
//            }
//        }
//    }
//    private func updateOriginalFeedViewModel() {
//        for (index, post) in feedViewModel.posts.enumerated() {
//            if let updatedPost = newFeedViewModel.posts.first(where: { $0.id == post.id }) {
//                feedViewModel.posts[index] = updatedPost
//            }
//        }
//    }
//}
//
//struct MultiPostAnnotationView: View {
//    let count: Int
//    
//    var body: some View {
//        ZStack {
//            Circle()
//                .fill(Color.white)
//                .frame(width: 40, height: 40)
//                .shadow(radius: 2)
//            
//            Text("\(count)")
//                .font(.system(size: 14, weight: .bold))
//                .foregroundColor(.black)
//        }
//    }
//}
//
//struct SinglePostAnnotationView: View {
//    let post: Post
//    
//    var body: some View {
//        if post.mediaType == .written {
//            ZStack {
//                Rectangle()
//                    .foregroundStyle(.white)
//                    .frame(width: 38, height: 38)
//                    .clipShape(RoundedRectangle(cornerRadius: 6))
//                Image(systemName: "line.3.horizontal")
//                    .resizable()
//                    .scaledToFit()
//                    .foregroundStyle(Color("Colors/AccentColor"))
//                    .frame(width: 20, height: 20)
//            }
//        } else {
//            PostAnnotationView(post: post)
//        }
//    }
//}
//
//struct PostListItem: View {
//    let post: Post
//    
//    var body: some View {
//        HStack {
//            if let url = URL(string: post.thumbnailUrl) {
//                KFImage(url)
//                    .resizable()
//                    .scaledToFill()
//                    .frame(width: 50, height: 50)
//                    .clipShape(RoundedRectangle(cornerRadius: 6))
//            } else {
//                Image(systemName: post.mediaType == .written ? "doc.text" : "photo")
//                    .resizable()
//                    .scaledToFit()
//                    .frame(width: 50, height: 50)
//                    .foregroundColor(.gray)
//            }
//            
//            VStack(alignment: .leading) {
//                Text(post.restaurant.name)
//                    .font(.headline)
//                Text(post.caption)
//                    .font(.subheadline)
//                    .lineLimit(1)
//            }
//        }
//    }
//}
//
//struct LocationWithPosts: Identifiable {
//    let id = UUID()
//    let coordinate: CLLocationCoordinate2D
//    let posts: [Post]
//}
//
//struct PostAnnotationView: View {
//    let post: Post
//    
//    var body: some View {
//        VStack(spacing: 0) {
//            ZStack() {
//                // Square background with point
//                Rectangle()
//                    .foregroundStyle(.white)
//                    .frame(width: 44, height: 44)
//                    .clipShape(RoundedRectangle(cornerRadius: 6))
//                
//                // Thumbnail image
//                if let url = URL(string: post.thumbnailUrl) {
//                    KFImage(url)
//                        .resizable()
//                        .scaledToFill()
//                        .frame(width: 40, height: 40)
//                        .clipShape(RoundedRectangle(cornerRadius: 6))
//                    
//                } else {
//                    RoundedRectangle(cornerRadius: 6)
//                        .fill(Color.gray.opacity(0.3))
//                        .frame(width: 44, height: 44)
//                }
//            }
//            
//        }
//    }
//}
//
//class ProfileMapViewModel: ObservableObject {
//    let clusterManager = ClusterManager<PostMapAnnotation>()
//    @Published var posts = [Post]()
//    var annotations: [PostMapAnnotation] = []
//    var clusters: [PostClusterAnnotation] = []
//    var mapSize: CGSize = .zero
//    @Published var currentRegion: MKCoordinateRegion = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 34.0549, longitude: -118.2426), span: MKCoordinateSpan(latitudeDelta: 0.03, longitudeDelta: 0.03))
//    func setPosts(posts: [Post]) {
//        self.posts = posts
//        let postAnnotations: [PostMapAnnotation] = self.posts.compactMap {post in
//            if let coordinates = post.coordinates {
//                return PostMapAnnotation(coordinate: coordinates, post: post)
//            } else {
//                return nil
//            }
//        }
//        
//        Task{
//            await clusterManager.add(postAnnotations)
//            await reloadAnnotations()
//        }
//        
//    }
//    func reloadAnnotations() async {
//        async let changes = clusterManager.reload(mapViewSize: mapSize, coordinateRegion: currentRegion)
//        await applyChanges(changes)
//    }
//    @MainActor
//    private func applyChanges(_ difference: ClusterManager<PostMapAnnotation>.Difference) {
//        for removal in difference.removals {
//            switch removal {
//            case .annotation(let annotation):
//                annotations.removeAll { $0 == annotation }
//            case .cluster(let clusterAnnotation):
//                clusters.removeAll { $0.id == clusterAnnotation.id }
//            }
//        }
//        for insertion in difference.insertions {
//            switch insertion {
//            case .annotation(let newItem):
//                annotations.append(newItem)
//            case .cluster(let newItem):
//                clusters.append(PostClusterAnnotation(
//                    id: newItem.id,
//                    coordinate: newItem.coordinate,
//                    count: newItem.memberAnnotations.count,
//                    memberAnnotations: newItem.memberAnnotations
//                ))
//            }
//        }
//    }
//}
//
//struct PostMapAnnotation: CoordinateIdentifiable, Identifiable, Hashable, Equatable {
//    let id = UUID()
//    var coordinate: CLLocationCoordinate2D
//    var post: Post
//}
//struct PostClusterAnnotation: Identifiable {
//    var id = UUID()
//    var coordinate: CLLocationCoordinate2D
//    var count: Int
//    var memberAnnotations: [PostMapAnnotation]
//    
//}
struct PostClusterCell: View {
    var cluster: PostClusterAnnotation
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.white)
                .frame(width: 20, height: 20)
                .overlay(
                    Circle()
                        .stroke(Color("Colors/AccentColor"), lineWidth: 2)
                )
            Text("\(cluster.count)")
                .foregroundColor(.black)
                .font(.custom("MuseoSansRounded-300", size: 10))
        }
    }
}

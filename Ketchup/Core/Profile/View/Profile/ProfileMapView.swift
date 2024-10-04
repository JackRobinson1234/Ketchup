//
//  IOS16MapView.swift
//  Ketchup
//
//  Created by Jack Robinson on 9/21/24.
//

import SwiftUI
import Kingfisher
import MapKit
import ClusterMap
import ClusterMapSwiftUI

@available(iOS 17.0, *)
struct ProfileMapView: View {
    @EnvironmentObject var tabBarController: TabBarController
    @StateObject var viewModel = ProfileMapViewModel()
    @ObservedObject var feedViewModel: FeedViewModel
    @State var selectedPost: Post?
    @State var selectedWrittenPost: Post?
    @State var selectedLocation: LocationWithPosts?
    @Environment(\.dismiss) var dismiss
    @StateObject var newFeedViewModel = FeedViewModel()
    @State var selectedCluster: ProfilePostClusterAnnotation?
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
            Map(initialPosition: .region(viewModel.initialUSRegion)) {
                ForEach(viewModel.annotations, id: \.self) { item in
                    Annotation(item.post.restaurant.name, coordinate: item.coordinate) {
                        Button {
                            //print("DEBUG: Single post annotation tapped")
                            selectedWrittenPost = item.post
                        } label: {
                            ProfileSinglePostAnnotationView(post: item.post)
                        }
                    }
                }
                ForEach(viewModel.clusters) { cluster in
                    Annotation("", coordinate: cluster.coordinate) {
                        ProfilePostClusterCell(cluster: cluster)
                            .onTapGesture {
                                newFeedViewModel.posts = cluster.memberAnnotations.map { $0.post}
                                //print("DEBUG: Cluster tapped - \(cluster.count) posts")
                                selectedCluster = cluster
                            }
                    }
                }
            }
            
            .readSize(onChange: { newValue in
                //print("DEBUG: Map size changed to \(newValue)")
                viewModel.mapSize = newValue
                //print(newValue)
            })
            .onAppear {
                //print("DEBUG: ProfileMapView appeared")
                viewModel.setPosts(posts: filteredPosts)
            }
            .onMapCameraChange { context in
                //print("DEBUG: Map camera changing - Center: \(context.region.center), Span: \(context.region.span)")
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
                VStack{
                    Button{
                        tabBarController.selectedTab = 2
                    } label: {
                        Text("+ Create your first post!")
                            .foregroundStyle(Color("Colors/AccentColor"))
                            .font(.custom("MuseoSansRounded-700", size: 14))
                        
                        
                    }
                    Text("No Posts to Show 😢")
                        .foregroundStyle(.gray)
                        .font(.custom("MuseoSansRounded-300", size: 16))
                }
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



struct ProfileSinglePostAnnotationView: View {
    let post: Post
    
    var body: some View {
        if post.mediaType == .written || post.mediaUrls.isEmpty{
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
    let clusterManager = ClusterManager<ProfilePostMapAnnotation>()
    @Published var posts = [Post]()
    var annotations: [ProfilePostMapAnnotation] = []
    var clusters: [ProfilePostClusterAnnotation] = []
    var mapSize: CGSize = .zero
    let initialUSRegion = MKCoordinateRegion(
           center: CLLocationCoordinate2D(latitude: 39.8283, longitude: -98.5795),
           span: MKCoordinateSpan(latitudeDelta: 60, longitudeDelta: 60)
       )
    @Published var currentRegion: MKCoordinateRegion = MKCoordinateRegion(
           center: CLLocationCoordinate2D(latitude: 39.8283, longitude: -98.5795),
           span: MKCoordinateSpan(latitudeDelta: 60, longitudeDelta: 60)
       )
    func setPosts(posts: [Post]) {
        //print("DEBUG: Setting posts - Count: \(posts.count)")
        annotations = []
        clusters = []
        self.posts = posts
        let postAnnotations: [ProfilePostMapAnnotation] = self.posts.compactMap { post in
            if let coordinates = post.coordinates {
                return ProfilePostMapAnnotation(coordinate: coordinates, post: post)
            } else {
                //print("DEBUG: Post without coordinates - ID: \(post.id)")
                return nil
            }
        }
        
        //print("DEBUG: Created \(postAnnotations.count) annotations")
        
        Task {
            await clusterManager.add(postAnnotations)
            //print("DEBUG: Added annotations to cluster manager")
            await reloadAnnotations()
        }
    }
    
    func reloadAnnotations() async {
        //print("DEBUG: Reloading annotations - Map size: \(mapSize), Region center: \(currentRegion.center)")
        let changes = await clusterManager.reload(mapViewSize: mapSize, coordinateRegion: currentRegion)
        //print("DEBUG: Cluster manager reload complete")
        applyChanges(changes)
    }
    
    private func applyChanges(_ difference: ClusterManager<ProfilePostMapAnnotation>.Difference) {
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
                clusters.append(ProfilePostClusterAnnotation(
                    id: newItem.id,
                    coordinate: newItem.coordinate,
                    count: newItem.memberAnnotations.count,
                    memberAnnotations: newItem.memberAnnotations
                ))
            }
        }
    }
}
struct ProfilePostMapAnnotation: CoordinateIdentifiable, Identifiable, Hashable, Equatable {
    let id = UUID()
    var coordinate: CLLocationCoordinate2D
    var post: Post
}
struct ProfilePostClusterAnnotation: Identifiable {
    var id = UUID()
    var coordinate: CLLocationCoordinate2D
    var count: Int
    var memberAnnotations: [ProfilePostMapAnnotation]
}

struct ProfilePostClusterCell: View {
    var cluster: ProfilePostClusterAnnotation
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



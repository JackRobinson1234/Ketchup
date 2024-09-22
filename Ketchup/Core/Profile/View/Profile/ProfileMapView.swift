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
    @State var selectedCluster: ProfilePostClusterAnnotation?
    // Filter posts to exclude those with restaurant IDs starting with "construction"
    var filteredPosts: [Post] {
        feedViewModel.posts.filter { !$0.restaurant.id.starts(with: "construction") }
    }

    var body: some View {
        if !filteredPosts.isEmpty {
            GeometryReader { geometryProxy in
                ProfileKitMapView(
                    viewModel: viewModel,
                    selectedWrittenPost: $selectedWrittenPost,
                    selectedCluster: $selectedCluster,
                    mapSize: geometryProxy.size
                )
            }
            .readSize(onChange: { newValue in
                viewModel.mapSize = newValue
            })
            .onAppear {
                viewModel.setPosts(posts: filteredPosts)
            }
            .frame(height: UIScreen.main.bounds.height * 0.5)
            .cornerRadius(10)
            .sheet(item: $selectedCluster) { cluster in
                NavigationStack {
                    ScrollView {
                        ProfileFeedView(
                            viewModel: newFeedViewModel,
                            scrollPosition: .constant(nil),
                            scrollTarget: .constant(nil)
                        )
                    }
                    .modifier(BackButtonModifier())
                }
                .onDisappear {
                    updateOriginalFeedViewModel()
                }
                .onAppear{
                    newFeedViewModel.posts = cluster.memberAnnotations.map { $0.post}
                }
            }
            .fullScreenCover(item: $selectedPost) { post in
                NavigationStack {
                    ScrollView {
                        WrittenFeedCell(
                            viewModel: newFeedViewModel,
                            post: .constant(post),
                            scrollPosition: .constant(nil),
                            pauseVideo: .constant(false),
                            selectedPost: .constant(nil),
                            checkLikes: true
                        )
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
            .sheet(item: $selectedWrittenPost) { post in
                NavigationStack {
                    ScrollView {
                        WrittenFeedCell(
                            viewModel: newFeedViewModel,
                            post: .constant(post),
                            scrollPosition: .constant(nil),
                            pauseVideo: .constant(false),
                            selectedPost: .constant(nil),
                            checkLikes: true
                        )
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
            HStack {
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

class ProfileMapViewModel: ObservableObject {
    let clusterManager = ClusterManager<ProfilePostAnnotation>()
    @Published var posts = [Post]()
    @Published var annotations: [ProfilePostAnnotation] = []
    @Published var clusters: [ProfilePostClusterAnnotation] = []
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
        annotations = []
        clusters = []
        self.posts = posts
        let postAnnotations: [ProfilePostAnnotation] = self.posts.compactMap { post in
            if let coordinates = post.coordinates {
                return ProfilePostAnnotation(coordinate: coordinates, post: post)
            } else {
                return nil
            }
        }

        Task {
            await clusterManager.add(postAnnotations)
            await reloadAnnotations()
        }
    }

    func reloadAnnotations() async {
        let changes = await clusterManager.reload(mapViewSize: mapSize, coordinateRegion: currentRegion)
        applyChanges(changes)
    }

    private func applyChanges(_ difference: ClusterManager<ProfilePostAnnotation>.Difference) {
        DispatchQueue.main.async {
            for removal in difference.removals {
                switch removal {
                case .annotation(let annotation):
                    self.annotations.removeAll { $0 == annotation }
                case .cluster(let clusterAnnotation):
                    self.clusters.removeAll { $0.id == clusterAnnotation.id }
                }
            }
            for insertion in difference.insertions {
                switch insertion {
                case .annotation(let newItem):
                    self.annotations.append(newItem)
                case .cluster(let newItem):
                    self.clusters.append(ProfilePostClusterAnnotation(
                        id: newItem.id,
                        coordinate: newItem.coordinate,
                        count: newItem.memberAnnotations.count,
                        memberAnnotations: newItem.memberAnnotations
                    ))
                }
            }
        }
    }
}

class ProfilePostAnnotation: NSObject, CoordinateIdentifiable, Identifiable, MKAnnotation {
    let id = UUID()
    var coordinate: CLLocationCoordinate2D
    var post: Post
    var title: String?

    init(coordinate: CLLocationCoordinate2D, post: Post) {
        self.coordinate = coordinate
        self.post = post
        self.title = post.restaurant.name
        super.init()
    }
}

class ProfilePostClusterAnnotation: NSObject, Identifiable, MKAnnotation, CoordinateIdentifiable {
    var id = UUID()
    var coordinate: CLLocationCoordinate2D
    var count: Int
    var memberAnnotations: [ProfilePostAnnotation]
    var title: String?

    init(id: UUID, coordinate: CLLocationCoordinate2D, count: Int, memberAnnotations: [ProfilePostAnnotation]) {
        self.id = id
        self.coordinate = coordinate
        self.count = count
        self.memberAnnotations = memberAnnotations
        self.title = "Cluster of \(count) Posts"
        super.init()
    }
}

struct ProfileKitMapView: UIViewRepresentable {
    @ObservedObject var viewModel: ProfileMapViewModel
    @Binding var selectedWrittenPost: Post?
    @Binding var selectedCluster: ProfilePostClusterAnnotation?
    var mapSize: CGSize
    func makeCoordinator() -> Coordinator {
        Coordinator(self, viewModel: viewModel)
    }

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView(frame: .zero)
        mapView.pointOfInterestFilter = .excludingAll
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true

        // Register annotation views
        mapView.register(ProfilePostAnnotationView.self, forAnnotationViewWithReuseIdentifier: ProfilePostAnnotationView.identifier)
        mapView.register(ProfilePostClusterAnnotationView.self, forAnnotationViewWithReuseIdentifier: ProfilePostClusterAnnotationView.identifier)

        return mapView
    }

    func updateUIView(_ uiView: MKMapView, context: Context) {
        uiView.removeAnnotations(uiView.annotations)
        uiView.addAnnotations(viewModel.annotations)
        uiView.addAnnotations(viewModel.clusters)

        DispatchQueue.main.async {
            viewModel.mapSize = mapSize
        }
    }

    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: ProfileKitMapView
        var viewModel: ProfileMapViewModel
        var debouncer = Debouncer(delay: 0.5)

        init(_ parent: ProfileKitMapView, viewModel: ProfileMapViewModel) {
            self.parent = parent
            self.viewModel = viewModel
        }

        func mapViewDidChangeVisibleRegion(_ mapView: MKMapView) {
            let newRegion = mapView.region
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                viewModel.currentRegion = mapView.region
                debouncer.schedule{
                    Task { await self.viewModel.reloadAnnotations() }
                }
            }
        }

        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            if let postAnnotation = annotation as? ProfilePostAnnotation {
                let identifier = ProfilePostAnnotationView.identifier
                var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? ProfilePostAnnotationView
                if annotationView == nil {
                    annotationView = ProfilePostAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                } else {
                    annotationView?.annotation = annotation
                }
                return annotationView
            } else if let clusterAnnotation = annotation as? ProfilePostClusterAnnotation {
                let identifier = ProfilePostClusterAnnotationView.identifier
                var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? ProfilePostClusterAnnotationView
                if annotationView == nil {
                    annotationView = ProfilePostClusterAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                } else {
                    annotationView?.annotation = annotation
                }
                return annotationView
            }
            return nil
        }

        func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
            if let postAnnotation = view.annotation as? ProfilePostAnnotation {
                mapView.deselectAnnotation(postAnnotation, animated: false)
                DispatchQueue.main.async {
                    self.parent.selectedWrittenPost = postAnnotation.post
                }
            } else if let clusterAnnotation = view.annotation as? ProfilePostClusterAnnotation {
                mapView.deselectAnnotation(clusterAnnotation, animated: false)
                DispatchQueue.main.async {
                    
                    self.parent.selectedCluster = clusterAnnotation
                }
            }
        }
    }
}

class ProfilePostAnnotationView: MKAnnotationView {
    static let identifier = "ProfilePostAnnotationView"

    private var hostingController: UIHostingController<ProfileSinglePostAnnotationView>?

    override var annotation: MKAnnotation? {
        willSet {
            guard let postAnnotation = newValue as? ProfilePostAnnotation else { return }
            configure(with: postAnnotation)
        }
    }

    private func configure(with annotation: ProfilePostAnnotation) {
        canShowCallout = false
        self.subviews.forEach { $0.removeFromSuperview() }

        let clusterCell = ProfileSinglePostAnnotationView(post: annotation.post)
        let hostingController = UIHostingController(rootView: clusterCell)
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(hostingController.view)
        self.hostingController = hostingController

        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: self.topAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: self.trailingAnchor),
        ])
    }
}

class ProfilePostClusterAnnotationView: MKAnnotationView {
    static let identifier = "ProfilePostClusterAnnotationView"

    private var hostingController: UIHostingController<ProfilePostClusterCell>?

    override var annotation: MKAnnotation? {
        willSet {
            guard let clusterAnnotation = newValue as? ProfilePostClusterAnnotation else { return }
            configure(with: clusterAnnotation)
        }
    }

    private func configure(with cluster: ProfilePostClusterAnnotation) {
        canShowCallout = false
        self.subviews.forEach { $0.removeFromSuperview() }

        let clusterCell = ProfilePostClusterCell(cluster: cluster)
        let hostingController = UIHostingController(rootView: clusterCell)
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(hostingController.view)
        self.hostingController = hostingController

        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: self.topAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: self.trailingAnchor),
        ])
    }
}

struct ProfileSinglePostAnnotationView: View {
    let post: Post

    var body: some View {
        if post.mediaType == .written || post.mediaUrls.isEmpty {
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

struct PostAnnotationView: View {
    let post: Post

    var body: some View {
        VStack(spacing: 0) {
            ZStack() {
                Rectangle()
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .clipShape(RoundedRectangle(cornerRadius: 6))

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
struct LocationWithPosts: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
    let posts: [Post]
}

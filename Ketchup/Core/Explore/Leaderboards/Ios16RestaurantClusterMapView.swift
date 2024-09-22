//
//  Ios16RestaurantClusterMapView.swift
//  Ketchup
//
//  Created by Jack Robinson on 9/22/24.
//

import SwiftUI
import MapKit
import Kingfisher
import ClusterMap
import ClusterMapSwiftUI
struct Ios16RestaurantClusterMapView: View {
    @StateObject private var viewModel: Ios16RestaurantMapViewModel
    @State private var selectedRestaurant: Restaurant?
    @State private var selectedCluster: Ios16RestaurantClusterAnnotation?

    init(restaurants: [Restaurant]) {
        _viewModel = StateObject(wrappedValue: Ios16RestaurantMapViewModel(restaurants: restaurants))
    }

    var body: some View {
        if !viewModel.restaurants.isEmpty {
            GeometryReader { geometryProxy in
                Ios16RestaurantKitMapView(
                    viewModel: viewModel,
                    selectedRestaurant: $selectedRestaurant,
                    selectedCluster: $selectedCluster,
                    mapSize: geometryProxy.size
                )
            }
            .readSize(onChange: { newValue in
                viewModel.mapSize = newValue
            })
            .onAppear {
                viewModel.initializeAnnotations()
            }
            .frame(height: 500)
            .cornerRadius(10)
            .fullScreenCover(item: $selectedRestaurant) { restaurant in
                NavigationStack {
                    RestaurantProfileView(restaurantId: restaurant.id)
                }
            }
            .sheet(item: $selectedCluster) { cluster in
                NavigationStack {
                    ScrollView {
                        ForEach(cluster.memberAnnotations, id: \.id) { item in
                            NavigationLink(destination: RestaurantProfileView(restaurantId: item.restaurant.id)) {
                                Ios16RestaurantMapCell(restaurant: item.restaurant)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .modifier(BackButtonModifier())
                }
            }
        } else {
            Text("No Restaurant locations Found")
        }
    }
}
class Ios16RestaurantMapViewModel: ObservableObject {
    let clusterManager = ClusterManager<Ios16RestaurantAnnotation>()
    @Published var restaurants: [Restaurant]
    @Published var annotations: [Ios16RestaurantAnnotation] = []
    @Published var clusters: [Ios16RestaurantClusterAnnotation] = []
    var mapSize: CGSize = .zero
    let initialUSRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 39.8283, longitude: -98.5795),
        span: MKCoordinateSpan(latitudeDelta: 60, longitudeDelta: 60)
    )
    @Published var currentRegion: MKCoordinateRegion

    init(restaurants: [Restaurant]) {
        self.restaurants = restaurants
        self.currentRegion = initialUSRegion
    }

    func initializeAnnotations() {
        let Ios16RestaurantAnnotations: [Ios16RestaurantAnnotation] = self.restaurants.compactMap { restaurant in
            guard let coordinates = restaurant.coordinates else { return nil }
            return Ios16RestaurantAnnotation(coordinate: coordinates, restaurant: restaurant)
        }

        Task {
            await clusterManager.add(Ios16RestaurantAnnotations)
            await reloadAnnotations()
        }
    }

    func reloadAnnotations() async {
        let changes = await clusterManager.reload(mapViewSize: mapSize, coordinateRegion: currentRegion)
        applyChanges(changes)
    }

    private func applyChanges(_ difference: ClusterManager<Ios16RestaurantAnnotation>.Difference) {
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
                    self.clusters.append(Ios16RestaurantClusterAnnotation(
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

class Ios16RestaurantAnnotation: NSObject, MKAnnotation, Identifiable, CoordinateIdentifiable {
    let id = UUID()
    var coordinate: CLLocationCoordinate2D
    var restaurant: Restaurant
    var title: String?

    init(coordinate: CLLocationCoordinate2D, restaurant: Restaurant) {
        self.coordinate = coordinate
        self.restaurant = restaurant
        self.title = restaurant.name
        super.init()
    }
}

class Ios16RestaurantClusterAnnotation: NSObject, MKAnnotation, Identifiable, CoordinateIdentifiable {
    var id = UUID()
    var coordinate: CLLocationCoordinate2D
    var count: Int
    var memberAnnotations: [Ios16RestaurantAnnotation]
    var title: String?

    init(id: UUID, coordinate: CLLocationCoordinate2D, count: Int, memberAnnotations: [Ios16RestaurantAnnotation]) {
        self.id = id
        self.coordinate = coordinate
        self.count = count
        self.memberAnnotations = memberAnnotations
        self.title = "Cluster of \(count) Restaurants"
        super.init()
    }
}
struct Ios16RestaurantKitMapView: UIViewRepresentable {
    @ObservedObject var viewModel: Ios16RestaurantMapViewModel
    @Binding var selectedRestaurant: Restaurant?
    @Binding var selectedCluster: Ios16RestaurantClusterAnnotation?
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
        mapView.register(Ios16RestaurantAnnotationView.self, forAnnotationViewWithReuseIdentifier: Ios16RestaurantAnnotationView.identifier)
        mapView.register(Ios16RestaurantClusterAnnotationView.self, forAnnotationViewWithReuseIdentifier: Ios16RestaurantClusterAnnotationView.identifier)

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
        var parent: Ios16RestaurantKitMapView
        var viewModel: Ios16RestaurantMapViewModel
        var debouncer = Debouncer(delay: 0.5)
        init(_ parent: Ios16RestaurantKitMapView, viewModel: Ios16RestaurantMapViewModel) {
            self.parent = parent
            self.viewModel = viewModel
        }

        func mapViewDidChangeVisibleRegion(_ mapView: MKMapView) {
            let newRegion = mapView.region
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.viewModel.currentRegion = newRegion
                debouncer.schedule{
                    Task { await self.viewModel.reloadAnnotations() }
                }
            }
        }

        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            if let Ios16RestaurantAnnotation = annotation as? Ios16RestaurantAnnotation {
                let identifier = Ios16RestaurantAnnotationView.identifier
                var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? Ios16RestaurantAnnotationView
                if annotationView == nil {
                    annotationView = Ios16RestaurantAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                } else {
                    annotationView?.annotation = annotation
                }
                return annotationView
            } else if let clusterAnnotation = annotation as? Ios16RestaurantClusterAnnotation {
                let identifier = Ios16RestaurantClusterAnnotationView.identifier
                var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? Ios16RestaurantClusterAnnotationView
                if annotationView == nil {
                    annotationView = Ios16RestaurantClusterAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                } else {
                    annotationView?.annotation = annotation
                }
                return annotationView
            }
            return nil
        }

        func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
            if let Ios16RestaurantAnnotation = view.annotation as? Ios16RestaurantAnnotation {
                mapView.deselectAnnotation(Ios16RestaurantAnnotation, animated: false)
                DispatchQueue.main.async {
                    self.parent.selectedRestaurant = Ios16RestaurantAnnotation.restaurant
                }
            } else if let clusterAnnotation = view.annotation as? Ios16RestaurantClusterAnnotation {
                mapView.deselectAnnotation(clusterAnnotation, animated: false)
                DispatchQueue.main.async {
                    self.parent.selectedCluster = clusterAnnotation
                }
            }
        }
    }
}
class Ios16RestaurantAnnotationView: MKAnnotationView {
    static let identifier = "Ios16RestaurantAnnotationView"

    private var hostingController: UIHostingController<Ios16RestaurantAnnotationContentView>?

    override var annotation: MKAnnotation? {
        willSet {
            guard let Ios16RestaurantAnnotation = newValue as? Ios16RestaurantAnnotation else { return }
            configure(with: Ios16RestaurantAnnotation)
        }
    }

    private func configure(with annotation: Ios16RestaurantAnnotation) {
        canShowCallout = false
        self.subviews.forEach { $0.removeFromSuperview() }

        let contentView = Ios16RestaurantAnnotationContentView(restaurant: annotation.restaurant)
        let hostingController = UIHostingController(rootView: contentView)
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
class Ios16RestaurantClusterAnnotationView: MKAnnotationView {
    static let identifier = "Ios16RestaurantClusterAnnotationView"

    private var hostingController: UIHostingController<Ios16RestaurantClusterCell>?

    override var annotation: MKAnnotation? {
        willSet {
            guard let clusterAnnotation = newValue as? Ios16RestaurantClusterAnnotation else { return }
            configure(with: clusterAnnotation)
        }
    }

    private func configure(with cluster: Ios16RestaurantClusterAnnotation) {
        canShowCallout = false
        self.subviews.forEach { $0.removeFromSuperview() }

        let contentView = Ios16RestaurantClusterCell(cluster: cluster)
        let hostingController = UIHostingController(rootView: contentView)
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
struct Ios16RestaurantAnnotationContentView: View {
    let restaurant: Restaurant

    var body: some View {
        VStack(spacing: 4) {
            if let imageUrl = restaurant.profileImageUrl {
                KFImage(URL(string: imageUrl))
                    .resizable()
                    .scaledToFill()
                    .frame(width: 40, height: 40)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.white, lineWidth: 2)
                    )
            } else {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.blue)
                    .frame(width: 40, height: 40)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.white, lineWidth: 2)
                    )
            }
            
            Text(restaurant.name)
                .foregroundColor(.black)
                .font(.custom("MuseoSansRounded-500", size: 10))
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(width: 60)  // Adjust this width as needed
                
        }
        .shadow(color: Color.black.opacity(0.2), radius: 2, x: 0, y: 2)
    }
}
struct Ios16RestaurantClusterCell: View {
    var cluster: Ios16RestaurantClusterAnnotation

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
struct Ios16RestaurantMapCell: View {
    let restaurant: Restaurant

    var body: some View {
        HStack {
            if let imageUrl = restaurant.profileImageUrl {
                KFImage(URL(string: imageUrl))
                    .resizable()
                    .scaledToFill()
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray)
                    .frame(width: 60, height: 60)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(restaurant.name)
                    .font(.custom("MuseoSansRounded-700", size: 16))
                    .foregroundColor(.primary)
                Text("\(restaurant.city ?? ""), \(restaurant.state ?? "")")
                    .font(.custom("MuseoSansRounded-300", size: 14))
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
    }
}

//
//  IOS16CollectionMapView.swift
//  Ketchup
//
//  Created by Jack Robinson on 9/21/24.
//

import SwiftUI
import MapKit
import ClusterMap
import ClusterMapSwiftUI
import Kingfisher
struct Ios16CollectionMapView: View {
    @ObservedObject var collectionsViewModel: CollectionsViewModel
    @StateObject private var viewModel = Ios16CollectionMapViewModel()
    @State private var selectedItem: CollectionItem?
    @State private var selectedCluster: Ios16CollectionItemClusterAnnotation?
    var body: some View {
        if let collection = collectionsViewModel.selectedCollection,
           !collectionsViewModel.items.isEmpty {
            GeometryReader { geometryProxy in
                Ios16CollectionKitMapView(viewModel: viewModel, selectedRestaurant: $selectedItem, selectedCluster: $selectedCluster,  mapSize: geometryProxy.size  )
            }

            .readSize(onChange: { newValue in
                viewModel.mapSize = newValue
            })
            .onAppear {
                viewModel.setItems(items: collectionsViewModel.items)
            }

            .frame(height: 500)
            .cornerRadius(10)
            .sheet(item: $selectedItem) { item in
                NavigationStack {
                    RestaurantProfileView(restaurantId: item.id)
                }
            }
            .sheet(item: $selectedCluster){ cluster in
                NavigationStack{
                    ScrollView{
                        ForEach(cluster.memberAnnotations, id: \.id) { item in
                            NavigationLink(destination: RestaurantProfileView(restaurantId: item.collectionItem.id)) {
                                CollectionItemCell(item: item.collectionItem, viewModel: collectionsViewModel)
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

class Ios16CollectionMapViewModel: ObservableObject {
    let clusterManager = ClusterManager<Ios16CollectionItemAnnotation>()
    @Published var items = [CollectionItem]()
    @Published var annotations: [Ios16CollectionItemAnnotation] = []
    @Published var clusters: [Ios16CollectionItemClusterAnnotation] = []
    var mapSize: CGSize = .zero
    let initialUSRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 39.8283, longitude: -98.5795),
        span: MKCoordinateSpan(latitudeDelta: 60, longitudeDelta: 60)
    )
    @Published var currentRegion: MKCoordinateRegion
    
    init() {
        self.currentRegion = initialUSRegion
    }
    
    func setItems(items: [CollectionItem]) {
        annotations = []
        clusters = []
        self.items = items
        let itemAnnotations: [Ios16CollectionItemAnnotation] = self.items.compactMap { item in
            guard let geoPoint = item.geoPoint else { return nil }
            let coordinate = CLLocationCoordinate2D(latitude: geoPoint.latitude, longitude: geoPoint.longitude)
            return Ios16CollectionItemAnnotation(coordinate: coordinate, collectionItem: item)
        }
        
        Task {
            await clusterManager.add(itemAnnotations)
            await reloadAnnotations()
        }
    }
    
    func reloadAnnotations() async {
        let changes = await clusterManager.reload(mapViewSize: mapSize, coordinateRegion: currentRegion)
        applyChanges(changes)
    }
    
    private func applyChanges(_ difference: ClusterManager<Ios16CollectionItemAnnotation>.Difference) {
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
                    self.clusters.append(Ios16CollectionItemClusterAnnotation(
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

class Ios16CollectionItemAnnotation: NSObject, CoordinateIdentifiable, Identifiable, MKAnnotation {
    let id = UUID()
    var coordinate: CLLocationCoordinate2D
    var collectionItem: CollectionItem
    
    var name: String { collectionItem.name }
    var title: String?

    init(coordinate: CLLocationCoordinate2D, collectionItem: CollectionItem) {
        self.coordinate = coordinate
        self.collectionItem = collectionItem
        self.title = collectionItem.name
        super.init()
    }
}

class Ios16CollectionItemClusterAnnotation: NSObject, Identifiable, MKAnnotation, CoordinateIdentifiable {
    var id = UUID()
    var coordinate: CLLocationCoordinate2D
    var count: Int
    var memberAnnotations: [Ios16CollectionItemAnnotation]
    var title: String?

    init(id: UUID, coordinate: CLLocationCoordinate2D, count: Int, memberAnnotations: [Ios16CollectionItemAnnotation]) {
        self.id = id
        self.coordinate = coordinate
        self.count = count
        self.memberAnnotations = memberAnnotations
        self.title = "Cluster of \(count) Restaurants"
        super.init()
    }
}

struct Ios16CollectionItemAnnotationView: View {
    let item: CollectionItem
    
    var body: some View {
        if let imageUrl = item.image {
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
    }
}

struct Ios16CollectionItemClusterCell: View {
    var cluster: Ios16CollectionItemClusterAnnotation
    
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

struct Ios16CollectionKitMapView: UIViewRepresentable {
    @ObservedObject var viewModel: Ios16CollectionMapViewModel
    @Binding var selectedRestaurant: CollectionItem?
    @Binding var selectedCluster: Ios16CollectionItemClusterAnnotation?
    var mapSize: CGSize
    
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self, viewModel: viewModel)
    }
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView(frame: .zero)
        mapView.pointOfInterestFilter = .excludingAll
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        // Set the mapSize here
        DispatchQueue.main.async {
            self.viewModel.mapSize = mapView.bounds.size
        }
        
        // Register annotation views
        mapView.register(Ios16RestaurantAnnotationMapView.self, forAnnotationViewWithReuseIdentifier: Ios16RestaurantAnnotationMapView.identifier)
        mapView.register(Ios16ClusterAnnotationView.self, forAnnotationViewWithReuseIdentifier: Ios16ClusterAnnotationView.identifier)
        
        return mapView
    }
    
    func updateUIView(_ uiView: MKMapView, context: Context) {
        uiView.removeAnnotations(uiView.annotations)
//        if let selectedLocation = selectedLocation {
//            let coordinateRegion = MKCoordinateRegion(center: selectedLocation, span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05))
//            uiView.setRegion(coordinateRegion, animated: true)
//            // After moving the map, set selectedLocation to nil so that we don't keep moving it
//            DispatchQueue.main.async {
//                self.selectedLocation = nil
//            }
        //}
       
            uiView.addAnnotations(viewModel.annotations)
            uiView.addAnnotations(viewModel.clusters)
        
        DispatchQueue.main.async {
            viewModel.mapSize = mapSize
        }
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: Ios16CollectionKitMapView
        var viewModel: Ios16CollectionMapViewModel
        
        
        init(_ parent: Ios16CollectionKitMapView, viewModel: Ios16CollectionMapViewModel) {
            self.parent = parent
            self.viewModel = viewModel
        }
        
        func mapViewDidChangeVisibleRegion(_ mapView: MKMapView) {
            let newRegion = mapView.region
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                viewModel.currentRegion = mapView.region
                    Task { await self.viewModel.reloadAnnotations() }
                
            }
        }
        
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            if let restaurantAnnotation = annotation as? Ios16CollectionItemAnnotation {
                let identifier = Ios16CollectionItemMapView.identifier
                var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? Ios16CollectionItemMapView
                if annotationView == nil {
                    annotationView = Ios16CollectionItemMapView(annotation: annotation, reuseIdentifier: identifier)
                } else {
                    annotationView?.annotation = annotation
                }
                return annotationView
            } else if let clusterAnnotation = annotation as? Ios16CollectionItemClusterAnnotation {
                let identifier = Ios16CollectionItemClusterAnnotationView.identifier
                var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? Ios16CollectionItemClusterAnnotationView
                if annotationView == nil {
                    annotationView = Ios16CollectionItemClusterAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                } else {
                    annotationView?.annotation = annotation
                }
                return annotationView
            }
            return nil
        }
        
        func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
            if let restaurantAnnotation = view.annotation as? Ios16CollectionItemAnnotation {
                mapView.deselectAnnotation(restaurantAnnotation, animated: false)
                DispatchQueue.main.async {
                    self.parent.selectedRestaurant = restaurantAnnotation.collectionItem
                }
            } else if let clusterAnnotation = view.annotation as? Ios16CollectionItemClusterAnnotation {
                mapView.deselectAnnotation(clusterAnnotation, animated: false)
                DispatchQueue.main.async {
                    self.parent.selectedCluster = clusterAnnotation
                }
            }
        }
    }
}
class Ios16CollectionItemMapView: MKAnnotationView {
    static let identifier = "Ios16CollectionItemMapView"
    
    private var hostingController: UIHostingController<Ios16CollectionItemAnnotationView>?
    
    override var annotation: MKAnnotation? {
        willSet {
            guard let clusterAnnotation = newValue as? Ios16CollectionItemAnnotation else { return }
            configure(with: clusterAnnotation)
        }
    }
    
    private func configure(with annotation: Ios16CollectionItemAnnotation) {
        //print("SHOULD BE CONFIGURING CLUSTER")
        canShowCallout = false
        self.subviews.forEach { $0.removeFromSuperview() }
        
        
        // Create the SwiftUI view
        let clusterCell = Ios16CollectionItemAnnotationView(item: annotation.collectionItem)
        
        // Embed the SwiftUI view into the annotation view
        let hostingController = UIHostingController(rootView: clusterCell)
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(hostingController.view)
        self.hostingController = hostingController
        
        // Constraints
        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: self.topAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            
        ])
    }
}
class Ios16CollectionItemClusterAnnotationView: MKAnnotationView {
    static let identifier = "Ios16CollectionItemClusterAnnotationView"
    
    private var hostingController: UIHostingController<Ios16CollectionItemClusterCell>?
    
    override var annotation: MKAnnotation? {
        willSet {
            guard let clusterAnnotation = newValue as? Ios16CollectionItemClusterAnnotation else { return }
            configure(with: clusterAnnotation)
        }
    }
    
    private func configure(with cluster: Ios16CollectionItemClusterAnnotation) {
        //print("SHOULD BE CONFIGURING CLUSTER")
        canShowCallout = false
        self.subviews.forEach { $0.removeFromSuperview() }
        
        // Determine the count
      
        
        // Create the SwiftUI view
        let clusterCell = Ios16CollectionItemClusterCell(cluster: cluster)
        
        // Embed the SwiftUI view into the annotation view
        let hostingController = UIHostingController(rootView: clusterCell)
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(hostingController.view)
        self.hostingController = hostingController
        
        // Constraints
        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: self.topAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            
        ])
    }
}

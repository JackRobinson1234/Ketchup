//
//  CollectionMapView.swift
//  Foodi
//
//  Created by Jack Robinson on 4/10/24.
//

import SwiftUI
import MapKit
import ClusterMap
import Kingfisher

//@available(iOS 17.0, *)
struct Ios16CollectionMapView: View {
    @ObservedObject var collectionsViewModel: CollectionsViewModel
    @StateObject private var viewModel = CollectionMapViewModel()
    @State private var selectedItem: CollectionItem?
    @State private var selectedCluster: CollectionItemClusterAnnotation?
    var body: some View {
        if let collection = collectionsViewModel.selectedCollection,
           !collectionsViewModel.items.isEmpty {
            GeometryReader { geometryProxy in
                CollectionKitMapView(viewModel: viewModel, selectedRestaurant: $selectedItem, selectedCluster: $selectedCluster,  mapSize: geometryProxy.size  )
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

class CollectionMapViewModel: ObservableObject {
    let clusterManager = ClusterManager<CollectionItemAnnotation>()
    @Published var items = [CollectionItem]()
    @Published var annotations: [CollectionItemAnnotation] = []
    @Published var clusters: [CollectionItemClusterAnnotation] = []
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
        let itemAnnotations: [CollectionItemAnnotation] = self.items.compactMap { item in
            guard let geoPoint = item.geoPoint else { return nil }
            let coordinate = CLLocationCoordinate2D(latitude: geoPoint.latitude, longitude: geoPoint.longitude)
            return CollectionItemAnnotation(coordinate: coordinate, collectionItem: item)
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
    
    private func applyChanges(_ difference: ClusterManager<CollectionItemAnnotation>.Difference) {
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
                    self.clusters.append(CollectionItemClusterAnnotation(
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

class CollectionItemAnnotation: NSObject, CoordinateIdentifiable, Identifiable, MKAnnotation {
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

class CollectionItemClusterAnnotation: NSObject, Identifiable, MKAnnotation, CoordinateIdentifiable {
    var id = UUID()
    var coordinate: CLLocationCoordinate2D
    var count: Int
    var memberAnnotations: [CollectionItemAnnotation]
    var title: String?

    init(id: UUID, coordinate: CLLocationCoordinate2D, count: Int, memberAnnotations: [CollectionItemAnnotation]) {
        self.id = id
        self.coordinate = coordinate
        self.count = count
        self.memberAnnotations = memberAnnotations
        self.title = "Cluster of \(count) Restaurants"
        super.init()
    }
}

struct CollectionItemAnnotationView: View {
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

struct CollectionItemClusterCell: View {
    var cluster: CollectionItemClusterAnnotation
    
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

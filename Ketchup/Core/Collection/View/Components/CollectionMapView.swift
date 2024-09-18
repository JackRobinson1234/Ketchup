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
//struct CollectionMapView: View {
//    @ObservedObject var collectionsViewModel: CollectionsViewModel
//    @StateObject private var viewModel = CollectionMapViewModel()
//    @State private var selectedItem: CollectionItem?
//    @State private var selectedCluster: CollectionItemClusterAnnotation?
//    var body: some View {
//        if let collection = collectionsViewModel.selectedCollection,
//           !collectionsViewModel.items.isEmpty {
//            Map(initialPosition: .region(viewModel.initialUSRegion)) {
//                ForEach(viewModel.annotations, id: \.self) { item in
//                    Annotation(item.name, coordinate: item.coordinate) {
//                        Button {
//                            selectedItem = item.collectionItem
//                        } label: {
//                            CollectionItemAnnotationView(item: item.collectionItem)
//                        }
//                    }
//                }
//                ForEach(viewModel.clusters) { cluster in
//                    Annotation("", coordinate: cluster.coordinate) {
//                        CollectionItemClusterCell(cluster: cluster)
//                            .onTapGesture {
//                                selectedCluster = cluster
//                            }
//                    }
//                }
//            }
//            .readSize(onChange: { newValue in
//                viewModel.mapSize = newValue
//            })
//            .onAppear {
//                viewModel.setItems(items: collectionsViewModel.items)
//            }
//            .onMapCameraChange { context in
//                viewModel.currentRegion = context.region
//            }
//            .onMapCameraChange(frequency: .onEnd) { _ in
//                Task.detached { await viewModel.reloadAnnotations() }
//            }
//            .mapStyle(.standard(pointsOfInterest: .excludingAll))
//            .frame(height: 500)
//            .cornerRadius(10)
//            .sheet(item: $selectedItem) { item in
//                NavigationStack {
//                    RestaurantProfileView(restaurantId: item.id)
//                }
//            }
//            .sheet(item: $selectedCluster){ cluster in
//                NavigationStack{
//                    ScrollView{
//                        ForEach(cluster.memberAnnotations, id: \.id) { item in
//                            NavigationLink(destination: RestaurantProfileView(restaurantId: item.collectionItem.id)) {
//                                CollectionItemCell(item: item.collectionItem, viewModel: collectionsViewModel)
//                            }
//                            .buttonStyle(PlainButtonStyle())
//                        }
//                    }
//                    .modifier(BackButtonModifier())
//                }
//            }
//        } else {
//            Text("No Restaurant locations Found")
//        }
//    }
//}
//
//class CollectionMapViewModel: ObservableObject {
//    let clusterManager = ClusterManager<CollectionItemAnnotation>()
//    @Published var items = [CollectionItem]()
//    @Published var annotations: [CollectionItemAnnotation] = []
//    @Published var clusters: [CollectionItemClusterAnnotation] = []
//    var mapSize: CGSize = .zero
//    let initialUSRegion = MKCoordinateRegion(
//        center: CLLocationCoordinate2D(latitude: 39.8283, longitude: -98.5795),
//        span: MKCoordinateSpan(latitudeDelta: 60, longitudeDelta: 60)
//    )
//    @Published var currentRegion: MKCoordinateRegion
//    
//    init() {
//        self.currentRegion = initialUSRegion
//    }
//    
//    func setItems(items: [CollectionItem]) {
//        annotations = []
//        clusters = []
//        self.items = items
//        let itemAnnotations: [CollectionItemAnnotation] = self.items.compactMap { item in
//            guard let geoPoint = item.geoPoint else { return nil }
//            let coordinate = CLLocationCoordinate2D(latitude: geoPoint.latitude, longitude: geoPoint.longitude)
//            return CollectionItemAnnotation(coordinate: coordinate, collectionItem: item)
//        }
//        
//        Task {
//            await clusterManager.add(itemAnnotations)
//            await reloadAnnotations()
//        }
//    }
//    
//    func reloadAnnotations() async {
//        let changes = await clusterManager.reload(mapViewSize: mapSize, coordinateRegion: currentRegion)
//        applyChanges(changes)
//    }
//    
//    private func applyChanges(_ difference: ClusterManager<CollectionItemAnnotation>.Difference) {
//        DispatchQueue.main.async {
//            for removal in difference.removals {
//                switch removal {
//                case .annotation(let annotation):
//                    self.annotations.removeAll { $0 == annotation }
//                case .cluster(let clusterAnnotation):
//                    self.clusters.removeAll { $0.id == clusterAnnotation.id }
//                }
//            }
//            for insertion in difference.insertions {
//                switch insertion {
//                case .annotation(let newItem):
//                    self.annotations.append(newItem)
//                case .cluster(let newItem):
//                    self.clusters.append(CollectionItemClusterAnnotation(
//                        id: newItem.id,
//                        coordinate: newItem.coordinate,
//                        count: newItem.memberAnnotations.count,
//                        memberAnnotations: newItem.memberAnnotations
//                    ))
//                }
//            }
//        }
//    }
//}
//
//struct CollectionItemAnnotation: CoordinateIdentifiable, Identifiable, Hashable, Equatable {
//    let id = UUID()
//    var coordinate: CLLocationCoordinate2D
//    var collectionItem: CollectionItem
//    
//    var name: String { collectionItem.name }
//}
//
//struct CollectionItemClusterAnnotation: Identifiable {
//    var id = UUID()
//    var coordinate: CLLocationCoordinate2D
//    var count: Int
//    var memberAnnotations: [CollectionItemAnnotation]
//}
//
//struct CollectionItemAnnotationView: View {
//    let item: CollectionItem
//    
//    var body: some View {
//        if let imageUrl = item.image {
//            KFImage(URL(string: imageUrl))
//                .resizable()
//                .scaledToFill()
//                .frame(width: 40, height: 40)
//                .clipShape(RoundedRectangle(cornerRadius: 6))
//                .overlay(
//                    RoundedRectangle(cornerRadius: 6)
//                        .stroke(Color.white, lineWidth: 2)
//                )
//        } else {
//            RoundedRectangle(cornerRadius: 6)
//                .fill(Color.blue)
//                .frame(width: 40, height: 40)
//                .overlay(
//                    RoundedRectangle(cornerRadius: 6)
//                        .stroke(Color.white, lineWidth: 2)
//                )
//        }
//    }
//}
//
//struct CollectionItemClusterCell: View {
//    var cluster: CollectionItemClusterAnnotation
//    
//    var body: some View {
//        ZStack {
//            Circle()
//                .fill(Color.white)
//                .frame(width: 20, height: 20)
//                .overlay(
//                    Circle()
//                        .stroke(Color("Colors/AccentColor"), lineWidth: 2)
//                )
//            Text("\(cluster.count)")
//                .foregroundColor(.black)
//                .font(.custom("MuseoSansRounded-300", size: 10))
//        }
//    }
//}

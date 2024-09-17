//
//  RestaurantProfileMapView.swift
//  Ketchup
//
//  Created by Jack Robinson on 9/17/24.
//

import SwiftUI
import _MapKit_SwiftUI
import ClusterMap
import Kingfisher

struct RestaurantClusterMapView: View {
    @StateObject private var viewModel: RestaurantMapViewModel
    @State private var selectedRestaurant: Restaurant?
    @State private var selectedCluster: RestaurantClusterAnnotation?

    init(restaurants: [Restaurant]) {
        _viewModel = StateObject(wrappedValue: RestaurantMapViewModel(restaurants: restaurants))
    }

    var body: some View {
        if !viewModel.restaurants.isEmpty {
            Map(initialPosition: .region(viewModel.initialUSRegion)) {
                ForEach(viewModel.annotations, id: \.self) { item in
                    Annotation(item.name, coordinate: item.coordinate) {
                        Button {
                            selectedRestaurant = item.restaurant
                        } label: {
                            RestaurantAnnotationView(restaurant: item.restaurant)
                        }
                    }
                }
                ForEach(viewModel.clusters) { cluster in
                    Annotation("", coordinate: cluster.coordinate) {
                        RestaurantClusterCell(cluster: cluster)
                            .onTapGesture {
                                selectedCluster = cluster
                            }
                    }
                }
            }
            .readSize(onChange: { newValue in
                viewModel.mapSize = newValue
            })
            .onAppear {
                viewModel.initializeAnnotations()
            }
            .onMapCameraChange { context in
                viewModel.currentRegion = context.region
            }
            .onMapCameraChange(frequency: .onEnd) { _ in
                Task.detached { await viewModel.reloadAnnotations() }
            }
            .mapStyle(.standard(pointsOfInterest: .excludingAll))
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
                                RestaurantMapCell(restaurant: item.restaurant)
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

class RestaurantMapViewModel: ObservableObject {
    let clusterManager = ClusterManager<RestaurantAnnotation>()
    @Published var restaurants: [Restaurant]
    @Published var annotations: [RestaurantAnnotation] = []
    @Published var clusters: [RestaurantClusterAnnotation] = []
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
        let restaurantAnnotations: [RestaurantAnnotation] = self.restaurants.compactMap { restaurant in
            guard let coordinates = restaurant.coordinates else { return nil }
            return RestaurantAnnotation(coordinate: coordinates, restaurant: restaurant)
        }

        Task {
            await clusterManager.add(restaurantAnnotations)
            await reloadAnnotations()
        }
    }

    func reloadAnnotations() async {
        let changes = await clusterManager.reload(mapViewSize: mapSize, coordinateRegion: currentRegion)
        applyChanges(changes)
    }

    private func applyChanges(_ difference: ClusterManager<RestaurantAnnotation>.Difference) {
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
                    self.clusters.append(RestaurantClusterAnnotation(
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


    struct RestaurantAnnotation: CoordinateIdentifiable, Identifiable, Hashable, Equatable {
        let id = UUID()
        var coordinate: CLLocationCoordinate2D
        var restaurant: Restaurant

        var name: String { restaurant.name }
    }

    struct RestaurantClusterAnnotation: Identifiable {
        var id = UUID()
        var coordinate: CLLocationCoordinate2D
        var count: Int
        var memberAnnotations: [RestaurantAnnotation]
    }

    struct RestaurantAnnotationView: View {
        let restaurant: Restaurant

        var body: some View {
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
        }
    }

    struct RestaurantClusterCell: View {
        var cluster: RestaurantClusterAnnotation

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

    struct RestaurantMapCell: View {
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

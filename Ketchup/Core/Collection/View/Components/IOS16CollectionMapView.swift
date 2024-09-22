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
struct CollectionKitMapView: UIViewRepresentable {
    @ObservedObject var viewModel: CollectionMapViewModel
    @Binding var selectedRestaurant: CollectionItem?
    @Binding var selectedCluster: CollectionItemClusterAnnotation?
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
        var parent: CollectionKitMapView
        var viewModel: CollectionMapViewModel
        
        
        init(_ parent: CollectionKitMapView, viewModel: CollectionMapViewModel) {
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
            if let restaurantAnnotation = annotation as? CollectionItemAnnotation {
                let identifier = CollectionItemMapView.identifier
                var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? CollectionItemMapView
                if annotationView == nil {
                    annotationView = CollectionItemMapView(annotation: annotation, reuseIdentifier: identifier)
                } else {
                    annotationView?.annotation = annotation
                }
                return annotationView
            } else if let clusterAnnotation = annotation as? CollectionItemClusterAnnotation {
                let identifier = CollectionItemClusterAnnotationView.identifier
                var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? CollectionItemClusterAnnotationView
                if annotationView == nil {
                    annotationView = CollectionItemClusterAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                } else {
                    annotationView?.annotation = annotation
                }
                return annotationView
            }
            return nil
        }
        
        func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
            if let restaurantAnnotation = view.annotation as? CollectionItemAnnotation {
                mapView.deselectAnnotation(restaurantAnnotation, animated: false)
                DispatchQueue.main.async {
                    self.parent.selectedRestaurant = restaurantAnnotation.collectionItem
                }
            } else if let clusterAnnotation = view.annotation as? CollectionItemClusterAnnotation {
                mapView.deselectAnnotation(clusterAnnotation, animated: false)
                DispatchQueue.main.async {
                    self.parent.selectedCluster = clusterAnnotation
                }
            }
        }
    }
}
class CollectionItemMapView: MKAnnotationView {
    static let identifier = "CollectionItemMapView"
    
    private var hostingController: UIHostingController<CollectionItemAnnotationView>?
    
    override var annotation: MKAnnotation? {
        willSet {
            guard let clusterAnnotation = newValue as? CollectionItemAnnotation else { return }
            configure(with: clusterAnnotation)
        }
    }
    
    private func configure(with annotation: CollectionItemAnnotation) {
        print("SHOULD BE CONFIGURING CLUSTER")
        canShowCallout = false
        self.subviews.forEach { $0.removeFromSuperview() }
        
        
        // Create the SwiftUI view
        let clusterCell = CollectionItemAnnotationView(item: annotation.collectionItem)
        
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
class CollectionItemClusterAnnotationView: MKAnnotationView {
    static let identifier = "CollectionItemClusterAnnotationView"
    
    private var hostingController: UIHostingController<CollectionItemClusterCell>?
    
    override var annotation: MKAnnotation? {
        willSet {
            guard let clusterAnnotation = newValue as? CollectionItemClusterAnnotation else { return }
            configure(with: clusterAnnotation)
        }
    }
    
    private func configure(with cluster: CollectionItemClusterAnnotation) {
        print("SHOULD BE CONFIGURING CLUSTER")
        canShowCallout = false
        self.subviews.forEach { $0.removeFromSuperview() }
        
        // Determine the count
      
        
        // Create the SwiftUI view
        let clusterCell = CollectionItemClusterCell(cluster: cluster)
        
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

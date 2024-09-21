//
//  MapRestaurantProfileView.swift
//  Foodi
//
//  Created by Jack Robinson on 2/1/24.
//

import SwiftUI
import MapKit
import Kingfisher

@available(iOS 17.0, *)
struct MapRestaurantProfileView: View {
    @ObservedObject var viewModel: RestaurantViewModel
    @Environment(\.dismiss) var dismiss
    @State private var route: MKRoute?
    @State private var travelInterval: TimeInterval?
    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var mapSelection: MKMapItem?
    @State private var isWithin50Miles: Bool = false
    
    var travelTime: String? {
        guard let travelInterval else { return nil }
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .full
        formatter.allowedUnits = [.hour, .minute]
        formatter.maximumUnitCount = 2
        return formatter.string(from: travelInterval)
    }
    
    var body: some View {
            NavigationStack {
                VStack {
                    if let restaurant = viewModel.restaurant, let coordinates = restaurant.coordinates {
                        ZStack(alignment: .topLeading) {
                            Map(position: $cameraPosition, selection: $mapSelection) {
                                Annotation(restaurant.name, coordinate: coordinates) {
                                    RestaurantCircularProfileImageView(imageUrl: restaurant.profileImageUrl, size: .medium)
                                }
                                .tag(MKMapItem(placemark: MKPlacemark(coordinate: coordinates)))
                                
                                UserAnnotation()
                                
                                if let route = route, isWithin50Miles {
                                    MapPolyline(route.polyline)
                                        .stroke(.blue, lineWidth: 6)
                                }
                            }
                            .mapStyle(.standard(pointsOfInterest: .excludingAll))
                            .frame(maxHeight: .infinity)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .onChange(of: mapSelection) { oldValue, newValue in
                                if isWithin50Miles {
                                    getDirections()
                                }
                            }
                            
                            Button(action: {
                                dismiss()
                            }) {
                                Image(systemName: "chevron.left")
                                    .foregroundColor(.white)
                                    .padding(6)
                                    .background(Color.gray.opacity(0.6))
                                    .clipShape(Circle())
                            }
                            .padding()
                            
                            if let travelTime = travelTime, isWithin50Miles {
                                VStack {
                                    HStack {
                                        Spacer()
                                        HStack(spacing: 0) {
                                            Image(systemName: "car")
                                                .foregroundStyle(.black)
                                            Text(" \(travelTime)")
                                                .foregroundStyle(.black)
                                        }
                                        .padding(8)
                                        .background(Color.white)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                        .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 2)
                                    }
                                    .padding()
                                    Spacer()
                                }
                            }
                            
                            VStack {
                                Spacer()
                                HStack {
                                    Spacer()
                                    Button(action: {
                                        if let coordinates = viewModel.restaurant?.coordinates {
                                            let url = URL(string: "maps://?saddr=&daddr=\(coordinates.latitude),\(coordinates.longitude)")
                                            if let url = url, UIApplication.shared.canOpenURL(url) {
                                                UIApplication.shared.open(url, options: [:], completionHandler: nil)
                                            }
                                        }
                                    }) {
                                        HStack(spacing: 0) {
                                            Text("Open in ")
                                                .foregroundStyle(.black)
                                            Image(systemName: "applelogo")
                                                .foregroundStyle(.black)
                                            Text(" Maps")
                                                .foregroundStyle(.black)
                                        }
                                        .padding(8)
                                        .background(Color.white)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                        .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 2)
                                    }
                                    Spacer()
                                }
                                .padding(.bottom, 25)
                            }
                        }
                        .onAppear {
                            checkDistanceAndSetRegion(coordinates: coordinates)
                        }
                    } else {
                        Text("No Location Found")
                    }
                }
                .navigationBarHidden(true)
                .ignoresSafeArea()
            }
        }
    
    private func checkDistanceAndSetRegion(coordinates: CLLocationCoordinate2D) {
        guard let userLocation = LocationManager.shared.userLocation else {
            setRegion(coordinates: coordinates)
            return
        }
        
        let userCoordinate = userLocation.coordinate
        let distance = CLLocation(latitude: userCoordinate.latitude, longitude: userCoordinate.longitude)
            .distance(from: CLLocation(latitude: coordinates.latitude, longitude: coordinates.longitude))
        
        isWithin50Miles = distance <= 80467.2 // 50 miles in meters
        
        if isWithin50Miles {
            setRegion(coordinates: coordinates)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                mapSelection = MKMapItem(placemark: MKPlacemark(coordinate: coordinates))
            }
        } else {
            setRegion(coordinates: coordinates, span: 0.5) // Wider span for distances over 50 miles
        }
    }
    
    private func setRegion(coordinates: CLLocationCoordinate2D, span: Double = 0.05) {
        cameraPosition = .region(MKCoordinateRegion(center: coordinates, span: MKCoordinateSpan(latitudeDelta: span, longitudeDelta: span)))
    }
    
    private func getDirections() {
        guard let restaurant = viewModel.restaurant,
              let coordinates = restaurant.coordinates,
              let userLocation = LocationManager.shared.userLocation else {
            return
        }
        
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: userLocation.coordinate))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: coordinates))
        request.transportType = .automobile
        
        Task {
            do {
                let result = try await MKDirections(request: request).calculate()
                route = result.routes.first
                travelInterval = result.routes.first?.expectedTravelTime
                
                if let rect = route?.polyline.boundingMapRect {
                    let margin: Double = 5000
                    let expandedRect = MKMapRect(
                        x: rect.origin.x - margin,
                        y: rect.origin.y - margin,
                        width: rect.size.width + (2 * margin),
                        height: rect.size.height + (2 * margin)
                    )
                    withAnimation {
                        cameraPosition = .rect(expandedRect)
                    }
                }
            } catch {
                //print("Error calculating directions: \(error.localizedDescription)")
            }
        }
    }
}
struct Ios16MapRestaurantProfileView: View {
    @ObservedObject var viewModel: RestaurantViewModel
    @Environment(\.dismiss) var dismiss
    @State private var route: MKRoute?
    @State private var travelInterval: TimeInterval?
    @State private var isWithin50Miles: Bool = false
    @State private var showAlert: Bool = false

    var travelTime: String? {
        guard let travelInterval else { return nil }
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .full
        formatter.allowedUnits = [.hour, .minute]
        formatter.maximumUnitCount = 2
        return formatter.string(from: travelInterval)
    }

    var body: some View {
        NavigationView {
            VStack {
                if let restaurant = viewModel.restaurant, let coordinates = restaurant.coordinates {
                    ZStack(alignment: .topLeading) {
                        Ios16RestaurantMapView(restaurantCoordinate: coordinates, route: $route)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .onAppear {
                                checkDistanceAndSetRegion(coordinates: coordinates)
                            }
                        // Back Button
                        Button(action: {
                            dismiss()
                        }) {
                            Image(systemName: "chevron.left")
                                .foregroundColor(.white)
                                .padding(6)
                                .background(Color.gray.opacity(0.6))
                                .clipShape(Circle())
                        }
                        .padding()
                        // Travel Time Display
                        if let travelTime = travelTime, isWithin50Miles {
                            VStack {
                                HStack {
                                    Spacer()
                                    HStack(spacing: 0) {
                                        Image(systemName: "car")
                                            .foregroundColor(.black)
                                        Text(" \(travelTime)")
                                            .foregroundColor(.black)
                                    }
                                    .padding(8)
                                    .background(Color.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                    .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 2)
                                }
                                .padding()
                                Spacer()
                            }
                        }
                        // Open in Maps Button
                        VStack {
                            Spacer()
                            HStack {
                                Spacer()
                                Button(action: {
                                    if let coordinates = viewModel.restaurant?.coordinates {
                                        let url = URL(string: "maps://?saddr=&daddr=\(coordinates.latitude),\(coordinates.longitude)")
                                        if let url = url, UIApplication.shared.canOpenURL(url) {
                                            UIApplication.shared.open(url, options: [:], completionHandler: nil)
                                        }
                                    }
                                }) {
                                    HStack(spacing: 0) {
                                        Text("Open in ")
                                            .foregroundColor(.black)
                                        Image(systemName: "applelogo")
                                            .foregroundColor(.black)
                                        Text(" Maps")
                                            .foregroundColor(.black)
                                    }
                                    .padding(8)
                                    .background(Color.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                    .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 2)
                                }
                                Spacer()
                            }
                            .padding(.bottom, 25)
                        }
                    }
                } else {
                    Text("No Location Found")
                }
            }
            .navigationBarHidden(true)
            .ignoresSafeArea()
        }
    }

    private func checkDistanceAndSetRegion(coordinates: CLLocationCoordinate2D) {
        guard let userLocation = LocationManager.shared.userLocation else {
            // No user location, cannot calculate distance
            return
        }

        let userCoordinate = userLocation.coordinate
        let distance = CLLocation(latitude: userCoordinate.latitude, longitude: userCoordinate.longitude)
            .distance(from: CLLocation(latitude: coordinates.latitude, longitude: coordinates.longitude))

        isWithin50Miles = distance <= 80467.2 // 50 miles in meters

        if isWithin50Miles {
            getDirections()
        }
    }

    private func getDirections() {
        guard let restaurant = viewModel.restaurant,
              let coordinates = restaurant.coordinates,
              let userLocation = LocationManager.shared.userLocation else {
            return
        }

        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: userLocation.coordinate))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: coordinates))
        request.transportType = .automobile

        let directions = MKDirections(request: request)
        directions.calculate { response, error in
            if let error = error {
                // Handle error
                print("Error calculating directions: \(error.localizedDescription)")
                return
            }
            if let route = response?.routes.first {
                self.route = route
                self.travelInterval = route.expectedTravelTime
            }
        }
    }
}
struct Ios16RestaurantMapView: UIViewRepresentable {
    var restaurantCoordinate: CLLocationCoordinate2D
    @Binding var route: MKRoute?

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator

        // Configure map view
        mapView.mapType = .standard
        if #available(iOS 13.0, *) {
            mapView.pointOfInterestFilter = .excludingAll
        }
        mapView.showsUserLocation = true
        mapView.userTrackingMode = .none

        // Add restaurant annotation
        let restaurantAnnotation = MKPointAnnotation()
        restaurantAnnotation.coordinate = restaurantCoordinate
        mapView.addAnnotation(restaurantAnnotation)

        // Set initial region
        let region = MKCoordinateRegion(center: restaurantCoordinate, span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05))
        mapView.setRegion(region, animated: false)

        return mapView
    }

    func updateUIView(_ mapView: MKMapView, context: Context) {
        // Update the route overlay if route is available
        mapView.removeOverlays(mapView.overlays)
        if let route = route {
            mapView.addOverlay(route.polyline)
            // Adjust the map region to fit the route
            let rect = route.polyline.boundingMapRect
            let edgeInsets = UIEdgeInsets(top: 50, left: 50, bottom: 50, right: 50)
            mapView.setVisibleMapRect(rect, edgePadding: edgeInsets, animated: true)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: Ios16RestaurantMapView

        init(_ parent: Ios16RestaurantMapView) {
            self.parent = parent
        }

        // Render the route polyline
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if overlay is MKPolyline {
                let renderer = MKPolylineRenderer(overlay: overlay)
                renderer.strokeColor = .blue
                renderer.lineWidth = 4.0
                return renderer
            }
            return MKOverlayRenderer(overlay: overlay)
        }

        // Customize annotation views
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            if annotation is MKUserLocation {
                // Use default user location view
                return nil
            } else {
                let identifier = "RestaurantAnnotation"
                var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
                if annotationView == nil {
                    annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                    annotationView?.canShowCallout = true
                } else {
                    annotationView?.annotation = annotation
                }
                return annotationView
            }
        }
    }
}

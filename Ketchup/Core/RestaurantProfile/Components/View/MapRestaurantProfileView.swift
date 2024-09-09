//
//  MapRestaurantProfileView.swift
//  Foodi
//
//  Created by Jack Robinson on 2/1/24.
//

import SwiftUI
import MapKit
import Kingfisher

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

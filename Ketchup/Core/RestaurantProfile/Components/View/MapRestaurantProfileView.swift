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
    @State var showRoute = false
    @Binding var route: MKRoute?
    @Binding var travelInterval: TimeInterval?
    @State var cameraPosition: MapCameraPosition = .automatic
    var travelTime: String? {
        guard let travelInterval else { return nil}
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
                        Map(position: $cameraPosition) {
                            Annotation(restaurant.name, coordinate: coordinates) {
                                RestaurantCircularProfileImageView(imageUrl: restaurant.profileImageUrl, size: .medium)
                            }
                            UserAnnotation()
                            if let route = route {
                                MapPolyline(route.polyline)
                                    .stroke(.blue, lineWidth: 6)
                            }
                        }
                        .mapStyle(.standard(elevation: .realistic))
                        .frame(maxHeight: .infinity)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        
                        Button(action: {
                            dismiss()
                        }) {
                            Image(systemName: "chevron.left")
                                .foregroundColor(.white)
                                .padding(6)
                                .background(Color.black.opacity(0.6))
                                .clipShape(Circle())
                        }
                        .padding()
                            if let travelTime = travelTime {
                                    HStack {
                                        Spacer()
                                        HStack(spacing: 0){
                                            Image(systemName: "car")
                                            Text(" \(travelTime)")
                                        }
                                            .foregroundColor(.black)
                                            .padding(8)
                                            .background(Color.white)
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                        
                                    }
                                    .padding()
    
                            
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
                                    HStack (spacing: 0) {
                                        Text("Open in ")
                                        Image(systemName: "applelogo")
                                        Text(" Maps")
                                        
                                    }
                                    .foregroundColor(.black)
                                    .padding(8)
                                    .background(Color.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                                Spacer()
                            }
                            .padding(.bottom, 25)
                        }
                    }
                    .onAppear {
                        if let rect = route?.polyline.boundingMapRect {
                            let margin: Double = 5000 // Adjust this margin value as needed
                            let expandedRect = MKMapRect(
                                x: rect.origin.x - margin,
                                y: rect.origin.y - margin,
                                width: rect.size.width + (2 * margin),
                                height: rect.size.height + (2 * margin)
                            )
                            cameraPosition = .rect(expandedRect)
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
}

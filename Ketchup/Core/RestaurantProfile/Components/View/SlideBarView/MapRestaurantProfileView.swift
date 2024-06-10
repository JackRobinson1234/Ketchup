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
                                    Text("Open in Maps")
                                        .foregroundColor(.white)
                                        .padding()
                                        .background(Color.black.opacity(0.6))
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                }
                                Spacer()
                            }
                        }
                    }
                    .onAppear {
                                            if let rect = route?.polyline.boundingMapRect {
                                                cameraPosition = .rect(rect)
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

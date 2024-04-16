//
//  CollectionMapView.swift
//  Foodi
//
//  Created by Jack Robinson on 4/10/24.
//

import SwiftUI
import MapKit
struct CollectionMapView: View {
    var collection: Collection
    var body: some View {
        if let items = collection.items {
        Map(initialPosition: .automatic) {
            ForEach(items, id: \.self) { item in
                if let geoPoint = item.geoPoint {
                       let lat = geoPoint.latitude
                       let long = geoPoint.longitude
                        if let image = item.image {
                            Annotation(item.name, coordinate: CLLocationCoordinate2D(latitude: lat, longitude: long)) {
                                RestaurantCircularProfileImageView(imageUrl: image, size: .medium)
                            }
                        } else{
                            Annotation(item.name, coordinate: CLLocationCoordinate2D(latitude: lat, longitude: long)) {
                                Circle()
                                    .foregroundStyle(.blue)
                            }
                        }
                    }
                }
            }
        } else {
            Text("No Restaurant locations Found")
        }
    }
}
#Preview {
    CollectionMapView(collection: DeveloperPreview.collections[0])
}

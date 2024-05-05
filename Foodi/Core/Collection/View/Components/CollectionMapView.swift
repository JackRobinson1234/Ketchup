//
//  CollectionMapView.swift
//  Foodi
//
//  Created by Jack Robinson on 4/10/24.
//

import SwiftUI
import MapKit
struct CollectionMapView: View {
    @ObservedObject var collectionsViewModel: CollectionsViewModel
    var body: some View {
        if collectionsViewModel.selectedCollection != nil {
        let items = collectionsViewModel.items
        let _ = print(items)
        Map(initialPosition: .automatic) {
            ForEach(items, id: \.self) { item in
                if let geoPoint = item.geoPoint {
                       let lat = geoPoint.latitude
                       let long = geoPoint.longitude
                    if let image = item.image {
                            Annotation(item.name, coordinate: CLLocationCoordinate2D(latitude: lat, longitude: long)) {
                                NavigationLink(destination: RestaurantProfileView(restaurantId: item.id)) {
                                    RestaurantCircularProfileImageView(imageUrl: image, size: .medium)
                                }
                            }
                        } else{
                            Annotation(item.name, coordinate: CLLocationCoordinate2D(latitude: lat, longitude: long)) {
                                NavigationLink(destination: RestaurantProfileView(restaurantId: item.id)) {
                                    Circle()
                                        .foregroundStyle(.blue)
                                }
                            }
                        }
                    }
                }
            }
        .frame(height: 500)
        .cornerRadius(10)

        } else {
            Text("No Restaurant locations Found")
        }
    }
}
#Preview {
    CollectionMapView(collectionsViewModel: CollectionsViewModel(user: DeveloperPreview.user))
}

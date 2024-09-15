//
//  RestaurantListView.swift
//  Foodi
//
//  Created by Jack Robinson on 2/1/24.
//

import SwiftUI
import InstantSearchSwiftUI
import MapKit

struct RestaurantListView: View {
    @ObservedObject var viewModel: SearchViewModel
    @Environment(\.dismiss) var dismiss
    @State private var userLocation: CLLocation? = LocationManager.shared.userLocation
    
    var debouncer = Debouncer(delay: 1.0)
    var body: some View {
        VStack{
            InfiniteList(viewModel.restaurantHits, itemView: { hit in
                NavigationLink(value: hit.object) {
                    RestaurantCell(restaurant: hit.object)
                        .padding(.horizontal)
                }
                Divider()
            }, noResults: {
                Text("No results found")
                    .foregroundStyle(.black)
            })
        }
       
    }
}

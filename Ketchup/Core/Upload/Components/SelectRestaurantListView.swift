//
//  SelectRestaurantListView.swift
//  Foodi
//
//  Created by Jack Robinson on 5/14/24.
//

import SwiftUI
import InstantSearchSwiftUI
import FirebaseFirestoreInternal

struct SelectRestaurantListView: View {
    @StateObject var viewModel = RestaurantListViewModel()
    @ObservedObject var uploadViewModel: UploadViewModel
    @Environment(\.dismiss) var dismiss
    var debouncer = Debouncer(delay: 1.0)
    
    var body: some View {
        InfiniteList(viewModel.hits, itemView: { hit in
            Button{
                uploadViewModel.restaurant = hit.object
                let restaurant = hit.object
                    if let geopoint = restaurant.geoPoint{
                        uploadViewModel.restaurant?.geoPoint = geopoint
                    } else if let geoLoc = restaurant._geoloc {
                        uploadViewModel.restaurant?.geoPoint = GeoPoint(latitude: geoLoc.lat, longitude: geoLoc.lng)
                    }
                
                dismiss()
            } label: {
                RestaurantCell(restaurant: hit.object)
                    .padding()
            }
            Divider()
        }, noResults: {
            Text("No results found")
        })
        .navigationTitle("Explore")
        .searchable(text: $viewModel.searchQuery,
                    prompt: "Search")
        .onChange(of: viewModel.searchQuery) {
            debouncer.schedule {
                viewModel.notifyQueryChanged()
            }
        }
        
    }
}


#Preview {
    RestaurantListView()
}

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
    @State var createRestaurantView = false
    @State var dismissRestaurantList = false
    var debouncer = Debouncer(delay: 1.0)
    
    
    var body: some View {
        Button{
            createRestaurantView.toggle()
        } label: {
            VStack{
                Text("Can't find the restaurant you're looking for?")
                    .foregroundStyle(.gray)
                    .font(.custom("MuseoSansRounded-300", size: 10))
                Text("Request a Restaurant")
                    .foregroundStyle(Color("Colors/AccentColor"))
                    .font(.custom("MuseoSansRounded-300", size: 10))
            }
        }
        InfiniteList(viewModel.hits, itemView: { hit in
            Button{
                uploadViewModel.restaurant = hit.object
                uploadViewModel.restaurantRequest = nil
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
           Text("No Results Found")
        })
        .navigationTitle("Select Restaurant")
        .searchable(text: $viewModel.searchQuery,
                    prompt: "Search")
        .onChange(of: viewModel.searchQuery) {
            debouncer.schedule {
                viewModel.notifyQueryChanged()
            }
        }
        .fullScreenCover(isPresented: $createRestaurantView) {
            AddRestaurantView(uploadViewModel: uploadViewModel, dismissRestaurantList: $dismissRestaurantList)
                .onDisappear{
                        print("APPEARED")
                        if dismissRestaurantList{
                          print("APPEARED- dismissing")
                            dismiss()
                            dismissRestaurantList = false
                        }
                    
                }
        }
    }
}


//#Preview {
//    RestaurantListView()
//}

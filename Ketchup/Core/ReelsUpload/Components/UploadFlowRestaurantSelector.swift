//
//  UploadFlowRestaurantSelector.swift
//  Ketchup
//
//  Created by Jack Robinson on 7/29/24.
//

import SwiftUI
import InstantSearchSwiftUI
import FirebaseFirestoreInternal

struct UploadFlowRestaurantSelector: View {
    @StateObject var viewModel = RestaurantListViewModel()
    @ObservedObject var uploadViewModel: UploadViewModel
    @ObservedObject var cameraViewModel: CameraViewModel
    @Environment(\.dismiss) var dismiss
    @State var createRestaurantView = false
    @State var dismissRestaurantList = false
    @State var navigateToCamera = false
    
    var debouncer = Debouncer(delay: 1.0)
    let isEditingRestaurant: Bool
    
    init(uploadViewModel: UploadViewModel, cameraViewModel: CameraViewModel, isEditingRestaurant: Bool = false) {
        self.uploadViewModel = uploadViewModel
        self.cameraViewModel = cameraViewModel
        self.isEditingRestaurant = isEditingRestaurant
    }
    
    var body: some View {
        NavigationStack{
            VStack {
                Button {
                    createRestaurantView.toggle()
                } label: {
                    VStack {
                        Text("Can't find the restaurant you're looking for?")
                            .foregroundStyle(.gray)
                            .font(.custom("MuseoSansRounded-300", size: 10))
                        Text("Request a Restaurant")
                            .foregroundStyle(Color("Colors/AccentColor"))
                            .font(.custom("MuseoSansRounded-300", size: 10))
                    }
                }
                
                InfiniteList(viewModel.hits, itemView: { hit in
                    Button {
                        uploadViewModel.restaurant = hit.object
                        uploadViewModel.restaurantRequest = nil
                        let restaurant = hit.object
                        if let geopoint = restaurant.geoPoint {
                            uploadViewModel.restaurant?.geoPoint = geopoint
                        } else if let geoLoc = restaurant._geoloc {
                            uploadViewModel.restaurant?.geoPoint = GeoPoint(latitude: geoLoc.lat, longitude: geoLoc.lng)
                        }
                        
                        if isEditingRestaurant {
                            dismiss()
                        } else {
                            navigateToCamera = true
                        }
                    } label: {
                        RestaurantCell(restaurant: hit.object)
                            .padding()
                    }
                    Divider()
                }, noResults: {
                    Text("No Results Found")
                })
            }
            .navigationTitle(isEditingRestaurant ? "Edit Restaurant" : "Select Restaurant")
            .searchable(text: $viewModel.searchQuery, prompt: "Search")
            .onChange(of: viewModel.searchQuery) {
                debouncer.schedule {
                    viewModel.notifyQueryChanged()
                }
            }
            .fullScreenCover(isPresented: $createRestaurantView) {
                AddRestaurantView(uploadViewModel: uploadViewModel, dismissRestaurantList: $dismissRestaurantList)
                    .onDisappear {
                        if dismissRestaurantList {
                            if isEditingRestaurant {
                                dismiss()
                            } else {
                                navigateToCamera = true
                            }
                            dismissRestaurantList = false
                        }
                    }
            }
            .fullScreenCover(isPresented: $navigateToCamera) {
                CameraView(cameraViewModel: cameraViewModel, uploadViewModel: uploadViewModel)
            }
        }
    }
}


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
    @StateObject var viewModel: SearchViewModel
    @ObservedObject var uploadViewModel: UploadViewModel
    @ObservedObject var cameraViewModel: CameraViewModel
    @Environment(\.dismiss) var dismiss
    @State var createRestaurantView = false
    @State var dismissRestaurantList = false
    @State var navigateToCamera = false
    @EnvironmentObject var tabBarController: TabBarController
    
    @State var dragDirection = "left"
    @State var isDragging = false
    @State var inSearchView = false
    @State private var isLocationSearchActive = false
    @FocusState private var isSearchFocused: Bool
    
    var debouncer = Debouncer(delay: 1.0)
    let isEditingRestaurant: Bool
    
    init(uploadViewModel: UploadViewModel, cameraViewModel: CameraViewModel, isEditingRestaurant: Bool = false) {
        self.uploadViewModel = uploadViewModel
        self.cameraViewModel = cameraViewModel
        self.isEditingRestaurant = isEditingRestaurant
        let initialSearchConfig = SearchModelConfig.restaurants
        _viewModel = StateObject(wrappedValue: SearchViewModel(initialSearchConfig: initialSearchConfig))
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Custom Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    ZStack(alignment: .leading) {
                        TextField("", text: $viewModel.searchQuery)
                            .focused($isSearchFocused)
                            .onTapGesture {
                                if isLocationSearchActive {
                                    isLocationSearchActive = false
                                    inSearchView = false
                                    viewModel.clearLocationSearchTerm()
                                }
                            }
                            .submitLabel(.done)
                            .onSubmit {
                                dismissKeyboard()
                            }
                        if viewModel.searchQuery.isEmpty {
                            Text("Search")
                                .font(.custom("MuseoSansRounded-500", size: 16))
                                .foregroundStyle(.gray)
                        }
                    }
                    if !viewModel.searchQuery.isEmpty {
                        Button(action: {
                            viewModel.searchQuery = ""
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    isSearchFocused = true
                }
                .padding(8)
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding(.horizontal)
                .padding(.top, 8)
                .padding(.bottom, 2)
                
                VStack(spacing: 0) {
                    RestaurantLocationSearchView(inSearchView: $inSearchView, isLocationSearchActive: $isLocationSearchActive, searchViewModel: viewModel)
                    
                    if !isLocationSearchActive {
                        Button {
                            createRestaurantView.toggle()
                        } label: {
                            VStack {
                                Text("Can't find the restaurant you're looking for?")
                                    .foregroundStyle(.gray)
                                    .font(.custom("MuseoSansRounded-300", size: 12))
                                Text("Add a New Restaurant")
                                    .foregroundStyle(Color("Colors/AccentColor"))
                                    .font(.custom("MuseoSansRounded-300", size: 12))
                            }
                            .padding(.top, 5)
                        }
                        
                        InfiniteList(viewModel.restaurantHits, itemView: { hit in
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
                    } else {
                        Spacer()
                    }
                }
            }
            .navigationTitle(isEditingRestaurant ? "Edit Restaurant" : "Choose a Restaurant To Review")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        if isEditingRestaurant {
                            dismiss()
                        } else {
                            uploadViewModel.reset()
                            cameraViewModel.reset()
                            tabBarController.selectedTab = 0
                        }
                    }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.black)
                    }
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
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    dismissKeyboard()
                }
            }
        }
        .onChange(of: viewModel.searchQuery) {
            debouncer.schedule {
                viewModel.notifyQueryChanged()
            }
        }
        .onAppear {
            isSearchFocused = true
            Debouncer(delay: 0.3).schedule {
                viewModel.notifyQueryChanged()
            }
        }
    }
    
    private func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}


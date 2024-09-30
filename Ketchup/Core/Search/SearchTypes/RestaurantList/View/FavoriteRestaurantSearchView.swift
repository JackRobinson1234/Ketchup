//
//  FavoriteRestaurantSearchView.swift
//  Foodi
//
//  Created by Jack Robinson on 2/21/24.
//

import SwiftUI
import InstantSearchSwiftUI

struct FavoriteRestaurantSearchView: View {
    @StateObject var viewModel: SearchViewModel
    @Binding var oldSelection: FavoriteRestaurant
    @Environment(\.dismiss) var dismiss
    @ObservedObject var editProfileViewModel: EditProfileViewModel
    
    @State var dragDirection = "left"
    @State var isDragging = false
    @State var inSearchView = false
    @State private var isLocationSearchActive = false
    @FocusState private var isSearchFocused: Bool
    
    var debouncer = Debouncer(delay: 1.0)
    
    init(oldSelection: Binding<FavoriteRestaurant>, editProfileViewModel: EditProfileViewModel) {
        self._oldSelection = oldSelection
        self.editProfileViewModel = editProfileViewModel
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
                        InfiniteList(viewModel.restaurantHits, itemView: { hit in
                            if !editProfileViewModel.favoritesPreview.contains(where: { $0.id == hit.object.id }) {
                                Button {
                                    let restaurant = hit.object
                                    let name = restaurant.name
                                    let id = restaurant.id
                                    let restaurantProfileImageUrl = restaurant.profileImageUrl ?? ""
                                    let newSelection = FavoriteRestaurant(name: name, id: id, restaurantProfileImageUrl: restaurantProfileImageUrl)
                                    if let index = editProfileViewModel.favoritesPreview.firstIndex(of: oldSelection) {
                                        editProfileViewModel.favoritesPreview[index] = newSelection
                                        dismiss()
                                    }
                                } label: {
                                    RestaurantCell(restaurant: hit.object)
                                        .padding()
                                }
                                Divider()
                            }
                        }, noResults: {
                            Text("No results found")
                        })
                    } else {
                        Spacer()
                    }
                }
            }
            .navigationTitle("Select a Favorite")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .tabBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Text("Cancel")
                    }
                }
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
        .onChange(of: viewModel.searchQuery) {newValue in
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

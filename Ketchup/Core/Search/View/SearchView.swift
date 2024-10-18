//
//  SearchView.swift
//  Foodi
//
//  Created by Jack Robinson on 2/1/24.
//

import SwiftUI

struct SearchView: View {
    var debouncer = Debouncer(delay: 1.0)
    @Environment(\.dismiss) var dismiss
    @StateObject var viewModel: SearchViewModel
    @State var dragDirection = "left"
    @State var isDragging = false
    @State var inSearchView = false
    @State private var isLocationSearchActive = false
    @FocusState private var isSearchFocused: Bool
    
    init(initialSearchConfig: SearchModelConfig) {
        _viewModel = StateObject(wrappedValue: SearchViewModel(initialSearchConfig: initialSearchConfig))
    }
    
    var drag: some Gesture {
        DragGesture(minimumDistance: 5)
            .onChanged { _ in self.isDragging = true }
            .onEnded { endedGesture in
                if (endedGesture.location.x - endedGesture.startLocation.x) > 0 {
                    self.dragDirection = "left"
                    if viewModel.searchConfig == .restaurants {
                        dismiss()
                    } else if viewModel.searchConfig == .users {
                        viewModel.searchConfig = .restaurants
                    } else if viewModel.searchConfig == .collections {
                        viewModel.searchConfig = .users
                    }
                } else {
                    self.dragDirection = "right"
                    if viewModel.searchConfig == .restaurants {
                        viewModel.searchConfig = .users
                    } else if viewModel.searchConfig == .users {
                        viewModel.searchConfig = .collections
                    }
                    self.isDragging = false
                }
            }
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
                        if viewModel.searchQuery.isEmpty{
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
                .contentShape(Rectangle()) // Makes the entire HStack area tappable
                .onTapGesture {
                    isSearchFocused = true // Focuses the TextField
                }
                
                .padding(8)
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding(.horizontal)
                .padding(.top, 8)
                .padding(.bottom, 2)
                
                switch viewModel.searchConfig {
                case .users:
                    VStack(spacing: 0) {
                        SearchViewSlideBar(viewModel: viewModel)
                        UserListView(viewModel: viewModel)
                    }
                case .restaurants:
                    VStack(spacing: 0) {
                        RestaurantLocationSearchView(inSearchView: $inSearchView, isLocationSearchActive: $isLocationSearchActive, searchViewModel: viewModel)
                        
                        if !isLocationSearchActive {
                            VStack(spacing: 0) {
                                SearchViewSlideBar(viewModel: viewModel)
                                    .padding(.bottom, 4)
                                RestaurantListView(viewModel: viewModel)
                            }
                        } else {
                            Spacer()
                        }
                    }
                case .collections:
                    VStack(spacing: 0) {
                        SearchViewSlideBar(viewModel: viewModel)
                        CollectionsSearchListView(viewModel: viewModel)
                    }
                }
            }
            .navigationBarBackButtonHidden()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Image("KetchupTextRed")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100)
                
                }
            }
            
            .navigationDestination(for: User.self) { user in
                ProfileView(uid: user.id)
            }
            .navigationDestination(for: Restaurant.self) { restaurant in
                RestaurantProfileView(restaurantId: restaurant.id)
            }
            .gesture(drag)
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
        .onChange(of: viewModel.searchConfig) {newValue in
            viewModel.notifyQueryChanged()
        }
        .onAppear {
            isSearchFocused = true
            Debouncer(delay: 0.3).schedule {
                viewModel.notifyQueryChanged()
            }
        }
        
    }
}
struct KeyboardDoneButtonModifier: ViewModifier {
    @FocusState private var isFocused: Bool
    
    func body(content: Content) -> some View {
        content
            .focused($isFocused)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        isFocused = false
                    }
                }
            }
    }
}

extension View {
    func addDoneButton() -> some View {
        self.modifier(KeyboardDoneButtonModifier())
    }
}

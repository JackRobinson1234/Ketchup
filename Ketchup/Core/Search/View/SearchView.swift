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
    @State var searchText: String = ""
    @StateObject var viewModel = SearchViewModel()
    @State var dragDirection = "left"
    @State var isDragging = false
    var drag: some Gesture {
        DragGesture(minimumDistance: 5)
            .onChanged { _ in self.isDragging = true
                print("DRAGGING ")}
            .onEnded { endedGesture in
                if (endedGesture.location.x - endedGesture.startLocation.x) > 0 {
                    self.dragDirection = "left"
                    //                    if !searchSlideBar {
                    //                        dismiss()
                    //                    } else {
                    if viewModel.searchConfig == .restaurants {
                        dismiss()
                    } else if viewModel.searchConfig == .users{
                        viewModel.searchConfig = .restaurants
                        
                    } else if viewModel.searchConfig == .collections{
                        viewModel.searchConfig = .users
                    }
                }
                else {
                    
                    self.dragDirection = "right"
                    if viewModel.searchConfig == .restaurants {
                        viewModel.searchConfig = .users
                    } else if viewModel.searchConfig == .users{
                        viewModel.searchConfig = .collections
                    }
                    self.isDragging = false
                }
                
            }
    }
    var body: some View {
        
        // Conditionally embed in NavigationStack only when searchSlideBar is true
        
        VStack{
            switch viewModel.searchConfig {
                
            case .users:
                NavigationStack{
                    VStack {
                        SearchViewSlideBar(viewModel: viewModel)
                        UserListView(viewModel: viewModel)
                    }
                    .modifier(BackButtonModifier())
                    .navigationBarBackButtonHidden()
                    .navigationTitle("Search")
                    .navigationBarTitleDisplayMode(.large)
                    .navigationDestination(for: User.self) { user in
                        ProfileView(uid: user.id)
                    }
                    .navigationDestination(for: Restaurant.self) { restaurant in
                        RestaurantProfileView(restaurantId: restaurant.id)
                    }
                    .gesture(drag)
                    .searchable(text: $viewModel.searchQuery, prompt: "Search")
                }
                
            case .restaurants:
                NavigationStack{
                    VStack {
                        SearchViewSlideBar(viewModel: viewModel)
                        RestaurantListView(viewModel: viewModel)
                    }
                    .modifier(BackButtonModifier())
                    .navigationBarBackButtonHidden()
                    .navigationTitle("Search")
                    
                   
                    .navigationBarTitleDisplayMode(.large)
                    
                    .navigationDestination(for: User.self) { user in
                        ProfileView(uid: user.id)
                    }
                    
                    .navigationDestination(for: Restaurant.self) { restaurant in
                        RestaurantProfileView(restaurantId: restaurant.id)
                    }
                    .gesture(drag)
                    .searchable(text: $viewModel.searchQuery, prompt: "Search")
                }
                
            case .collections:
                NavigationStack{
                    VStack {
                        SearchViewSlideBar(viewModel: viewModel)
                        CollectionsSearchListView(viewModel: viewModel)
                    }
                    .modifier(BackButtonModifier())
                    .navigationBarBackButtonHidden()
                    .navigationTitle("Search")
                    
                   
                    .navigationBarTitleDisplayMode(.large)
                    
                    .navigationDestination(for: User.self) { user in
                        ProfileView(uid: user.id)
                    }
                    
                    .navigationDestination(for: Restaurant.self) { restaurant in
                        RestaurantProfileView(restaurantId: restaurant.id)
                    }
                    .gesture(drag)
                    .searchable(text: $viewModel.searchQuery, prompt: "Search")
                }
            }
        }
        .onChange(of: viewModel.searchQuery) {
            debouncer.schedule {
                viewModel.notifyQueryChanged()
            }
        }
        .onChange(of: viewModel.searchConfig) {
            viewModel.notifyQueryChanged()
        }
    }
        
}

//struct SearchView_Previews: PreviewProvider {
//    static var previews: some View {
//        SearchView(viewModel.searchConfig: .restaurants)
//    }
//}



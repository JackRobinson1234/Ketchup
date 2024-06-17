//
//  SearchView.swift
//  Foodi
//
//  Created by Jack Robinson on 2/1/24.
//

import SwiftUI


struct SearchView: View {
    @Environment(\.dismiss) var dismiss
    @State var searchText: String = ""
    @State var searchSlideBar: Bool
    @State var searchConfig: SearchModelConfig
    
    init(searchConfig: SearchModelConfig, searchSlideBar: Bool = false) {
        self._searchConfig = State(initialValue: searchConfig)
        self._searchSlideBar = State(initialValue: searchSlideBar)
    }
    @State var dragDirection = "left"
    @State var isDragging = false
    var drag: some Gesture {
        DragGesture(minimumDistance: 30)
            .onChanged { _ in self.isDragging = true
            print("DRAGGING ")}
            .onEnded { endedGesture in
                if (endedGesture.location.x - endedGesture.startLocation.x) > 0 {
                    self.dragDirection = "left"
//                    if !searchSlideBar {
//                        dismiss()
//                    } else {
                        if searchConfig == .restaurants {
                            dismiss()
                        } else if searchConfig == .posts{
                            searchConfig = .restaurants
                        } else if searchConfig == .users{
                            searchConfig = .posts
                        } else if searchConfig == .collections{
                            searchConfig = .users
                        }
                    }
                 else {

                        self.dragDirection = "right"
                        if searchConfig == .restaurants {
                            searchConfig = .posts
                        } else if searchConfig == .posts{
                            searchConfig = .users
                        } else if searchConfig == .users{
                            searchConfig = .collections
                        }
                        self.isDragging = false
                    }
                
            }
    }
    var body: some View {
        // Conditionally embed in NavigationStack only when searchSlideBar is true

        if searchSlideBar {
            NavigationStack {
                internalBody
                    .navigationDestination(for: User.self) { user in
                        ProfileView(uid: user.id)
                    }
                    .navigationDestination(for: SearchModelConfig.self) { config in
                        SearchView(searchConfig: config)}
                    .navigationDestination(for: Restaurant.self) { restaurant in
                        RestaurantProfileView(restaurantId: restaurant.id)
                    }
                    .gesture(drag)
                
            }
        } else {
            internalBody
                .gesture(drag)
        }
    }
    
    private var internalBody: some View {
        VStack {
            if searchSlideBar {
                SearchViewSlideBar(searchConfig: $searchConfig)
            }
            
            switch searchConfig {
            case .posts:
                PostListView()
                    .modifier(BackButtonModifier())
                    .navigationBarBackButtonHidden()
                    
                
                
            
            case .users:
                    UserListView()
                        .modifier(BackButtonModifier())
                        .navigationBarBackButtonHidden()
            case .restaurants:
                    RestaurantListView()
                        .modifier(BackButtonModifier())
                        .navigationBarBackButtonHidden()
            case .collections:
                CollectionsSearchListView()
                    .modifier(BackButtonModifier())
                    .navigationBarBackButtonHidden()
            }
        }
        
    }
}

struct SearchView_Previews: PreviewProvider {
    static var previews: some View {
        SearchView(searchConfig: .posts)
    }
}



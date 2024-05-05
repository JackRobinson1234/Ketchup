//
//  SearchView.swift
//  Foodi
//
//  Created by Jack Robinson on 2/1/24.
//

import SwiftUI


struct SearchView: View {
    @State var searchText: String = ""
    @State var searchSlideBar: Bool
    private let userService: UserService
    @State var searchConfig: SearchModelConfig
    
    init(userService: UserService, searchConfig: SearchModelConfig, searchSlideBar: Bool = false) {
        self.userService = userService
        self._searchConfig = State(initialValue: searchConfig)
        self._searchSlideBar = State(initialValue: searchSlideBar)
    }
    
    var body: some View {
        // Conditionally embed in NavigationStack only when searchSlideBar is true

        if searchSlideBar {
            NavigationStack {
                internalBody
                    .navigationDestination(for: User.self) { user in
                        ProfileView(uid: user.id, userService: userService)
                    }
                    .navigationDestination(for: SearchModelConfig.self) { config in
                        SearchView(userService: UserService(), searchConfig: config)}
                    .navigationDestination(for: Restaurant.self) { restaurant in
                        RestaurantProfileView(restaurantId: restaurant.id)
                    }
            }
        } else {
            internalBody
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
        SearchView(userService: UserService(), searchConfig: .posts)
    }
}



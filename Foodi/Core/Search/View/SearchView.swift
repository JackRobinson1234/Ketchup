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
                        ProfileView(user: user, userService: userService)
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
                PostListView(userService: userService, searchText: $searchText)
                    .modifier(BackButtonModifier())
                    .navigationBarBackButtonHidden()
                    
                
            case .users(let userListConfig):
                UserListView(config: userListConfig, userService: userService, searchText: $searchText)
                    .modifier(BackButtonModifier())
                    .navigationBarBackButtonHidden()
                    
                
            case .restaurants(let restaurantListConfig):
                switch restaurantListConfig {
                case .upload:
                    RestaurantListView(config: restaurantListConfig, restaurantService: RestaurantService(), userService: userService)
                        .modifier(BackButtonModifier())
                        .navigationBarBackButtonHidden()
                case .restaurants:
                    RestaurantListView(config: restaurantListConfig, restaurantService: RestaurantService(), userService: userService)
                        .modifier(BackButtonModifier())
                        .navigationBarBackButtonHidden()
                }
                /*if restaurantListConfig == .upload{
                    RestaurantListView(config: restaurantListConfig, restaurantService: RestaurantService(), userService: userService)
                        .modifier(BackButtonModifier())
                        .navigationBarBackButtonHidden()
                        
                }
                else {
                    RestaurantListView(config: restaurantListConfig, restaurantService: RestaurantService(), userService: userService)
                        
                }
                 */
            }
        }
        
    }
}

struct SearchView_Previews: PreviewProvider {
    static var previews: some View {
        SearchView(userService: UserService(), searchConfig: .posts)
    }
}



//
//  SearchView.swift
//  Foodi
//
//  Created by Jack Robinson on 2/1/24.
//

import SwiftUI


struct SearchView: View {
    @State var searchText: String = ""
    @State var inSearchMode = false
    @Environment(\.dismiss) var dismiss
    private let userService: UserService
    @State var searchConfig: SearchModelConfig
    
    /*

    func searchView(config: SearchModelConfig) {
        switch config {
        case .users(let userConfig):
            // Handle user case with userConfig
            print("User config: \(userConfig)")
        case .restaurants(let restaurantConfig):
            // Handle restaurant case with restaurantConfig
            print("Restaurant config: \(restaurantConfig)")
        }
    }
    */
    
    
    init(userService: UserService, searchConfig: SearchModelConfig) {
        self.userService = userService
        self._searchConfig = State(initialValue: searchConfig)
    }
    
    var body: some View {
        NavigationStack {
            VStack{
                SearchViewSlideBar(searchConfig: $searchConfig)
                switch searchConfig {
                case .posts:
                    Text("Should Be Posts")
                    UserListView(config: .users, userService: userService, searchText: $searchText)
                        
                        .navigationDestination(for: User.self) { user in
                            ProfileView(user: user, userService: userService)}
                case .users(let userListConfig):
                    UserListView(config: userListConfig, userService: userService, searchText: $searchText)
                        
                        .navigationDestination(for: User.self) { user in
                            ProfileView(user: user, userService: userService)}
                    
                case .restaurants(let restaurantListConfig):
                    RestaurantListView(config: restaurantListConfig, restaurantService: RestaurantService(), userService: userService)
                    
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .font(.subheadline)
                    .foregroundColor(.black)
                }
            }
        }
                
                
        }
    }


struct SearchView_Previews: PreviewProvider {
    static var previews: some View {
        SearchView(userService: UserService(), searchConfig: .posts)
    }
}

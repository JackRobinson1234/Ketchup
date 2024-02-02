//
//  UserListVIew.swift
//  Foodi
//
//  Created by Jack Robinson on 2/1/24.
//

import SwiftUI

struct UserListView: View {
    @StateObject var viewModel: UserListViewModel
    private let config: UserListConfig
    //@State private var searchText = ""
    @Binding var searchText: String
    private let userService: UserService
    
    init(config: UserListConfig, userService: UserService, searchText: Binding<String>) {
        self.config = config
        self.userService = userService
        self._viewModel = StateObject(wrappedValue: UserListViewModel(config: config, userService: userService))
        self._searchText = searchText
    }
    
    var users: [User] {
        return searchText.isEmpty ? viewModel.users : viewModel.filteredUsers(searchText)
    }
    
    var body: some View {
        ScrollView {
            LazyVStack {
                ForEach(users) { user in
                    NavigationLink(value: user) {
                        UserCell(user: user)
                            .padding(.leading)
                            .onAppear {
                                if user.id == users.last?.id ?? "" {
                                }
                            }
                    }
                }
                
            }
            .navigationTitle(config.navigationTitle)
            .padding(.top)
            
            
        }
        //DEBUG: when this is commented out, do not get purple errors for multiple navigation destinations, but when its accessed from anywhere besides the feed, it doenst work.
        //.navigationDestination(for: User.self) { user in
        //ProfileView(user: user, userService: userService).id(user.id)}
        .searchable(text: $searchText, placement: .navigationBarDrawer)
    }
}

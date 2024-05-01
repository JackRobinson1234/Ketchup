//
//  ProfileUserLists.swift
//  Foodi
//
//  Created by Jack Robinson on 4/22/24.
//

import SwiftUI

struct ProfileUserLists: View {
    @StateObject var viewModel: ProfileUserListViewModel
    private let config: UserListConfig
    private let userService: UserService
    
    init(config: UserListConfig, userService: UserService) {
        self.config = config
        self.userService = userService
        self._viewModel = StateObject(wrappedValue: ProfileUserListViewModel(config: config, userService: userService))
    }
    
    //var users: [User] {
        //return viewModel.searchText.isEmpty ? viewModel.users : viewModel.filteredUsers(viewModel.searchText)
    //}
    
    var body: some View {
        NavigationStack{
            ScrollView {
                LazyVStack {
                    ForEach(viewModel.users) { user in
                        NavigationLink(value: user) {
                            UserCell(user: user)
                                .padding(.leading)
                                .onAppear {
                                    if user.id == viewModel.users.last?.id ?? "" {
                                    }
                                }
                        }
                    }
                    
                }
                .padding(.top)
                
                
            }
            .navigationTitle(config.navigationTitle)
            .navigationDestination(for: User.self) { user in
                ProfileView(uid: user.id, userService: userService)
            }
            .modifier(BackButtonModifier())
        }
    }
}

#Preview {
    ProfileUserLists(config: .following(uid: ""), userService: UserService())
}

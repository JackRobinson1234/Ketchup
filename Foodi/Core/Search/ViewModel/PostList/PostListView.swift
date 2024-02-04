//
//  PostListView.swift
//  Foodi
//
//  Created by Jack Robinson on 2/1/24.
//

import SwiftUI
//DEBUG
struct PostListView: View {
    var userService: UserService
    @Binding var searchText: String
    @StateObject var viewModel: PostListViewModel
    init(userService: UserService, searchText: Binding<String>){
        self.userService = userService
        self._searchText = searchText
        self._viewModel = StateObject(wrappedValue: PostListViewModel())
        
    }
    var body: some View {
        ScrollView{
            PostGridView(viewModel: viewModel, userService: userService)
        }
        .navigationTitle("Explore")
        .padding(.top)
        .searchable(text: $searchText, placement: .navigationBarDrawer)
    }
    
}

#Preview {
    PostListView(userService: UserService(), searchText: .constant(""))
}

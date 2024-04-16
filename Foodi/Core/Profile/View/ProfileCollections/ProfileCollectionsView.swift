//
//  CollectionsView.swift
//  Foodi
//
//  Created by Jack Robinson on 4/15/24.
//

import SwiftUI
import FirebaseAuth
import Firebase
struct ProfileCollectionsView: View {
    @State private var isLoading = true
    @StateObject var viewModel: CollectionsViewModel = CollectionsViewModel()
    let user: User
    var body: some View {
        if isLoading && viewModel.collections.isEmpty {
            // Loading screen
            ProgressView("Loading...")
                .onAppear {
                    Task {
                        await viewModel.fetchCollections(user: user.id)
                        isLoading = false
                    }
                }
                .toolbar(.hidden, for: .tabBar)
        }
        else{
            ScrollView{
                VStack{
                    if user.isCurrentUser {
                       CreateCollectionButton()
                        Divider()
                    }
                    if !viewModel.collections.isEmpty {
                        ForEach(viewModel.collections) { collection in
                            NavigationLink(value: collection) {
                                ProfileCollectionCell(collection: collection)
                            }
                            Divider()
                        }
                    }
                    else {
                        Text("No Collections to Show")
                    }
                }
                .navigationDestination(for: Collection.self) {collection in CollectionView(collection: collection)}
            }
        }
    }
}

#Preview {
    ProfileCollectionsView(user: DeveloperPreview.user)
}

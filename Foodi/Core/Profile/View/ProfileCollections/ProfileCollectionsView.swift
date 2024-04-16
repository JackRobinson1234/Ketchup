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
    @State var showAddCollection: Bool = false
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
                        Button{
                            showAddCollection.toggle()
                        } label: {
                            CreateCollectionButton()
                        }
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
                .navigationDestination(for: Collection.self) {collection in CollectionView(collectionsViewModel: viewModel, collection: collection)}
                .sheet(isPresented: $showAddCollection) {CreateCollectionDetails(user: user)}
            }
        }
    }
}

#Preview {
    ProfileCollectionsView(user: DeveloperPreview.user)
}

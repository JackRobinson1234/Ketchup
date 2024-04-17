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
    @StateObject var viewModel: CollectionsViewModel
    @State var showAddCollection: Bool = false
    @State var showCollection: Bool = false
    let user: User
    
    init(user: User) {
        self.user = user
        self._viewModel = StateObject(wrappedValue: CollectionsViewModel(user: user))
    }
    
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
                        Button{
                            viewModel.updateSelectedCollection(collection: collection) 
                            showCollection.toggle()
                        } label: {
                            ProfileCollectionCell(collection: collection)
                        }
                        Divider()
                    }
                }
                else {
                    Text("No Collections to Show")
                }
            }
            .fullScreenCover(isPresented: $showCollection) {CollectionView(collectionsViewModel: viewModel)}
            //.navigationDestination(for: Collection.self) {collection in
            //CollectionView(collectionsViewModel: viewModel, collection: collection)}
            .sheet(isPresented: $showAddCollection) {CreateCollectionDetails(user: user, collectionsViewModel: viewModel)}
        }
    }
}

#Preview {
    ProfileCollectionsView(user: DeveloperPreview.user)
}

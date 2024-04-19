//
//  CollectionsView.swift
//  Foodi
//
//  Created by Jack Robinson on 4/15/24.
//

import SwiftUI
import FirebaseAuth
import Firebase
struct CollectionsListView: View {
    @Environment(\.dismiss) var dismiss
    @State private var isLoading = true
    @StateObject var viewModel: CollectionsViewModel
    @State var showAddCollection: Bool = false
    @State var showCollection: Bool = false
    var post: Post?
    let user: User
    
    init(user: User, post: Post? = nil) {
        self.user = user
        self.post = post
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
                    // if post isn't passed in, then go to the selected collection, else add the post as an item to the collection
                    ForEach(viewModel.collections) { collection in
                        Button{
                            if post == nil {
                                viewModel.updateSelectedCollection(collection: collection)
                                showCollection.toggle()
                            } else {
                                if let post {
                                    viewModel.updateSelectedCollection(collection: collection)
                                    viewModel.addPostToCollection(post: post)
                                    dismiss()
                                }
                            }
                        } label: {
                            CollectionListCell(collection: collection)
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
            .sheet(isPresented: $showAddCollection) {if post == nil {CreateCollectionDetails(user: user, collectionsViewModel: viewModel)}}
        }
    }
}

#Preview {
    CollectionsListView(user: DeveloperPreview.user)
}

struct CreateCollectionButton: View {
    var body: some View {
        HStack{
            Image(systemName: "plus")
                .resizable()
                .scaledToFit()
                .frame(width: 20, height: 20)
            VStack(alignment: .leading){
                Text("Create a New Collection")
                    .font(.subheadline)
            }
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundStyle(.black)
                .padding(.horizontal)
        }
        .padding(.horizontal)
    }
}

#Preview {
    CreateCollectionButton()
}

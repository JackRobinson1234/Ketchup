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
    @ObservedObject var viewModel: CollectionsViewModel
    @State var showAddCollection: Bool = false
    @State var showCollection: Bool = false
    @State var dismissCollectionsList: Bool = false
    
    var body: some View {
        //MARK: isLoading
        VStack{
            if viewModel.isLoading {
                // Loading screen
                ProgressView("Loading...")
                    .toolbar(.hidden, for: .tabBar)
            }
            else{
                //MARK: Add Collection Button
                ScrollView{
                    LazyVStack{
                        if viewModel.user.isCurrentUser {
                            Divider()
                            Button{
                                if let post = viewModel.post{
                                    print("POST", post)
                                }
                                if let post = viewModel.restaurant{
                                    print("RESTAURANT", post)
                                }
                                showAddCollection.toggle()
                            } label: {
                                CreateCollectionButton()
                            }
                            .padding(.vertical)
                            Divider()
                        }
                        //MARK: CollectionsList
                        if !viewModel.collections.isEmpty {
                            // if post isn't passed in, then go to the selected collection
                            ForEach(viewModel.collections) { collection in
                                Button{
                                    if viewModel.post == nil && viewModel.restaurant == nil {
                                        viewModel.updateSelectedCollection(collection: collection)
                                        showCollection.toggle()
                                    } else if viewModel.post != nil {
                                        Task{
                                            viewModel.dismissListView = true
                                            viewModel.updateSelectedCollection(collection: collection)
                                            try await viewModel.addPostToCollection()
                                            viewModel.dismissListView = false
                                        }
                                    } else if viewModel.restaurant != nil {
                                        Task {
                                            viewModel.dismissListView = true
                                            viewModel.updateSelectedCollection(collection: collection)
                                            try await viewModel.addRestaurantToCollection()
                                            viewModel.dismissListView = false
                                        }
                                    }
                                } label: {
                                    CollectionListCell(collection: collection)
                                }
                                Divider()
                            }
                        }
                        //MARK: No Collections Message
                        else {
                            if viewModel.user.isCurrentUser{
                                Text("You don't have any collections yet!")
                                    .font(.subheadline)
                                    .padding()
                            } else {
                                Text("\(viewModel.user.fullname) doesn't have any collections yet!")
                                    .font(.subheadline)
                                    .padding()
                            }
                        }
                    }
                }
                .fullScreenCover(isPresented: $showCollection) {CollectionView(collectionsViewModel: viewModel)}
                //.navigationDestination(for: Collection.self) {collection in
                //CollectionView(collectionsViewModel: viewModel, collection: collection)}
                .sheet(isPresented: $showAddCollection) {
                    CreateCollectionDetails(user: viewModel.user, collectionsViewModel: viewModel, dismissCollectionsList: $dismissCollectionsList)
                }
                // Dismisses this view if a new collection is made
                
            }
        }
        
        .onAppear {
            if !viewModel.dismissListView {
                Task {
                    await viewModel.fetchCollections(user: viewModel.user.id)
                }
            }
        }
        .onChange(of: viewModel.dismissListView) {
            if viewModel.dismissListView {
                viewModel.dismissListView = false
                dismiss()
            }
        }
    }
}

#Preview {
    CollectionsListView(viewModel: CollectionsViewModel(user: DeveloperPreview.user))
}
struct CreateCollectionButton: View {
    var body: some View {
        HStack{
            Image(systemName: "plus")
                .resizable()
                .scaledToFit()
                .frame(width: 20)
                .foregroundStyle(Color("Colors/AccentColor"))
                .padding(.horizontal)
            VStack(alignment: .leading){
                Text("Create a New Collection")
                    .font(.subheadline)
                    .foregroundStyle(.primary)
            }
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundStyle(.primary)
                .padding(.horizontal)
        }
        .padding(.horizontal)
    }
}

#Preview {
    CreateCollectionButton()
}

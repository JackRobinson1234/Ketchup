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
    let user: User
    
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
                //ScrollView{
                    LazyVStack{
                        if user.isCurrentUser {
                            Divider()
                            Button{
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
                                    CollectionListCell(collection: collection, collectionsViewModel: viewModel)
                                }
                                Divider()
                            }
                        }
                        //MARK: No Collections Message
                        else {
                            if user.isCurrentUser{
                                Text("You don't have any collections yet!")
                                    .font(.custom("MuseoSansRounded-300", size: 16))
                                    .padding()
                            } else {
                                Text("\(user.fullname) doesn't have any collections yet!")
                                    .font(.custom("MuseoSansRounded-300", size: 16))
                                    .padding()
                            }
                        }
                    //}
                }
                .fullScreenCover(isPresented: $showCollection) {CollectionView(collectionsViewModel: viewModel)}
                //.navigationDestination(for: Collection.self) {collection in
                //CollectionView(collectionsViewModel: viewModel, collection: collection)}
                .sheet(isPresented: $showAddCollection) {
                    CreateCollectionDetails(collectionsViewModel: viewModel, dismissCollectionsList: $dismissCollectionsList)
                }
                // Dismisses this view if a new collection is made
                
            }
        }
        
        .onAppear {
            if !viewModel.dismissListView {
                Task {
                    await viewModel.fetchCollections(user: user.id)
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
                    .font(.custom("MuseoSansRounded-300", size: 16))
                    .foregroundStyle(.black)
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

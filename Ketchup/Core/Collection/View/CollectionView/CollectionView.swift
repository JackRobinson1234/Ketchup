//
//  collectionSlideBar.swift
//  Foodi
//
//  Created by Jack Robinson on 4/10/24.
//

import SwiftUI
import Kingfisher
import FirebaseAuth
enum collectionSection {
    case grid, map
}

struct CollectionView: View {
    @State var currentSection: collectionSection = .grid
    @ObservedObject var collectionsViewModel: CollectionsViewModel
    @Environment(\.dismiss) var dismiss
    @State var showEditCollection: Bool = false
    @State var deletedCollection: Bool = false
    @State private var showingOptionsSheet = false
    @FocusState private var isNotesFocused: Bool
    @State var isDragging = false
    @State var dragDirection = "left"
    
    var drag: some Gesture {
        DragGesture(minimumDistance: 14 )
            .onChanged { _ in self.isDragging = true }
            .onEnded { endedGesture in
                if (endedGesture.location.x - endedGesture.startLocation.x) > 0 {
                    self.dragDirection = "left"
                    
                    dismiss()
                }
            }
    }
    var body: some View {
        //MARK: Selecting Images
        NavigationStack{
            ZStack{
                ScrollView(showsIndicators: false){
                    if let collection = collectionsViewModel.selectedCollection {
                        VStack{
                            
                            //MARK: Cover Image
                            HStack(alignment: .bottom){
                                if let cover = collection.coverImageUrl {
                                    CollageImage(tempImageUrls: [cover], width: 200)
                                } else if let tempImageUrls = collection.tempImageUrls {
                                    CollageImage(tempImageUrls: tempImageUrls, width: 200)
                                } else {
                                    Image(systemName: "folder")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 200, height: 200)
                                        .foregroundStyle(.black)
                                }
                            
                            }
                               
                            //MARK: Title
                            HStack{
                                Text(collection.name)
                                    .font(.custom("MuseoSansRounded-300", size: 20))
                                    .bold()
                                    .foregroundStyle(.black)
                            }
                            //MARK: UserName
                            NavigationLink(destination: ProfileView(uid: collection.uid)){
                                Text("by: @")
                                    .font(.custom("MuseoSansRounded-300", size: 18))
                                    .foregroundStyle(.black)
                                +
                                Text(collection.username)
                                    .font(.custom("MuseoSansRounded-500", size: 18))
                                    .foregroundStyle(.black)
                                
                            }
                            if let description = collection.description, !description.isEmpty {
                                VStack{
                                    Text(description)
                                        .font(.custom("MuseoSansRounded-300", size: 16))
                                        .foregroundStyle(.black)
                                }
                                .frame(width: UIScreen.main.bounds.width * 3 / 4)
                                
                            }
                            LikeButton(collection: collection, viewModel: collectionsViewModel)
                                .padding(.vertical, 2)

                            // MARK: Grid View
                            HStack(spacing: 0) {
                                Image(systemName: currentSection == .grid ? "square.grid.2x2.fill" : "square.grid.2x2")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 50, height: 20)
                                    .onTapGesture {
                                        withAnimation {
                                            self.currentSection = .grid
                                        }
                                    }
                                    .modifier(UnderlineImageModifier(isSelected: currentSection == .grid))
                                    .frame(maxWidth: .infinity)
                                
                                //MARK: Location View
                                Image(systemName: currentSection == .map ? "location.fill" : "location")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 50, height: 22)
                                
                                    .onTapGesture {
                                        withAnimation {
                                            self.currentSection = .map
                                        }
                                    }
                                    .modifier(UnderlineImageModifier(isSelected: currentSection == .map))
                                    .frame(maxWidth: .infinity)
                            }
                            .padding()
                            // MARK: Section Logic
                            if currentSection == .map {
                                CollectionMapView(collectionsViewModel: collectionsViewModel)
                                
                            }
                            if currentSection == .grid {
                                CollectionListView(collectionsViewModel: collectionsViewModel)
                            }
                        }
                        .toolbar {
                            ToolbarItem(placement: .topBarLeading) {
                                Button {
                                    collectionsViewModel.resetViewModel()
                                    dismiss()
                                } label: {
                                    Image(systemName: "chevron.left")
                                        .foregroundStyle(.white)
                                        .background(
                                            Circle()
                                                .fill(Color.gray.opacity(0.5)) // Adjust the opacity as needed
                                                .frame(width: 30, height: 30) // Adjust the size as needed
                                        )
                                        .padding()
                                }
                            }
                            //MARK: Edit
                            ToolbarItem(placement: .topBarTrailing) {
                                if let currentUser = Auth.auth().currentUser?.uid, let uid = collectionsViewModel.selectedCollection?.uid, uid == currentUser {
                                    Button {
                                        showEditCollection.toggle()
                                    } label: {
                                        Text("Edit")
                                            .padding()
                                            .foregroundStyle(.black)
                                    }
                                } else {
                                    Button {
                                        showingOptionsSheet = true
                                    } label: {
                                        ZStack{
                                            Rectangle()
                                                .fill(.clear)
                                                .frame(width: 18, height: 14)
                                            Image(systemName: "ellipsis")
                                                .resizable()
                                                .scaledToFill()
                                                .frame(width: 6, height: 6)
                                                .foregroundStyle(.black)
                                            
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                //MARK: Notes View
                if let item = collectionsViewModel.notesPreview {
                    ItemNotesView(item: item, viewModel: collectionsViewModel )
                        .focused($isNotesFocused) // Connects the focus state to the editor view
                        .onAppear {
                            isNotesFocused = true // Automatically focuses the TextEditor when it appears
                        }
                }
                
            }
            .onAppear{
                Task{
                    await collectionsViewModel.checkIfUserLikedCollection()
                }
            }
            .gesture(drag)
            .sheet(isPresented: $showEditCollection) {
                EditCollectionView(collectionsViewModel: collectionsViewModel)
                    .onDisappear {
                        if collectionsViewModel.dismissCollectionView {
                            collectionsViewModel.dismissCollectionView = false
                            dismiss()
                        }
                        
                    }
            }// if the collection is deleted in the edit collection view, navigate back to the collectionListview
            .sheet(isPresented: $showingOptionsSheet) {
                if let selectedCollection = collectionsViewModel.selectedCollection {
                    CollectionOptionsSheet(collection: selectedCollection)
                        .presentationDetents([.height(UIScreen.main.bounds.height * 0.10)])
                }
            }
            
            
        }
    }
}

struct LikeButton: View {
    let collection: Collection
    @ObservedObject var viewModel: CollectionsViewModel
    
    var body: some View {
        Button(action: {
            Task {
                if collection.didLike {
                    await viewModel.unlike(collection)
                } else {
                    await viewModel.like(collection)
                }
            }
        }) {
            HStack(spacing: 1){
                Image(systemName: collection.didLike ? "heart.fill" : "heart")
                    .foregroundColor(collection.didLike ? .red : .gray)
                Text("\(collection.likes)")
                    .foregroundColor(.gray)
            }
        }
    }
}

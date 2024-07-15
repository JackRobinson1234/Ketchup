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
                           CollageImage(collection: collection, width: 200)
                            //MARK: Title
                            Text(collection.name)
                                .font(.custom("MuseoSansRounded-300", size: 20))
                                .bold()
                                .foregroundStyle(.primary)
                            //MARK: UserName
                            Text("by: @\(collection.username)")
                                .font(.custom("MuseoSansRounded-300", size: 18))
                                .foregroundStyle(.primary)
                            if let description = collection.description {
                                VStack{
                                    Text(description)
                                        .font(.custom("MuseoSansRounded-300", size: 16))
                                        .foregroundStyle(.primary)
                                }
                                .frame(width: UIScreen.main.bounds.width * 3 / 4)
                                      
                            }
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
                                            .foregroundStyle(.primary)
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
                                                .foregroundStyle(.primary)
                                            
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
#Preview {
    CollectionView(collectionsViewModel: CollectionsViewModel())
}

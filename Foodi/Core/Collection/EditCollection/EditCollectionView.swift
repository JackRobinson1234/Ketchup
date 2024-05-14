//
//  EditCollectionView.swift
//  Foodi
//
//  Created by Jack Robinson on 4/16/24.
//

import SwiftUI

struct EditCollectionView: View {
    @ObservedObject var collectionsViewModel: CollectionsViewModel
    @Environment(\.dismiss) var dismiss
    @State private var isEditingCaption = false
    @State private var isEditingTitle = false
    @FocusState private var isCaptionEditorFocused: Bool
    @FocusState private var isTitleEditorFocused: Bool
    @State private var itemsPreview: [CollectionItem] // Define itemsPreview state
    @State var selectedItem: CollectionItem?
    let width = (UIScreen.main.bounds.width / 3) - 5
    let spacing: CGFloat = 3
        init(collectionsViewModel: CollectionsViewModel) {
            self.collectionsViewModel = collectionsViewModel
            _itemsPreview = State(initialValue: collectionsViewModel.items)
        }
    
    var body: some View {
        NavigationStack{
                ZStack {
                    ScrollView{
                        VStack {
                            Button{
                                Task{
                                    try await collectionsViewModel.deleteCollection()
                                    dismiss()
                                }
                            } label: {
                                Text("Delete Collection")
                                    .font(.subheadline)
                                    .foregroundStyle(.red)
                            }
                            //Image Selector
                            CoverPhotoSelector(viewModel: collectionsViewModel)
                            //MARK: Title Box
                            Button(action: {
                                self.isEditingTitle = true
                            }) {
                                TextBox(text: $collectionsViewModel.editTitle, isEditing: $isEditingTitle, placeholder: "Enter a title...*", maxCharacters: 100)
                            }
                            
                            .padding(.vertical)
                            //MARK: Caption Box
                            Button(action: {
                                self.isEditingCaption = true
                            }) {
                                TextBox(text: $collectionsViewModel.editDescription, isEditing: $isEditingCaption, placeholder: "Enter a description...", maxCharacters: 150)
                            }
                            // MARK: Items
                            LazyVGrid(columns: [GridItem(.flexible(), spacing: spacing), GridItem(.flexible(), spacing: spacing), GridItem(.flexible(), spacing: spacing)], spacing: spacing) {
                                //if collection.uid == Auth.auth().currentUser?.uid{
                                ForEach(itemsPreview, id: \.id) { item in
                                    VStack{
                                        CollectionItemCell(item: item, width: width, previewMode: true, viewModel: collectionsViewModel)
                                            .aspectRatio(1.0, contentMode: .fit)
                                            .overlay(
                                                Button{
                                                    self.selectedItem = item
                                                } label: {
                                                    Image(systemName: "square.and.pencil")
                                                        .resizable()
                                                        .scaledToFit()
                                                        .frame(width: 30)
                                                        .foregroundColor(.white)
                                                    
                                                        .shadow(color: .black.opacity(1), radius: 4, x: 1, y: 1)
                                                        .opacity(0.8)
                                                
                                                }
                                                    .offset(x: width/2.8, y: -width/2.3 )
                                            )
                                        Button{
                                            if let index = itemsPreview.firstIndex(where: { $0.id == item.id }) {
                                                itemsPreview.remove(at: index)
                                                collectionsViewModel.deleteItems.append(item)
                                            }
                                            print(collectionsViewModel.deleteItems)
                                        } label: {
                                            Text("Remove")
                                                .foregroundStyle(.red)
                                                .font(.subheadline)
                                        }
                                    }
                                    .padding(7)
                                }
                                Spacer()
                                    .padding(.vertical)
                                
                            }
                        }
                    }
                    //MARK: Title Editor Overlay
                    if isEditingTitle {
                        EditorView(text: $collectionsViewModel.editTitle, isEditing: $isEditingTitle, placeholder: "Enter a title*...", maxCharacters: 100, title: "Title")
                            .focused($isTitleEditorFocused) // Connects the focus state to the editor view
                            .onAppear {
                                isTitleEditorFocused = true // Automatically focuses the TextEditor when it appears
                            }
                    }
                    //MARK: Caption Editor Overlay
                    if isEditingCaption {
                        EditorView(text: $collectionsViewModel.editDescription, isEditing: $isEditingCaption, placeholder: "Enter a description...", maxCharacters: 150, title: "Description")
                            .focused($isCaptionEditorFocused) // Connects the focus state to the editor view
                            .onAppear {
                                isCaptionEditorFocused = true // Automatically focuses the TextEditor when it appears
                            }
                    }
                    if selectedItem != nil {
                        EditNotesView(item: $selectedItem, viewModel: collectionsViewModel, itemsPreview: $itemsPreview)
                    }
                }
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle("Edit Collection")
            .preferredColorScheme(.light)
            //POSS Check if keyboard is active here
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        collectionsViewModel.clearEdits()
                        dismiss()
                    } label: {
                        Text("Cancel")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task{
                            try await collectionsViewModel.saveEditedCollection()
                            dismiss()
                        }
                    } label: {
                        Text("Save")
                            .opacity(collectionsViewModel.editTitle.isEmpty ? 0.5 : 1.0)
                    }
                    .disabled(collectionsViewModel.editTitle.isEmpty)
                }
            }
        }
        .onDisappear {
            collectionsViewModel.clearEdits()
        }
    }
}
#Preview {
    EditCollectionView(collectionsViewModel: CollectionsViewModel(user: DeveloperPreview.user))
}

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
    
    var body: some View {
        NavigationStack{
            ZStack {
                VStack {
                    CoverPhotoSelector(viewModel: collectionsViewModel)
                    //MARK: Title Box
                    Button(action: {
                        self.isEditingTitle = true
                    }) {
                        TextBox(text: $collectionsViewModel.editTitle, isEditing: $isEditingTitle, placeholder: "Enter a title...", maxCharacters: 100)
                    }
                    
                    .padding(.vertical)
                    //MARK: CaptionBox
                    Button(action: {
                        self.isEditingCaption = true
                    }) {
                        TextBox(text: $collectionsViewModel.editDescription, isEditing: $isEditingCaption, placeholder: "Enter a description...", maxCharacters: 150)
                    }
                    
                    Spacer()
                        .padding(.vertical)
                    
                }
                //MARK: Title Editor Overlay
                if isEditingTitle {
                    EditorView(text: $collectionsViewModel.editTitle, isEditing: $isEditingTitle, placeholder: "Enter a title...", maxCharacters: 100, title: "Title")
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
                    }
                }
            }
        }
        .onDisappear {
            collectionsViewModel.clearEdits()
        }
    }
}
#Preview {
    CreateCollectionDetails(user: DeveloperPreview.user, collectionsViewModel: CollectionsViewModel(user: DeveloperPreview.user))
}

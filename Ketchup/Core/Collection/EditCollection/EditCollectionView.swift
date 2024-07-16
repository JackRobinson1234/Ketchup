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
    @State private var itemsPreview: [CollectionItem]
    @State var selectedItem: CollectionItem?

    init(collectionsViewModel: CollectionsViewModel) {
        self.collectionsViewModel = collectionsViewModel
        _itemsPreview = State(initialValue: collectionsViewModel.items)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 0) {
                    // Delete Collection Button
                    Button {
                        Task {
                            try await collectionsViewModel.deleteCollection()
                            dismiss()
                        }
                    } label: {
                        Text("Delete Collection")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.red)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .center)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(10)
                    }
                    .padding()

                    // Cover Photo Selector
                    CoverPhotoSelector(viewModel: collectionsViewModel)
                        .padding()

                    // Title Editor
                    Button(action: { self.isEditingTitle = true }) {
                        TextBox(text: $collectionsViewModel.editTitle, isEditing: $isEditingTitle, placeholder: "Enter a title...*", maxCharacters: 100)
                    }
                    .padding()

                    // Description Editor
                    Button(action: { self.isEditingCaption = true }) {
                        TextBox(text: $collectionsViewModel.editDescription, isEditing: $isEditingCaption, placeholder: "Enter a description...", maxCharacters: 150)
                    }
                    .padding()

                    // Items List
                    ForEach(itemsPreview, id: \.id) { item in
                        HStack {
                            CollectionItemCell(item: item, previewMode: true, viewModel: collectionsViewModel)
                                .frame(height: 72)
                            
                            Spacer()
                            
                            Button {
                                self.selectedItem = item
                            } label: {
                                Image(systemName: "square.and.pencil")
                                    .foregroundColor(.blue)
                            }
                            
                            Button {
                                if let index = itemsPreview.firstIndex(where: { $0.id == item.id }) {
                                    itemsPreview.remove(at: index)
                                    collectionsViewModel.deleteItems.append(item)
                                }
                            } label: {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                            }
                        }
                        .padding(.horizontal)
                        
                        Divider()
                            .padding(.leading, 84)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle("Edit Collection")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        collectionsViewModel.clearEdits()
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        Task {
                            try await collectionsViewModel.saveEditedCollection()
                            dismiss()
                        }
                    }
                    .disabled(collectionsViewModel.editTitle.isEmpty)
                }
            }
            .overlay(Group {
                if isEditingTitle {
                    EditorView(text: $collectionsViewModel.editTitle, isEditing: $isEditingTitle, placeholder: "Enter a title*...", maxCharacters: 100, title: "Title")
                        .focused($isTitleEditorFocused)
                        .onAppear { isTitleEditorFocused = true }
                }
                if isEditingCaption {
                    EditorView(text: $collectionsViewModel.editDescription, isEditing: $isEditingCaption, placeholder: "Enter a description...", maxCharacters: 150, title: "Description")
                        .focused($isCaptionEditorFocused)
                        .onAppear { isCaptionEditorFocused = true }
                }
                if selectedItem != nil {
                    EditNotesView(item: $selectedItem, viewModel: collectionsViewModel, itemsPreview: $itemsPreview)
                }
            })
        }
        .onDisappear {
            collectionsViewModel.clearEdits()
        }
    }
}

//
//  EditCollectionView.swift
//  Foodi
//
//  Created by Jack Robinson on 4/16/24.
//

import SwiftUI
import FirebaseAuth

struct EditCollectionView: View {
    @ObservedObject var collectionsViewModel: CollectionsViewModel
    @Environment(\.dismiss) var dismiss
    @State private var isEditingCaption = false
    @State private var isEditingTitle = false
    @FocusState private var isCaptionEditorFocused: Bool
    @FocusState private var isTitleEditorFocused: Bool
    @State private var itemsPreview: [CollectionItem]
    @State var selectedItem: CollectionItem?
    @State private var showDeleteAlert = false
    @State private var showLeaveAlert = false

    init(collectionsViewModel: CollectionsViewModel) {
        self.collectionsViewModel = collectionsViewModel
        _itemsPreview = State(initialValue: collectionsViewModel.items)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 0) {
                    // Delete Collection Button (only for owner)
                    if isOwner {
                        deleteCollectionButton
                    } else {
                        leaveCollectionButton
                    }

                    // Rest of the view remains the same
                    CoverPhotoSelector(viewModel: collectionsViewModel)
                        .padding()

                    Button(action: { self.isEditingTitle = true }) {
                        TextBox(text: $collectionsViewModel.editTitle, isEditing: $isEditingTitle, placeholder: "Enter a title...*", maxCharacters: 100)
                    }
                    .padding()

                    Button(action: { self.isEditingCaption = true }) {
                        TextBox(text: $collectionsViewModel.editDescription, isEditing: $isEditingCaption, placeholder: "Enter a description...", maxCharacters: 150)
                    }
                    .padding()

                    // ... rest of the existing view code ...
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
            // ... rest of the existing view code ...
        }
        .onDisappear {
            collectionsViewModel.clearEdits()
        }
    }

    private var isOwner: Bool {
        guard let currentUserUid = Auth.auth().currentUser?.uid else { return false }
        return currentUserUid == collectionsViewModel.selectedCollection?.uid
    }

    private var deleteCollectionButton: some View {
        Button {
            showDeleteAlert = true
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
        .alert(isPresented: $showDeleteAlert) {
            Alert(
                title: Text("Delete Collection"),
                message: Text("Are you sure you want to delete this collection? This action cannot be undone."),
                primaryButton: .destructive(Text("Delete")) {
                    Task {
                        try await collectionsViewModel.deleteCollection()
                        dismiss()
                    }
                },
                secondaryButton: .cancel()
            )
        }
    }

    private var leaveCollectionButton: some View {
        Button {
            showLeaveAlert = true
        } label: {
            Text("Leave Collection")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.red)
                .padding()
                .frame(maxWidth: .infinity, alignment: .center)
                .background(Color.red.opacity(0.1))
                .cornerRadius(10)
        }
        .padding()
        .alert(isPresented: $showLeaveAlert) {
            Alert(
                title: Text("Leave Collection"),
                message: Text("Are you sure you want to leave this collection? You will no longer be able to contribute to it."),
                primaryButton: .destructive(Text("Leave")) {
                    Task {
                        await collectionsViewModel.removeSelfAsCollaborator()
                        dismiss()
                    }
                },
                secondaryButton: .cancel()
            )
        }
    }
}

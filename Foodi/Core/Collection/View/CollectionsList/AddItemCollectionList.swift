//
//  SwiftUIView.swift
//  Foodi
//
//  Created by Jack Robinson on 4/19/24.
//

import SwiftUI

struct AddItemCollectionList: View {
    @Environment(\.dismiss) var dismiss
    @StateObject var viewModel: CollectionsViewModel
    @FocusState private var isCaptionEditorFocused: Bool
    @State private var isEditingCaption = false
    let user: User
    var post: Post?
    var restaurant: Restaurant?
    
    init(user: User, post: Post? = nil, restaurant: Restaurant? = nil) {
        self.user = user
        self.post = post
        self.restaurant = restaurant
        self._viewModel = StateObject(wrappedValue: CollectionsViewModel(user: user, post: post, restaurant: restaurant))
    }
    var body: some View {
        NavigationStack{
                    ZStack {
                        ScrollView {
                            VStack{
                                if post != nil {
                                    if let item = viewModel.convertPostToCollectionItem() {
                                        CollectionItemCell(item: item, previewMode: true, viewModel: viewModel)
                                            .padding()
                                    }
                                }
                                
                                else if restaurant != nil {
                                    if let item = viewModel.convertRestaurantToCollectionItem() {
                                        CollectionItemCell(item: item, previewMode: true, viewModel: viewModel)
                                            .padding()
                                    }
                                }
                                
                                Button(action: {
                                    self.isEditingCaption = true
                                }) {
                                    CaptionBox(caption: $viewModel.notes, isEditingCaption: $isEditingCaption, title: "Add some notes...")
                                }
                                
                                CollectionsListView(viewModel: viewModel)
                                Spacer()
                            }
                        }
                    if isEditingCaption {
                        CaptionEditorView(caption: $viewModel.notes, isEditingCaption: $isEditingCaption, title: "Notes")
                            .focused($isCaptionEditorFocused) // Connects the focus state to the editor view
                            .onAppear {
                                isCaptionEditorFocused = true // Automatically focuses the TextEditor when it appears
                            }
                    }
            }
            .onChange(of: viewModel.dismissListView) {
                if viewModel.dismissListView {
                    dismiss()
                    viewModel.dismissListView = false
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Text("Cancel")
                            .foregroundStyle(.blue)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarTitle(post?.postType == "atHome" ? "Add Post to a Collection" : "Add Restaurant to a Collection")
        }
    }
}
#Preview {
    AddItemCollectionList(user: DeveloperPreview.user, post: DeveloperPreview.posts[0])
}

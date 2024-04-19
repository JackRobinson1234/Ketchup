//
//  CreateCollectionDetails.swift
//  Foodi
//
//  Created by Jack Robinson on 4/15/24.
//

import SwiftUI
import PhotosUI
import Kingfisher

struct CreateCollectionDetails: View {
    var user: User
    @ObservedObject var collectionsViewModel: CollectionsViewModel
    @Environment(\.dismiss) var dismiss
    @State private var isEditingCaption = false
    @State private var isEditingTitle = false
    @FocusState private var isCaptionEditorFocused: Bool
    @FocusState private var isTitleEditorFocused: Bool
    @Binding var dismissCollectionsList: Bool
    
    var body: some View {
        NavigationStack{
            ZStack {
                VStack {
                    CoverPhotoSelector(viewModel: collectionsViewModel)
                    //MARK: Title Box
                    Button(action: {
                        self.isEditingTitle = true
                    }) {
                        TextBox(text: $collectionsViewModel.editTitle, isEditing: $isEditingTitle, placeholder: "Enter a title...*", maxCharacters: 100)
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
                    //MARK: Create Collection Button
                    if collectionsViewModel.editTitle.isEmpty{
                        Text("Add a title to continue")
                            .font(.caption)
                    }
                    Button {
                        Task {
                            try await collectionsViewModel.uploadCollection()
                            // Dismiss all the views
                            if collectionsViewModel.post != nil {
                                collectionsViewModel.dismissListView.toggle()
                            } else {
                                collectionsViewModel.dismissCollectionView.toggle()
                            }
                            dismiss()
                        }
                    } label: {
                        if collectionsViewModel.post != nil {
                            Text(collectionsViewModel.isLoading ? "" : "Create Collection + Add Item")
                                .modifier(StandardButtonModifier())
                                .opacity(collectionsViewModel.editTitle.isEmpty ? 0.5 : 1.0)
                                .overlay {
                                    if collectionsViewModel.isLoading {
                                        ProgressView()
                                            .tint(.white)
                                    }
                                }
                        } else {
                                Text(collectionsViewModel.isLoading ? "" : "Create Collection")
                                    .modifier(StandardButtonModifier())
                                    .opacity(collectionsViewModel.editTitle.isEmpty ? 0.5 : 1.0)
                                    .overlay {
                                        if collectionsViewModel.isLoading {
                                            ProgressView()
                                                .tint(.white)
                                        }
                                    }
                            }
                    }
                    .disabled(collectionsViewModel.editTitle.isEmpty)
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
            .onDisappear{collectionsViewModel.resetViewModel()}
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle("Create a New Collection")
            .preferredColorScheme(.light)
            //POSS Check if keyboard is active here
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Text("Cancel")
                    }
                }
            }
        }
    }
}
#Preview {
    CreateCollectionDetails(user: DeveloperPreview.user, collectionsViewModel: CollectionsViewModel(user: DeveloperPreview.user), dismissCollectionsList: .constant(false))
}


//MARK: TextBox
struct TextBox: View {
    @Binding var text: String
    @Binding var isEditing: Bool
    let placeholder: String
    let maxCharacters: Int

    var body: some View {
        VStack {
            ScrollView {
                ZStack(alignment: .leading) {
                    TextEditor(text: $text)
                        .foregroundColor(text.isEmpty ? .clear : .black)
                        .disabled(true)
                        .frame(maxHeight: .infinity)
                        .multilineTextAlignment(.leading)
                        .onTapGesture {
                            isEditing = true
                        }
                        

                    if text.isEmpty {
                        Text(placeholder)
                            .foregroundColor(.gray)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 8)
                    }
                }
            }
            .frame(height: 80)
            .padding(.horizontal)

            HStack {
                Spacer()
                Text("\(maxCharacters - text.count) characters remaining")
                    .font(.caption)
                    .foregroundColor(text.count > maxCharacters ? .red : .gray)
                    .padding(.horizontal, 10)
            }
            Divider()
        }
        //Makes sure that the text shows up
        .onAppear {
            text += " "
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    if text.last == " " {
                        text.removeLast() // Removes the space after 0.1 seconds if it was added
                    }
                }
            }
        }
    }

//MARK: EditorView

struct EditorView: View {
    @Binding var text: String
    @Binding var isEditing: Bool
    let placeholder: String
    let maxCharacters: Int
    let title: String
    @FocusState var isFocused: Bool

    var body: some View {
        VStack {
            ZStack {
                VStack {
                    HStack() {
                        Text(title)
                            .fontWeight(.bold)
                        
                        Spacer()
                        
                        Button {
                            isEditing = false
                            isFocused = false
                        } label: {
                            Text("Done")
                                .fontWeight(.bold)
                                
                        }
                        .padding(8)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .padding(.horizontal, 10)
                        
                    }
                    .padding(.top, 10)
                    .frame(width: 330)
                    
                    Divider()
                    
                    TextEditor(text: $text)
                        .font(.subheadline)
                        .background(Color.white)
                        .frame(width: 330, height: 150)
                        .focused($isFocused)
                    
                    HStack {
                        Spacer()
                        
                        Text("\(maxCharacters - text.count) characters remaining")
                            .font(.caption)
                            .foregroundColor(text.count > maxCharacters ? .red : .gray)
                            .padding(.horizontal, 10)
                    }
                    
                }
                .onChange(of: text) {
                    if text.count > maxCharacters {
                        text = String(text.prefix(maxCharacters))
                    }
                }
                .padding(.bottom, 5)
                .frame(width: 350)
                .background(Color.white)
                .cornerRadius(10)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.8))
    }
}


//MARK: COVER PHOTO SELECTOR
struct CoverPhotoSelector: View{
    @ObservedObject var viewModel: CollectionsViewModel
    var body: some View {
        PhotosPicker(selection: $viewModel.selectedImage) {
            VStack {
                if let image = viewModel.coverImage {
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: 200, height: 200)
                        .clipShape(Rectangle())
                        .foregroundColor(Color(.systemGray4))
                        .cornerRadius(10)
                } else if let image = viewModel.selectedCollection?.coverImageUrl, !image.isEmpty {
                    KFImage(URL(string: viewModel.editImageUrl))
                        .resizable()
                        .scaledToFill()
                        .frame(width: 200, height: 200)
                        .clipShape(Rectangle())
                        .foregroundColor(Color(.systemGray4))
                        .cornerRadius(10)
                } else {
                    ZStack {
                        //MARK: Cover Photo
                        Rectangle()
                            .fill(.gray.opacity(0.1))
                            .cornerRadius(10)
                            .frame(width: 200, height: 200)
                        VStack{
                            Image(systemName: "plus")
                                .padding()
                        }
                        
                    }
                }
                if viewModel.coverImage == nil && viewModel.editImageUrl.isEmpty {
                    Text("Add a Cover Photo")
                        .font(.footnote)
                        .fontWeight(.semibold)
                } else {
                    Text("Edit Cover Photo")
                        .font(.footnote)
                        .fontWeight(.semibold)
                }
            }
        }
        .padding(.vertical, 8)
    }
    
}

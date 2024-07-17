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
                ScrollView{
                    VStack {
                        CoverPhotoSelector(viewModel: collectionsViewModel)
                        //MARK: Title Box
                        ZStack(alignment: .topLeading) {
                            TextEditor(text: $collectionsViewModel.editTitle)
                                .font(.custom("MuseoSansRounded-300", size: 16))
                                .frame(height: 75)
                                .padding(.horizontal, 20)
                                .background(Color.white)
                                .cornerRadius(5)
                            if collectionsViewModel.editTitle.isEmpty {
                                Text("Enter a Title...")
                                    .font(.custom("MuseoSansRounded-300", size: 16))
                                    .foregroundColor(Color.gray)
                                    .padding(.horizontal, 25)
                                    .padding(.top, 8)
                            }
                        }
                        
                        .padding(.vertical)
                        //MARK: CaptionBox
                        ZStack(alignment: .topLeading) {
                            TextEditor(text: $collectionsViewModel.editDescription)
                                .font(.custom("MuseoSansRounded-300", size: 16))
                                .frame(height: 75)
                                .padding(.horizontal, 20)
                                .background(Color.white)
                                .cornerRadius(5)
                                .toolbar {
                                    ToolbarItemGroup(placement: .keyboard) {
                                        Spacer()
                                        Button("Done") {
                                            dismissKeyboard()
                                        }
                                    }
                                }
                            if collectionsViewModel.editDescription.isEmpty {
                                Text("Enter a description...")
                                    .font(.custom("MuseoSansRounded-300", size: 16))
                                    .foregroundColor(Color.gray)
                                    .padding(.horizontal, 25)
                                    .padding(.top, 8)
                            }
                        }
                        
                        
                        //MARK: Item Preview if theres an item
                        if let item = collectionsViewModel.convertPostToCollectionItem() {
                            LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                                CollectionItemCell(item: item, previewMode: true, viewModel: collectionsViewModel)
                            }
                            .padding(.top)
                            //Restaurant preview
                        } else if let item = collectionsViewModel.convertRestaurantToCollectionItem() {
                            LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                                CollectionItemCell(item: item, previewMode: true, viewModel: collectionsViewModel)
                            }
                            .padding(.top)
                            
                            Spacer()
                                .padding(.vertical)
                        }
                    }
                }
                    .overlay(alignment: .bottom) {
                        //MARK: Create Collection Button
                        
                        Button {
                            Task {
                                if collectionsViewModel.post != nil || collectionsViewModel.restaurant != nil {
                                    collectionsViewModel.dismissListView.toggle()
                                }
                                try await collectionsViewModel.uploadCollection()
                                // Dismiss all the views
                                dismiss()
                            }
                        } label: {
                            if collectionsViewModel.post != nil || collectionsViewModel.restaurant != nil{
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
                        .frame(maxWidth: .infinity)
                        .padding(.top)
                        .background(.white)
                        
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
            .onAppear{
                print("third viewModel post", collectionsViewModel.post)
                print("third viewModel restaurant", collectionsViewModel.restaurant)
            }
                //.onDisappear{collectionsViewModel.resetViewModel()}
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
    CreateCollectionDetails(collectionsViewModel: CollectionsViewModel(), dismissCollectionsList: .constant(false))
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
                        .foregroundColor(text.isEmpty ? .clear : .primary)
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
                    .font(.custom("MuseoSansRounded-300", size: 10))
                    .foregroundColor(text.count > maxCharacters ? Color("Colors/AccentColor"): .gray)
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
                        .background(Color("Colors/AccentColor"))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .padding(.horizontal, 10)
                        
                    }
                    .padding(.top, 10)
                    .frame(width: 330)
                    
                    Divider()
                    
                    TextEditor(text: $text)
                        .font(.custom("MuseoSansRounded-300", size: 16))
                        .background(Color.white)
                        .frame(width: 330, height: 150)
                        .focused($isFocused)
                    
                    HStack {
                        Spacer()
                        
                        Text("\(maxCharacters - text.count) characters remaining")
                            .font(.custom("MuseoSansRounded-300", size: 10))
                            .foregroundColor(text.count > maxCharacters ? Color("Colors/AccentColor") : .gray)
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
        .background(Color.primary.opacity(0.8))
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
                        .font(.custom("MuseoSansRounded-300", size: 10))
                        .fontWeight(.semibold)
                } else {
                    Text("Edit Cover Photo")
                        .font(.custom("MuseoSansRounded-300", size: 10))
                        .fontWeight(.semibold)
                }
            }
        }
        .padding(.vertical, 8)
    }
    
}

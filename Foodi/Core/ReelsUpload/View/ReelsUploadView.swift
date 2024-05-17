//
//  ReelsUploadView.swift
//  Foodi
//
//  Created by Jack Robinson on 4/21/24.
//

import SwiftUI
import AVKit
import AVFoundation

struct ReelsUploadView: View {
    
    // VIEW MODEL
    @ObservedObject var uploadViewModel: UploadViewModel
    @ObservedObject var cameraViewModel: CameraViewModel
        
    // SHOW POP UPS AND SELECTION VIEWS
    @FocusState private var isCaptionEditorFocused: Bool
    @State private var isEditingCaption = false
    @State var isPickingRestaurant = false
    @State var isAddingRecipe = false
    @State var showPostTypeMenu: Bool = true
    @State var titleText: String = ""
    private let maxCharacters = 50
    // POST TYPE OPTIONS
    let postTypeOptions = ["restaurant", "atHome"]
    
    var body: some View {
        
            ZStack {
                VStack {
                    if uploadViewModel.mediaType == "video" {
                        FinalVideoPreview(uploadViewModel: uploadViewModel)
                            .frame(width: 156, height: 337.6)
                            .cornerRadius(10)
                    } else if uploadViewModel.mediaType == "photo" {
                        FinalPhotoPreview(uploadViewModel: uploadViewModel)
                            .frame(width: 156, height: 337.6)
                            .cornerRadius(10)
                    } else {
                        Rectangle()
                            .frame(width: 156, height: 337.6)
                            .cornerRadius(10)
                            .foregroundStyle(.black)
                    }
                    if uploadViewModel.postType == "atHome" {
                        ZStack(alignment: .topLeading){
                            TextField("Give your cooking post a title!*...", text: $titleText)
                                .font(.title3)
                                .background(Color.white)
                                .frame(height: 75)
                                .padding(.horizontal, 20)
//                                .padding(.horizontal, 20)
//                                .toolbar {
//                                                        ToolbarItem(placement: .keyboard) {
//                                                            HStack {
//                                                                Spacer()
//                                                                Button("Done") {
//                                                                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
//                                                                }
//                                                            }
//                                                        }
//                                                    }
//                            if titleText.isEmpty {
//                                Text("Give your cooking post a title!*...")
//                                    .font(.title3)
//                                    .foregroundColor(.gray)
//                                    .padding(.horizontal, 20)
//                                    .padding(.vertical, 12)
//                                    
//                                
//                            }
                        }
                        .onChange(of: titleText) {
                            if titleText.count > maxCharacters {
                                titleText = String(titleText.prefix(maxCharacters))
                            }
                        }
                        
                        
                        HStack {
                            Spacer()
                            
                            Text("\(maxCharacters - titleText.count) characters remaining")
                                .font(.caption)
                                .foregroundColor(titleText.count > maxCharacters ? .red : .gray)
                                .padding(.horizontal, 10)
                        }
                        }
                        Divider()
                    //}
                    Button(action: {
                        self.isEditingCaption = true
                    }) {
                        CaptionBox(caption: $uploadViewModel.caption, isEditingCaption: $isEditingCaption)
                    }
                    
                    PostOptions(uploadViewModel: uploadViewModel,
                                isPickingRestaurant: $isPickingRestaurant,
                                isAddingRecipe: $isAddingRecipe)
                    
                    Button {
                        Task {
                            if uploadViewModel.postType == "atHome" {
                                uploadViewModel.recipeTitle = titleText
                                uploadViewModel.savedRecipe = true
                            }
                            await uploadViewModel.uploadPost()
                            uploadViewModel.reset()
                            cameraViewModel.reset()
                        }
                        
                    } label: {
                        
                        Text(uploadViewModel.isLoading ? "" : "Post")
                            .frame(width: 90, height: 45)
                            .background(.blue)
                            .foregroundColor(.white)
                            .cornerRadius(7)
                            .overlay {
                                if uploadViewModel.isLoading {
                                    ProgressView()
                                        .tint(.white)
                                }
                                
                            }
                    }
                    .opacity(uploadViewModel.postType == "atHome" && titleText.isEmpty ? 0.5 : 1.0)
                    .disabled(
                        uploadViewModel.postType == "atHome" && titleText.isEmpty)
                    
                    Spacer()
                }
               
                .padding(.vertical)
                .blur(radius: showPostTypeMenu ? 10 : 0)
                
                if isEditingCaption {
                    CaptionEditorView(caption: $uploadViewModel.caption, isEditingCaption: $isEditingCaption)
                        .focused($isCaptionEditorFocused) // Connects the focus state to the editor view
                        .onAppear {
                            isCaptionEditorFocused = true // Automatically focuses the TextEditor when it appears
                        }
                }
                
                if showPostTypeMenu {
                    PostTypeMenuView(uploadViewModel: uploadViewModel, showPostTypeMenu: $showPostTypeMenu)
                }
            }
            .navigationBarHidden(showPostTypeMenu)
            .navigationTitle(uploadViewModel.postType)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarTitleMenu {
                ForEach(postTypeOptions, id: \.self) { posttype in
                    Button {
                        uploadViewModel.postType = posttype
                    } label: {
                        if uploadViewModel.postType == posttype {
                            HStack {
                                Text(posttype)
                                    .foregroundColor(.black)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .padding()
                                
                                Spacer()
                                
                                Image(systemName: "checkmark")
                                    .foregroundColor(.black)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .padding()
                            }
                        } else {
                            Text(posttype)
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding()
                                
                        }
                    }
                }
            }
            .toolbarBackground(.white, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .preferredColorScheme(.light)
            //POSS Check if keyboard is active here
            .onTapGesture {
                dismissKeyboard()
            }
            .gesture(
                DragGesture().onChanged { value in
                    if value.translation.height > 50 {
                        dismissKeyboard()
                    }
                }
            )
            .navigationDestination(isPresented: $isPickingRestaurant) {
                SelectRestaurantListView(uploadViewModel: uploadViewModel)
                    .navigationTitle("Select Restaurant")
            }
            .navigationDestination(isPresented: $isAddingRecipe) {
                RecipeView(uploadViewModel: uploadViewModel)
                    .navigationTitle("Create Recipe")
            }
    }
    
    
    // Dismiss keyboard method
    private func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

#Preview {
    ReelsUploadView(uploadViewModel: UploadViewModel(), cameraViewModel: CameraViewModel(), showPostTypeMenu: false)
}




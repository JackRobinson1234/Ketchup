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
 
    // POST TYPE OPTIONS
    let postTypeOptions = ["At Home Post", "Going Out Post"]
    
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
                    }
                    
                    
                    Button(action: {
                        self.isEditingCaption = true
                    }) {
                        CaptionBox(caption: $uploadViewModel.caption, isEditingCaption: $isEditingCaption)
                    }
                    
                    PostOptions(uploadViewModel: uploadViewModel,
                                isPickingRestaurant: $isPickingRestaurant,
                                isAddingRecipe: $isAddingRecipe)
                    
                    Button {
                        // hande errors
                        Task {
                            await uploadViewModel.uploadPost()
                            uploadViewModel.reset()
                            cameraViewModel.reset()
                        }
                        
                    } label: {
                         Text("Post")
                            .frame(width: 90, height: 45)
                            .background(.blue)
                            .foregroundColor(.white)
                            .cornerRadius(7)
                    }
                    
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
                SelectRestaurantListView()
                    .navigationTitle("Select Restaurant")
            }
            .navigationDestination(isPresented: $isAddingRecipe) {
                JoeRecipeView(uploadViewModel: uploadViewModel)
                    .navigationTitle("Create Recipe")
            }
    }
    
    
    // Dismiss keyboard method
    private func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    
}

struct CaptionBox: View {
    
    @Binding var caption: String
    @Binding var isEditingCaption: Bool
    let maxCharacters = 150
    
    var body: some View {
        VStack {
            
            ScrollView {
                ZStack(alignment: .leading) {
                    
                    TextEditor(text: $caption)
                        .foregroundColor(caption.isEmpty ? .clear : .primary) // Hide text editor text when empty and showing placeholder
                        .disabled(true)  // Disables editing directly in this view
                        .frame(maxHeight: .infinity) // Allows for flexible height
                        .multilineTextAlignment(.leading)
                        .onTapGesture {
                            isEditingCaption = true // Activate editing mode
                        }
                    
                    if caption.isEmpty {
                        Text("Enter caption...")
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
                Text("\(maxCharacters - caption.count) characters remaining")
                    .font(.caption)
                    .foregroundColor(caption.count > maxCharacters ? .red : .gray)
                    .padding(.horizontal, 10)
            }
        }
    }
}


struct FinalVideoPreview: View {
    
    @ObservedObject var uploadViewModel: UploadViewModel
    
    var body: some View {
        
        if let url = uploadViewModel.videoURL {
            let player = AVPlayer(url: url)
            ZStack {
                if uploadViewModel.fromInAppCamera {
                    VideoPlayer(player: player, videoGravity: .resizeAspectFill)
                } else {
                    VideoPlayer(player: player, videoGravity: .resizeAspect)
                }
            }
        }
    }
}


struct FinalPhotoPreview: View {
    
    @ObservedObject var uploadViewModel: UploadViewModel
    
    @State private var currentPage = 0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                TabView(selection: $currentPage) {
                    ForEach(uploadViewModel.images!.indices, id: \.self) { index in
                        if uploadViewModel.fromInAppCamera {
                            Image(uiImage: uploadViewModel.images![index])
                                .resizable()
                                .scaledToFill()
                                .tag(index)
                        } else {
                            Image(uiImage: uploadViewModel.images![index])
                                .resizable()
                                .scaledToFit()
                                .tag(index)
                        }
                    }
                }
                .background(.black)
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
                .frame(width: geometry.size.width, height: geometry.size.height)
            }
        }
    }
}

struct CaptionEditorView: View {
    
    @Binding var caption: String
    @Binding var isEditingCaption: Bool
    let maxCharacters = 150
    @FocusState var isFocused: Bool
    
    var body: some View {
        VStack {
            ZStack {
                VStack {
                    
                    HStack() {
                        Text("Caption")
                            .fontWeight(.bold)
                        
                        Spacer()
                        
                        Button {
                            isEditingCaption = false
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
                    
                    TextEditor(text: $caption)
                        .font(.subheadline)
                        .background(Color.white)
                        .frame(width: 330, height: 150)
                        .focused($isFocused)
                    
                    HStack {
                        Spacer()
                        
                        Text("\(maxCharacters - caption.count) characters remaining")
                            .font(.caption)
                            .foregroundColor(caption.count > maxCharacters ? .red : .gray)
                            .padding(.horizontal, 10)
                    }
                    
                }
                .onChange(of: caption) {
                    if caption.count > maxCharacters {
                        caption = String(caption.prefix(maxCharacters))
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

struct PostOptions: View {

    @ObservedObject var uploadViewModel: UploadViewModel
    @Binding var isPickingRestaurant: Bool
    @Binding var isAddingRecipe: Bool
    
    var body: some View {
        VStack {
            Divider()
            if uploadViewModel.postType == "At Home Post" {
      
                Button {
                    isAddingRecipe = true
                } label: {
                    // ADD RECIPE
                    
                    if !uploadViewModel.savedRecipe {
                        HStack {
                            Image(systemName: "book.circle")
                                .resizable()
                                .foregroundColor(.black)
                                .frame(width: 40, height: 40, alignment: .center)
                            
                            Text("Add recipe")
                                .foregroundColor(.black)
                            
                            Spacer()
                            
                            Image(systemName: "plus")
                                .resizable()
                                .foregroundColor(.gray)
                                .frame(width: 15, height: 15)
                        }
                        .padding(.horizontal , 15)
                        .padding(.vertical, 3)
                    } else {
                        HStack {
                            Image(systemName: "book.circle")
                                .resizable()
                                .foregroundColor(.black)
                                .frame(width: 40, height: 40, alignment: .center)
                            
                            Text("Recipe Saved")
                                .foregroundColor(.black)
                            
                            Spacer()
                            
                            Image(systemName: "checkmark.circle")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .foregroundColor(.green)
                                .frame(width: 20, height: 20)
                        }
                        .padding(.horizontal , 15)
                        .padding(.vertical, 3)
                    }
                    
                    
                }
            } else if uploadViewModel.postType == "Going Out Post" {
                if let restaurant = uploadViewModel.restaurant {
                    Button {
                        isPickingRestaurant = true
                    } label: {
                        // REPLACE RESTAURANT
                        HStack {
                            RestaurantCircularProfileImageView(imageUrl: restaurant.profileImageUrl, size: .small)
                                .frame(width: 40, height: 40, alignment: .center)
                            
                            Text(restaurant.name)
                                .foregroundColor(.black)
                            
                            Spacer()
                            
                            Image(systemName: "checkmark.circle")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .foregroundColor(.green)
                                .frame(width: 20, height: 20)
                        }
                        .padding(.horizontal , 15)
                        .padding(.vertical, 3)
                    }
                } else {
                    Button {
                        isPickingRestaurant = true
                    } label: {
                        // ADD RESTAURANT
                        HStack {
                            Image(systemName: "fork.knife.circle")
                                .resizable()
                                .foregroundColor(.black)
                                .frame(width: 40, height: 40, alignment: .center)
                            
                            Text("Add restaurant")
                                .foregroundColor(.black)
                            
                            Spacer()
                            
                            Image(systemName: "plus")
                                .resizable()
                                .foregroundColor(.gray)
                                .frame(width: 15, height: 15)
                        }
                        .padding(.horizontal , 15)
                        .padding(.vertical, 3)
                    }
                }
            }

            Divider()
            // TAG USER
//            HStack {
//                Image(systemName: "person.badge.plus")
//                    .resizable()
//                    .foregroundColor(.black)
//                    .frame(width: 40, height: 40, alignment: .center)
//                
//                Text("Tag User")
//                
//                Spacer()
//                
//                Image(systemName: "plus")
//                    .resizable()
//                    .foregroundColor(.gray)
//                    .frame(width: 15, height: 15)
//            }
//            .padding(.horizontal , 15)
//            .padding(.vertical, 3)
//            Divider()
//            
//            HStack {
//                Image(systemName: "list.bullet.rectangle.portrait")
//                    .resizable()
//                    .foregroundColor(.black)
//                    .scaledToFit()
//                    .frame(width: 40, height: 35, alignment: .center)
//                    .frame(width: 40, height: 40, alignment: .center)
//                
//                Text("Add to collection")
//                
//                Spacer()
//                
//                Image(systemName: "plus")
//                    .resizable()
//                    .foregroundColor(.gray)
//                    .frame(width: 15, height: 15)
//                
//            }
//            .padding(.horizontal , 15)
//            .padding(.vertical, 3)
//            
//            Divider()
        }
    }
}

import SwiftUI
import InstantSearchSwiftUI

struct SelectRestaurantListView: View {
    @StateObject var viewModel: RestaurantListViewModel
    @Environment(\.dismiss) var dismiss
    var debouncer = Debouncer(delay: 1.0)
    init() {
        
        self._viewModel = StateObject(wrappedValue: RestaurantListViewModel())}
    
    var body: some View {
        InfiniteList(viewModel.hits, itemView: { hit in
            NavigationLink(value: hit.object) {
                RestaurantCell(restaurant: hit.object)
                    .padding()
            }
            Divider()
        }, noResults: {
            Text("No results found")
        })
        .navigationTitle("Explore")
        .searchable(text: $viewModel.searchQuery,
                    prompt: "Search")
        .onChange(of: viewModel.searchQuery) {
            debouncer.schedule {
                viewModel.notifyQueryChanged()
            }
        }
        
    }
}


#Preview {
    RestaurantListView()
}


struct PostTypeMenuView: View {
    
    @ObservedObject var uploadViewModel: UploadViewModel
    @Binding var showPostTypeMenu: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            Divider()
            
            Text("Select Post Type")
                .font(.headline)
                .fontWeight(.bold)
                .frame(height: 50)
            
            Divider()
                .frame(width: 260)
            
            HStack(spacing: 0) {
                Button(action: {
                    uploadViewModel.postType = "At Home Post"
                    showPostTypeMenu = false
                }) {
                    VStack {
                        Image(systemName: "house.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 40)
                            .foregroundColor(.black)
                            .opacity(0.6)
                                    
                        Text("At Home Post")
                            .font(.subheadline)
                            .foregroundColor(.black)
                    }
                    .frame(width: 130, height: 100)
                }
                
                Divider()
                    .frame(height: 100)
                
                Button(action: {
                    uploadViewModel.postType = "Going Out Post"
                    showPostTypeMenu = false
                }) {
                    VStack {
                        Image(systemName: "fork.knife")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 40)
                            .foregroundColor(.black)
                            .opacity(0.6)
                        
                        Text("Going Out Post")
                            .font(.subheadline)
                            .foregroundColor(.black)
                    }
                    .frame(width: 130, height: 100)
                }
            }
            
            Divider()
        }
        .frame(width: 260)
        .background(Color.white)
        .cornerRadius(10)
        .shadow(radius: 5)
    }
}

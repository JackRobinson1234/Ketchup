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
    //@State var showPostTypeMenu: Bool = true
    @State var titleText: String = ""
    private let maxCharacters = 25
    let postTypeOptions: [PostType] = [.dining]
    private let spacing: CGFloat = 20
    private var width: CGFloat {
        (UIScreen.main.bounds.width - (spacing * 2)) / 3
    }
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    
    var body: some View {
        ZStack {
            VStack {
                HStack{
                    Spacer()
//                    if uploadViewModel.postType == .cooking {
//                        VStack{
//                            ZStack(alignment: .topLeading){
//                                ZStack(alignment: .topLeading) {
//                                    TextEditor(text: $titleText)
//                                        .font(.title3)
//                                        .frame(height: 75)
//                                        .padding(.horizontal, 20)
//                                        .background(Color.white)
//                                        .cornerRadius(5)
//                                    if titleText.isEmpty {
//                                        Text("Create a title...")
//                                            .font(.title3)
//                                            .foregroundColor(Color.gray)
//                                            .padding(.horizontal, 25)
//                                            .padding(.top, 8)
//                                    }// Optional: Adds rounded corners to the text editor
//                                }
//                                
//                            }
//                            .onChange(of: titleText) {
//                                if titleText.count > maxCharacters {
//                                    titleText = String(titleText.prefix(maxCharacters))
//                                }
//                            }
//                            
//                            
//                            HStack {
//                                Spacer()
//                                
//                                Text("\(titleText.count)/\(maxCharacters)")
//                                    .font(.caption)
//                                    .foregroundColor(titleText.count == 0 ? Color("Colors/AccentColor") : .gray)
//                                    .padding(.horizontal, 10)
//                            }
//                        }
//                        
//                    } else if uploadViewModel.postType == .dining {
                        Button {
                            isPickingRestaurant = true
                        } label: {
                            if uploadViewModel.restaurant == nil && uploadViewModel.restaurantRequest == nil{
                                VStack {
                                    Image(systemName: "plus")
                                        .font(.largeTitle) // Adjust the size as needed
                                        .foregroundColor(Color("Colors/AccentColor"))
                                    Text("Add a restaurant")
                                        .foregroundColor(.primary)
                                }
                            } else if let restaurant = uploadViewModel.restaurant{
                                VStack{
                                    RestaurantCircularProfileImageView(imageUrl: uploadViewModel.restaurant?.profileImageUrl, size: .xLarge)
                                    Text(restaurant.name)
                                        .font(.title)
                                    if let cuisine = restaurant.cuisine, let price = restaurant.price {
                                        Text("\(cuisine), \(price)")
                                            .font(.caption)
                                            .foregroundStyle(.primary)
                                        
                                        
                                    } else if let cuisine = restaurant.cuisine {
                                        Text(cuisine)
                                            .font(.caption)
                                            .foregroundStyle(.primary)
                                        
                                        
                                    } else if let price = restaurant.price {
                                        Text(price)
                                            .font(.caption)
                                            .foregroundStyle(.primary)
                                    }
                                    if let address = restaurant.address{
                                        Text(address)
                                            .font(.caption)
                                            .foregroundStyle(.primary)
                                    }
                                    Text("Edit")
                                        .foregroundStyle(Color("Colors/AccentColor"))
                                        .font(.caption)
                                    
                                }
                            } else if let request = uploadViewModel.restaurantRequest {
                                VStack{
                                    RestaurantCircularProfileImageView(size: .xLarge)
                                    Text(request.name)
                                        .font(.title)
                                    Text("\(request.city), \(request.state)")
                                        .font(.caption)
                                    Text("(To be created)")
                                        .foregroundStyle(.gray)
                                        .font(.footnote)
                                    Text("Edit")
                                        .foregroundStyle(Color("Colors/AccentColor"))
                                        .font(.caption)
                                }
                            }
                        }
                    //}
                    Spacer()
                    if uploadViewModel.mediaType == "video" {
                        FinalVideoPreview(uploadViewModel: uploadViewModel)
                            .frame(width: width, height: 150) // Half of the original dimensions
                            .cornerRadius(5) // Adjusted corner radius to maintain proportionality
                    } else if uploadViewModel.mediaType == "photo" {
                        FinalPhotoPreview(uploadViewModel: uploadViewModel)
                            .frame(width: width, height: 150) // Half of the original dimensions
                            .cornerRadius(5) // Adjusted corner radius to maintain proportionality
                    } else {
                        Rectangle()
                            .frame(width: width, height: 150) // Half of the original dimensions
                            .cornerRadius(5) // Adjusted corner radius to maintain proportionality
                            .foregroundStyle(.primary)
                    }
                    Spacer()
                }
                .padding(.vertical)
                
                Divider()
                VStack{
                    ZStack(alignment: .topLeading){
                        TextEditor(text: $uploadViewModel.caption)
                            .font(.subheadline)
                            .frame(height: 75)
                            .padding(.horizontal, 20)
                            .background(Color.white)
                            .cornerRadius(5)
                        
                        if uploadViewModel.caption.isEmpty {
                            Text("Enter a caption...")
                                .font(.subheadline)
                                .foregroundColor(Color.gray)
                                .padding(.horizontal, 25)
                                .padding(.top, 8)
                        }
                    }
                    HStack {
                        Spacer()
                        
                        Text("\(uploadViewModel.caption.count)/\(150)")
                            .font(.caption)
                            .foregroundColor( .gray)
                            .padding(.horizontal, 10)
                    }
                }
                .onChange(of: uploadViewModel.caption) {
                    if uploadViewModel.caption.count >= 150 {
                        uploadViewModel.caption = String(uploadViewModel.caption.prefix(150))
                    }
                }
                Divider()
                
                
//                if uploadViewModel.postType == .cooking{
//                    Button {
//                        isAddingRecipe = true
//                    } label: {
//                        // ADD RECIPE
//                        if !uploadViewModel.hasRecipeDetailsChanged() {
//                            HStack {
//                                Image("BlackChefHat")
//                                    .resizable()
//                                    .frame(width: 40, height: 40, alignment: .center)
//                                    .opacity(0.2)
//                                
//                                Text("Add recipe")
//                                    .font(.subheadline)
//                                    .foregroundColor(.gray)
//                                
//                                Spacer()
//                                
//                                Image(systemName: "chevron.right")
//                                    .foregroundColor(.gray)
//                                
//                            }
//                            .padding(.horizontal , 15)
//                            .padding(.vertical, 3)
//                        } else {
//                            HStack {
//                                Image(systemName: "checkmark")
//                                    .foregroundStyle(.green)
//                                    .padding(.trailing, 30)
//                                Image("BlackChefHat")
//                                    .resizable()
//                                    .frame(width: 40, height: 40, alignment: .center)
//                                
//                                Text("Edit Recipe")
//                                    .foregroundColor(.primary)
//                                
//                                Spacer()
//                                
//                                Image(systemName: "chevron.right")
//                                    .foregroundStyle(.gray)
//                            }
//                            .padding(.horizontal , 15)
//                            .padding(.vertical, 3)
//                        }
//                    }
//                    Divider()
//                } else {
                    HStack(spacing: 20) {
                        Button(action: { uploadViewModel.recommend = true }) {
                            VStack {
                                Image(systemName: "heart")
                                    .foregroundColor(uploadViewModel.recommend == true ? Color("Colors/AccentColor") : .gray)
                                    .font(.title)
                                Text("Recommend")
                                    .font(.caption)
                                    .foregroundStyle(uploadViewModel.recommend == true ? Color("Colors/AccentColor") : .gray)
                            }
                        }
                        
                        Button(action: { uploadViewModel.recommend = false }) {
                            VStack {
                                Image(systemName: "heart.slash")
                                    .foregroundColor(uploadViewModel.recommend == false ? .primary : .gray)
                                    .font(.title)
                                Text("Don't Recommend")
                                    .font(.caption)
                                    .foregroundStyle(uploadViewModel.recommend == false ? .black : .gray)
                            }
                        }
                    }
                    .padding(20)
                //}
                Spacer()
                Button {
                    if uploadViewModel.postType == .cooking && titleText.isEmpty {
                        alertMessage = "Please add a title for your post."
                        showAlert = true
                    } else if uploadViewModel.postType == .dining && (uploadViewModel.restaurant == nil && uploadViewModel.restaurantRequest == nil) {
                        alertMessage = "Please select a restaurant."
                        showAlert = true
                    } else {
                        Task {
                            if uploadViewModel.postType == .cooking {
                                uploadViewModel.recipeTitle = titleText
                            }
                            await uploadViewModel.uploadPost()
                            uploadViewModel.reset()
                            cameraViewModel.reset()
                        }
                    }
                } label: {
                    Text(uploadViewModel.isLoading ? "" : "Post")
                        .modifier(StandardButtonModifier(width: 90))
                        .overlay {
                            if uploadViewModel.isLoading {
                                ProgressView()
                                    .tint(.white)
                            }
                        }
                }
                .opacity(uploadViewModel.postType == .cooking && titleText.isEmpty ? 0.5 : 1.0)

                .opacity(uploadViewModel.postType == .dining && (uploadViewModel.restaurant == nil && uploadViewModel.restaurantRequest == nil) ? 0.5 : 1.0)
                .alert(isPresented: $showAlert) {
                    Alert(title: Text("Enter Details"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
                }
            }
            
            .padding()
            //.blur(radius: showPostTypeMenu ? 10 : 0)
            
//            if showPostTypeMenu {
//                PostTypeMenuView(uploadViewModel: uploadViewModel, showPostTypeMenu: $showPostTypeMenu)
//            }
        }
        //.navigationBarHidden(showPostTypeMenu)
        //.navigationTitle(uploadViewModel.postType?.postTypeTitle ?? "Select a Post Type")
        .navigationBarTitleDisplayMode(.inline)
//        .toolbarTitleMenu {
//            ForEach(postTypeOptions, id: \.self) { posttype in
//                Button {
//                    uploadViewModel.postType = posttype
//                } label: {
//                    if uploadViewModel.postType == posttype {
//                        HStack {
//                            Text(posttype == .cooking ? "Cooking" : "Dining")
//                                .foregroundColor(.primary)
//                                .frame(maxWidth: .infinity, alignment: .center)
//                                .padding()
//                            
//                            Spacer()
//                            
//                            Image(systemName: "checkmark")
//                                .foregroundColor(.primary)
//                                .frame(maxWidth: .infinity, alignment: .center)
//                                .padding()
//                        }
//                    } else {
//                        Text(posttype.postTypeTitle)
//                            .foregroundColor(.primary)
//                            .frame(maxWidth: .infinity, alignment: .center)
//                            .padding()
//                        
//                    }
//                }
//            }
//        }
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
            EditRecipeView(uploadViewModel: uploadViewModel)
        }
    }
    
    
    // Dismiss keyboard method
    private func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

#Preview {
    ReelsUploadView(uploadViewModel: UploadViewModel(), cameraViewModel: CameraViewModel())
}


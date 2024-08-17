//
//  EditProfileView.swift
//  Foodi
//
//  Created by Jack Robinson on 2/1/24.
//

import SwiftUI
import Kingfisher
import PhotosUI

import SwiftUI
import PhotosUI
import SwiftyCrop

struct EditProfileView: View {
    @State private var username = ""
    @StateObject private var viewModel: EditProfileViewModel
    @Binding var user: User
    @Environment(\.dismiss) var dismiss
    @State private var showLocationEdit = false
    @State private var showCancelAlert = false
     @State private var hasChanges = false
    var usernameDebouncer = Debouncer(delay: 2.0)
    
    init(user: Binding<User>) {
        self._user = user
        self._username = State(initialValue: _user.wrappedValue.username)
        self._viewModel = StateObject(wrappedValue: EditProfileViewModel(user: user.wrappedValue))
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                VStack(spacing: 8) {
                    Divider()
                    //MARK: profile image
                    PhotosPicker(selection: $viewModel.selectedImage, matching: .images,
                                 photoLibrary: .shared()) {
                        VStack {
                            if let image = viewModel.profileImage {
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 72, height: 72)
                                    .clipShape(Circle())
                                    .foregroundColor(Color(.systemGray4))
                            } else {
                                UserCircularProfileImageView(profileImageUrl: user.profileImageUrl, size: .large)
                            }
                            Text("Edit profile picture")
                                .font(.custom("MuseoSansRounded-300", size: 10))
                                .fontWeight(.semibold)
                        }
                    }
                    .padding(.vertical, 8)
                    
                    Divider()
                }
                .padding(.bottom, 4)
                //MARK: Edit username
                VStack {
                    EditProfileRowView(title: "Username", placeholder: "Enter your username..", text: $viewModel.username)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .onChange(of: viewModel.username) { oldValue, newValue in
                               // Remove any characters that are not allowed
                               let allowedCharacters = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789._")
                               viewModel.username = newValue.filter { char in
                                   char.unicodeScalars.allSatisfy { allowedCharacters.contains($0) }
                               }
                               
                               // Convert to lowercase
                               viewModel.username = viewModel.username.lowercased()
                               
                               // Remove leading and trailing periods
                               viewModel.username = viewModel.username.trimmingCharacters(in: CharacterSet(charactersIn: "."))
                               
                               // Limit to 30 characters (Instagram's limit)
                               if viewModel.username.count > 25 {
                                   viewModel.username = String(viewModel.username.prefix(25))
                               }
                               
                               // Reset validation state
                               viewModel.validUsername = nil
                               
                               // Check availability if not empty
                               if !viewModel.username.isEmpty {
                                   usernameDebouncer.schedule {
                                       Task {
                                           try await viewModel.checkIfUsernameAvailable()
                                       }
                                   }
                               }
                           }
                    
                    //MARK: Username availability
                    if viewModel.username.count == 30 {
                        Text("Max 30 Characters")
                            .font(.custom("MuseoSansRounded-300", size: 10))
                    }
                    //MARK: Checking username
                    if viewModel.validUsername == nil && !viewModel.username.isEmpty && viewModel.username != user.username {
                        Text("Checking if username is available...")
                            .font(.custom("MuseoSansRounded-300", size: 10))
                            .foregroundStyle(.black)
                    }
                    //MARK: Available Username
                    else if let validUsername = viewModel.validUsername, validUsername && !viewModel.username.isEmpty && viewModel.username != user.username {
                        Text("Username Available!")
                            .font(.custom("MuseoSansRounded-300", size: 10))
                            .foregroundStyle(.green)
                    //MARK: Taken Username
                    } else if let validUsername = viewModel.validUsername, !validUsername && !viewModel.username.isEmpty && viewModel.username != user.username {
                        Text("Username is already taken. Please try a different username")
                            .font(.custom("MuseoSansRounded-300", size: 10))
                            .foregroundStyle(Color("Colors/AccentColor"))
                    }
                    //MARK: emptyUsername
                    if viewModel.username.count == 0 {
                        Text("Username cannot be empty")
                            .font(.custom("MuseoSansRounded-300", size: 10))
                            .foregroundStyle(Color("Colors/AccentColor"))
                    }

                    //MARK: Fullname
                    EditProfileRowView(title: "Name", placeholder: "Enter your name..", text: $viewModel.fullname)
                        .onChange(of: viewModel.fullname) { oldValue, newValue in
                            if newValue.count > 64 {
                                viewModel.fullname = String(newValue.prefix(64))
                            }
                        }
                    //MARK: fullname max
                    if viewModel.fullname.count == 64 {
                        Text("Max 64 Characters")
                            .font(.custom("MuseoSansRounded-300", size: 10))
                            .foregroundStyle(Color("Colors/AccentColor"))
                    }
                    //MARK: fullname empty
                    if viewModel.fullname.count == 0 {
                        Text("Full name cannot be empty")
                            .font(.custom("MuseoSansRounded-300", size: 10))
                            .foregroundStyle(Color("Colors/AccentColor"))
                    }
                    Button(action: {
                        showLocationEdit = true
                    }) {
                        HStack {
                            Text("Location")
                                .padding(.leading, 8)
                                .frame(width: 100, alignment: .leading)
                            
                            VStack(alignment: .leading) {
                                if let location = viewModel.location {
                                    Text("\(location.city ?? ""), \(location.state ?? "")")
                                } else {
                                    Text("Add location")
                                        .font(.custom("MuseoSansRounded-300", size: 10))
                                        .foregroundStyle(Color("Colors/AccentColor"))
                                }
                                Divider()
                            }
                        }
                        
                    }
                    .sheet(isPresented: $showLocationEdit) {
                        EditLocationView(editProfileViewModel: viewModel)
                            .presentationDetents([.height(UIScreen.main.bounds.height * 0.5)])
                    }
                    editFavoritesView(user: user, editProfileViewModel: viewModel)
                        .padding()
                }
                
                Spacer()
            }
            .toolbar {
                         ToolbarItem(placement: .navigationBarLeading) {
                             Button("Cancel") {
                                 if hasChanges {
                                     showCancelAlert = true
                                 } else {
                                     dismiss()
                                 }
                             }
                             .font(.custom("MuseoSansRounded-300", size: 16))
                         }
                         
                         ToolbarItem(placement: .navigationBarTrailing) {
                             Button("Save") {
                                 Task {
                                     try await viewModel.updateUserData()
                                     dismiss()
                                 }
                             }
                             .disabled(!formIsValid)
                             .opacity(formIsValid ? 1 : 0.5)
                             .font(.custom("MuseoSansRounded-300", size: 16))
                             .fontWeight(.semibold)
                         }
                     }
                     .onReceive(viewModel.$user, perform: { user in
                         self.user = user
                     })
                     .onChange(of: viewModel.username) { _, _ in checkForChanges() }
                     .onChange(of: viewModel.fullname) { _, _ in checkForChanges() }
                     .onChange(of: viewModel.location) { _, _ in checkForChanges() }
                     .onChange(of: viewModel.favoritesPreview) { _, _ in checkForChanges() }
                     .onChange(of: viewModel.croppedImage) { _, _ in checkForChanges() }
                     .alert(isPresented: $showCancelAlert) {
                         Alert(
                             title: Text("Discard Changes?"),
                             message: Text("You have unsaved changes. Are you sure you want to discard them?"),
                             primaryButton: .destructive(Text("Discard")) {
                                 dismiss()
                             },
                             secondaryButton: .cancel()
                         )
                     }
                     .navigationTitle("Edit Profile")
                     .navigationBarTitleDisplayMode(.inline)
                 }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    dismissKeyboard()
                }
            }
        }
        .fullScreenCover(isPresented: $viewModel.showingImageCropper) {
            let configuration = SwiftyCropConfiguration(
                //maskRadius: 130,
                //cropImageCircular: true,
                rotateImage: false
            )
            if let selectedImage = viewModel.uiImage {
                SwiftyCropView(
                    imageToCrop: selectedImage,
                    maskShape: .circle,
                    configuration: configuration
                ) { croppedImage in
                    if let croppedImage{
                        viewModel.setCroppedImage(croppedImage)
                    }
                }
            }
        }
    }
    private func checkForChanges() {
            hasChanges = viewModel.username != user.username ||
                         viewModel.fullname != user.fullname ||
                         viewModel.location != user.location ||
                         viewModel.favoritesPreview != user.favorites ||
                         viewModel.croppedImage != nil
        }
}

extension EditProfileView: AuthenticationFormProtocol {
    var formIsValid: Bool {
            guard let validUsername = viewModel.validUsername else {
                return false
            }
            
            let hasValidUsername = !viewModel.username.isEmpty && validUsername
            let hasFullName = !viewModel.fullname.isEmpty
            let hasLocation = viewModel.location != nil
            
            return hasValidUsername && hasFullName && hasLocation
        }
}

struct EditProfileRowView: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    
    var body: some View {
        HStack {
            Text(title)
                .padding(.leading, 8)
                .frame(width: 100, alignment: .leading)
                .autocorrectionDisabled()
                .autocapitalization(.none)
                            
            VStack {
                TextField(placeholder, text: $text)
                
                Divider()
            }
        }
        .font(.custom("MuseoSansRounded-300", size: 16))
        .frame(height: 36)
    }
}

struct editFavoritesView: View {
    let user: User
    @State private var fetchedRestaurant: Restaurant?
    @State private var isEditFavoritesShowing = false
    @State var oldSelection: FavoriteRestaurant = FavoriteRestaurant(name: "", id: "", restaurantProfileImageUrl: nil)
    @ObservedObject var editProfileViewModel: EditProfileViewModel
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Spacer()
            ForEach(editProfileViewModel.favoritesPreview) { favoriteRestaurant in
                VStack(spacing: 10) {
                    Button {
                        oldSelection = favoriteRestaurant
                        isEditFavoritesShowing.toggle()
                    } label: {
                        VStack {
                            Text("Edit")
                                .font(.custom("MuseoSansRounded-300", size: 10))
                                .foregroundStyle(.blue)
                            HStack {
                                VStack {
                                    ZStack(alignment: .bottom) {
                                        if let imageUrl = favoriteRestaurant.restaurantProfileImageUrl {
                                            RestaurantCircularProfileImageView(imageUrl: imageUrl, size: .medium)
                                        }
                                    }
                                    Text(favoriteRestaurant.name)
                                        .font(.custom("MuseoSansRounded-300", size: 10))
                                        .multilineTextAlignment(.center)
                                        .lineLimit(2)
                                        .frame(maxWidth: .infinity, alignment: .center)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                        }
                    }
                    if !favoriteRestaurant.name.isEmpty {
                        Button {
                            oldSelection = favoriteRestaurant
                            if let index = editProfileViewModel.favoritesPreview.firstIndex(of: oldSelection) {
                                editProfileViewModel.favoritesPreview[index] = FavoriteRestaurant(name: "", id: NSUUID().uuidString, restaurantProfileImageUrl: "")
                            }
                        } label: {
                            VStack {
                                Text("Clear")
                                    .foregroundStyle(Color("Colors/AccentColor"))
                                    .font(.custom("MuseoSansRounded-300", size: 10))
                            }
                        }
                    }
                }
                Spacer()
            }
        }
        .sheet(isPresented: $isEditFavoritesShowing) {
            FavoriteRestaurantSearchView(oldSelection: $oldSelection, editProfileViewModel: editProfileViewModel)
        }
    }
}

//
//  EditProfileView.swift
//  Foodi
//
//  Created by Jack Robinson on 2/1/24.
//

import SwiftUI
import Kingfisher
import PhotosUI

struct EditProfileView: View {
    @State private var username = ""
    @StateObject private var viewModel: EditProfileViewModel
    @Binding var user: User
    @Environment(\.dismiss) var dismiss
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
                    PhotosPicker(selection: $viewModel.selectedImage) {
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
                                    .font(.footnote)
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
                        .onChange(of: viewModel.username) {oldValue, newValue in
                            //lowercase and no space
                            viewModel.username = viewModel.username.trimmingCharacters(in: .whitespaces).lowercased()
                            //limits characters
                            if newValue.count > 25 {
                                viewModel.username = String(newValue.prefix(25))
                            }
                            //for the debouncer to wait
                            viewModel.validUsername = nil
                            if !viewModel.username.isEmpty{
                                usernameDebouncer.schedule{
                                    Task{
                                        try await viewModel.checkIfUsernameAvailable()
                                    }
                                }
                            }
                        }
                    
                    //MARK: Username availability
                    if viewModel.username.count == 30 {
                        Text("Max 30 Characters")
                            .font(.caption)
                    }
                    //MARK: Checking username
                    if viewModel.validUsername == nil && !viewModel.username.isEmpty && viewModel.username != user.username {
                        Text("Checking if username is available...")
                            .font(.caption)
                            .foregroundStyle(.black)
                    }
                    //MARK: Available Username
                    else if let validUsername = viewModel.validUsername, validUsername && !viewModel.username.isEmpty && viewModel.username != user.username{
                        Text("Username Available!")
                            .font(.caption)
                            .foregroundStyle(.green)
                        //MARK: Taken Uername
                    } else if let validUsername = viewModel.validUsername, !validUsername && !viewModel.username.isEmpty && viewModel.username != user.username {
                        Text("Username is already taken. Please try a different username")
                            .font(.caption)
                            .foregroundStyle(Color("Colors/AccentColor"))
                    }
                    //MARK: emptyUsername
                    if viewModel.username.count == 0 {
                        Text("Full name can not be empty")
                            .font(.caption)
                            .foregroundStyle(Color("Colors/AccentColor"))
                    }

                    //MARK: Fullname
                    EditProfileRowView(title: "Name", placeholder: "Enter your name..", text: $viewModel.fullname)
                        .onChange(of: viewModel.fullname) {oldValue, newValue in
                            if newValue.count > 64 {
                                viewModel.fullname = String(newValue.prefix(64))
                            }
                        }
                    //MARK: fullname max
                    if viewModel.fullname.count == 64 {
                        Text("Max 64 Characters")
                            .font(.caption)
                            .foregroundStyle(Color("Colors/AccentColor"))
                    }
                    //MARK: fullname empty
                    if viewModel.fullname.count == 0 {
                        Text("Full name can not be empty")
                            .font(.caption)
                            .foregroundStyle(Color("Colors/AccentColor"))
                    }
                    
                    editFavoritesView(user: user, editProfileViewModel: viewModel)
                        .padding()
                }
                
                Spacer()
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .font(.subheadline)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        Task {
                            try await viewModel.updateUserData()
                            dismiss()
                        }
                    }
                    .disabled(!formIsValid)
                    .opacity(formIsValid ? 1 : 0.5)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                }
            }
            .onReceive(viewModel.$user, perform: { user in
                self.user = user
            })
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
        }

    }
}

extension EditProfileView: AuthenticationFormProtocol {
    var formIsValid: Bool {
        if let validUsername = viewModel.validUsername{
            return !viewModel.fullname.isEmpty && validUsername
        }
        else{
            return false
        }
    }
}
//MARK: EditProfileRowView
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
        .font(.subheadline)
        .frame(height: 36)
    }
}

#Preview {
    EditProfileView(user: .constant(DeveloperPreview.user))
}
//MARK: editFavoritesView
struct editFavoritesView: View {
    let user: User
    @State private var fetchedRestaurant: Restaurant?
    @State private var isEditFavoritesShowing = false
    @State var oldSelection: FavoriteRestaurant = FavoriteRestaurant(name: "", id: "", restaurantProfileImageUrl: nil)
    @ObservedObject var editProfileViewModel: EditProfileViewModel
    var body: some View {
        HStack(alignment: .top, spacing: 8){
            Spacer()
            ForEach(editProfileViewModel.favoritesPreview) { favoriteRestaurant in
                VStack (spacing:10){
                    Button{
                        oldSelection = favoriteRestaurant
                        isEditFavoritesShowing.toggle()
                    } label: {
                        VStack{
                            Text("Edit")
                                .font(.caption)
                                .foregroundStyle(.blue)
                            HStack{
                                VStack {
                                    ZStack(alignment: .bottom) {
                                        if let imageUrl = favoriteRestaurant.restaurantProfileImageUrl {
                                            RestaurantCircularProfileImageView(imageUrl: imageUrl, size: .medium)
                                        }
                                    }
                                    Text(favoriteRestaurant.name)
                                        .font(.caption)
                                        .multilineTextAlignment(.center)
                                        .lineLimit(2)
                                        .frame(maxWidth: .infinity, alignment: .center) // Limit the width
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                
                            }
                        }
                    }
                    if !favoriteRestaurant.name.isEmpty{
                        Button{
                            oldSelection = favoriteRestaurant
                            if let index = editProfileViewModel.favoritesPreview.firstIndex(of: oldSelection) {
                                editProfileViewModel.favoritesPreview[index] = FavoriteRestaurant(name: "", id: NSUUID().uuidString, restaurantProfileImageUrl: "")
                            }
                        } label: {
                            VStack{
                                Text("Clear")
                                    .foregroundStyle(Color("Colors/AccentColor"))
                                    .font(.caption)
                            }
                        }
                    }
                }

                Spacer()
                    
                }
            }
        .sheet(isPresented: $isEditFavoritesShowing) { FavoriteRestaurantSearchView(oldSelection: $oldSelection, editProfileViewModel: editProfileViewModel)}
    }
}



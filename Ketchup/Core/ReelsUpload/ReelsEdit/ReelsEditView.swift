//
//  ReelsEditView.swift
//  Ketchup
//
//  Created by Jack Robinson on 7/10/24.
//

import SwiftUI
import AVKit
import Photos
import Kingfisher
import FirebaseAuth
import UIKit
import InstantSearchSwiftUI

struct ReelsEditView: View {
    @StateObject private var editViewModel: ReelsEditViewModel
    @ObservedObject var feedViewModel: FeedViewModel
    @Binding var post: Post
    @Environment(\.dismiss) var dismiss
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    @State private var tempFoodRating: Double
    @State private var tempAtmosphereRating: Double
    @State private var tempValueRating: Double
    @State private var tempServiceRating: Double
    @State private var showNoChangesAlert: Bool = false
    @State private var currentMediaIndex = 0
    @StateObject private var searchViewModel = SearchViewModel(initialSearchConfig: .users)
    @FocusState private var isCaptionFocused: Bool
    @State var isTaggingUsers = false
    private let spacing: CGFloat = 20
    
    private var width: CGFloat {
        (UIScreen.main.bounds.width - (spacing * 2)) / 3
    }
    
    init(post: Binding<Post>, feedViewModel: FeedViewModel) {
        self._post = post
        self.feedViewModel = feedViewModel
        _editViewModel = StateObject(wrappedValue: ReelsEditViewModel(post: post.wrappedValue))
        _tempFoodRating = State(initialValue: post.wrappedValue.foodRating ?? 5.0)
        _tempAtmosphereRating = State(initialValue: post.wrappedValue.atmosphereRating ?? 5.0)
        _tempValueRating = State(initialValue: post.wrappedValue.valueRating ?? 5.0)
        _tempServiceRating = State(initialValue: post.wrappedValue.serviceRating ?? 5.0)
    }
    
    var body: some View {
        NavigationStack{
            VStack {
                ScrollView {
                    VStack(spacing: 20) {
                        restaurantInfoView
                        Divider()
                        captionInputView
                        if editViewModel.isMentioning {
                            mentionsList
                        }
                        Divider()
                        tagUsersButton
                        Divider()
                        ratingsView
                        Divider()
                        saveButton
                    }
                    .padding()
                }
            }
            .onTapGesture {
                dismissKeyboard()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.white, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .preferredColorScheme(.light)
            .gesture(
                DragGesture().onChanged { value in
                    if value.translation.height > 50 {
                        dismissKeyboard()
                    }
                }
            )
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        if hasUnsavedChanges {
                            showAlert = true
                        } else {
                            dismiss()
                        }
                    }
                }
            }
            .alert("Unsaved Changes", isPresented: $showAlert) {
                Button("Discard", role: .destructive) { dismiss() }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("You have unsaved changes. Are you sure you want to discard them?")
            }
            .onAppear {
                editViewModel.fetchFollowingUsers()
            }
            .onChange(of: editViewModel.caption) { oldValue, newValue in
                editViewModel.checkForMentioning()
                if editViewModel.filteredMentionedUsers.isEmpty {
                    let text = editViewModel.checkForAlgoliaTagging(in: newValue)
                    if !text.isEmpty {
                        searchViewModel.searchQuery = text
                        Debouncer(delay: 0).schedule {
                            searchViewModel.notifyQueryChanged()
                        }
                    }
                }
            }
            .sheet(isPresented: $isTaggingUsers) {
                        NavigationStack {
                            SelectFollowingEditPostView(editViewModel: editViewModel)
                                .navigationTitle("Tag Users")
                        }
                        .presentationDetents([.height(UIScreen.main.bounds.height * 0.5)])
                    }
        }
    }
    
    var captionInputView: some View {
        VStack {
            ZStack(alignment: .topLeading) {
                TextEditor(text: $editViewModel.caption)
                    .font(.custom("MuseoSansRounded-300", size: 16))
                    .frame(height: 75)
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
                    .onChange(of: editViewModel.caption) {
                        editViewModel.checkForMentioning()
                    }
                if editViewModel.caption.isEmpty {
                    Text("Enter a caption...")
                        .font(.custom("MuseoSansRounded-300", size: 16))
                        .foregroundColor(Color.gray)
                        .padding(.top, 8)
                        .padding(.horizontal, 5)
                }
            }
            HStack {
                Spacer()
                Text("\(editViewModel.caption.count)/500")
                    .font(.custom("MuseoSansRounded-300", size: 10))
                    .foregroundColor(.gray)
                    .padding(.horizontal, 10)
            }
        }
        .onChange(of: editViewModel.caption) {
            if editViewModel.caption.count >= 500 {
                editViewModel.caption = String(editViewModel.caption.prefix(500))
            }
        }
    }
    
    var mentionsList: some View {
        Group {
            if !editViewModel.filteredMentionedUsers.isEmpty {
                ForEach(editViewModel.filteredMentionedUsers, id: \.id) { user in
                    Button(action: {
                        let username = user.username
                        var words = editViewModel.caption.split(separator: " ").map(String.init)
                        words.removeLast()
                        words.append("@" + username)
                        editViewModel.caption = words.joined(separator: " ") + " "
                        editViewModel.isMentioning = false
                    }) {
                        HStack {
                            UserCircularProfileImageView(profileImageUrl: user.profileImageUrl, size: .small)
                            Text(user.username)
                                .font(.custom("MuseoSansRounded-300", size: 14))
                            Spacer()
                        }
                        .padding(.horizontal)
                    }
                    .contentShape(Rectangle())
                }
            } else {
                InfiniteList(searchViewModel.userHits, itemView: { hit in
                    Button {
                        let username = hit.object.username
                        var words = editViewModel.caption.split(separator: " ").map(String.init)
                        words.removeLast()
                        words.append("@" + username)
                        editViewModel.caption = words.joined(separator: " ") + " "
                        editViewModel.isMentioning = false
                    } label: {
                        UserCell(user: hit.object)
                            .padding()
                    }
                    Divider()
                }, noResults: {
                    Text("No results found")
                        .foregroundStyle(.black)
                })
            }
        }
    }
    
    private func addMention(user: User) {
        let username = user.username
        var words = editViewModel.caption.split(separator: " ").map(String.init)
        words.removeLast()
        words.append("@" + username)
        editViewModel.caption = words.joined(separator: " ") + " "
        editViewModel.isMentioning = false
        isCaptionFocused = true
    }
    private var ratingsView: some View {
        VStack(spacing: 10) {
            OverallRatingView(rating: calculateOverallRating())
            RatingSliderGroup(label: "Food", rating: $tempFoodRating, isNA: $editViewModel.isFoodNA)
            RatingSliderGroup(label: "Atmosphere", rating: $tempAtmosphereRating, isNA: $editViewModel.isAtmosphereNA)
            RatingSliderGroup(label: "Value", rating: $tempValueRating, isNA: $editViewModel.isValueNA)
            RatingSliderGroup(label: "Service", rating: $tempServiceRating, isNA: $editViewModel.isServiceNA)
        }
    }
    private var restaurantInfoView: some View {
        VStack {
            RestaurantCircularProfileImageView(imageUrl: post.restaurant.profileImageUrl, size: .xLarge)
            Text(post.restaurant.name)
                .font(.custom("MuseoSansRounded-500", size: 20))
            if let cuisine = post.restaurant.cuisine, let price = post.restaurant.price {
                Text("\(cuisine), \(price)")
                    .font(.custom("MuseoSansRounded-300", size: 10))
                    .foregroundStyle(.black)
            } else if let cuisine = post.restaurant.cuisine {
                Text(cuisine)
                    .font(.custom("MuseoSansRounded-300", size: 10))
                    .foregroundStyle(.black)
            } else if let price = post.restaurant.price {
                Text(price)
                    .font(.custom("MuseoSansRounded-300", size: 10))
                    .foregroundStyle(.black)
            }
            if let address = post.restaurant.address {
                Text(address)
                    .font(.custom("MuseoSansRounded-300", size: 10))
                    .foregroundStyle(.black)
            }
        }
    }
    func calculateOverallRating() -> String {
        var ratings: [Double] = []
        if !editViewModel.isFoodNA { ratings.append(tempFoodRating) }
        if !editViewModel.isAtmosphereNA { ratings.append(tempAtmosphereRating) }
        if !editViewModel.isValueNA { ratings.append(tempValueRating) }
        if !editViewModel.isServiceNA { ratings.append(tempServiceRating) }
        
        if ratings.isEmpty {
            return "N/A"
        } else {
            let average = ratings.reduce(0, +) / Double(ratings.count)
            return String(format: "%.1f", average)
        }
    }
    
    private var saveButton: some View {
        Button {
            Task {
                if let updatedPost = await editViewModel.updatePost(
                    newCaption: editViewModel.caption,
                    foodRating: tempFoodRating,
                    atmosphereRating: tempAtmosphereRating,
                    valueRating: tempValueRating,
                    serviceRating: tempServiceRating
                ) {
                    feedViewModel.updatePost(updatedPost)
                    post = updatedPost
                    dismiss()
                } else {
                    alertMessage = "Failed to update post. Please try again."
                    showAlert = true
                }
            }
        } label: {
            Text(editViewModel.isLoading ? "" : "Save")
                .modifier(StandardButtonModifier(width: 90))
                .overlay {
                    if editViewModel.isLoading {
                        ProgressView()
                            .tint(.white)
                    }
                }
        }
        .disabled(editViewModel.isLoading || !hasUnsavedChanges)
        .opacity(hasUnsavedChanges ? 1.0 : 0.5)
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Error"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
    }
    private var tagUsersButton: some View {
        Button {
            isTaggingUsers = true
        } label: {
            HStack {
                Text("Went with anyone?")
                    .font(.custom("MuseoSansRounded-300", size: 16))
                    .foregroundColor(.black)
                    .frame(alignment: .trailing)
                
                Spacer()
                if editViewModel.taggedUsers.isEmpty {
                    Image(systemName: "chevron.right")
                        .frame(width: 25, height: 25)
                        .foregroundColor(Color("Colors/AccentColor"))
                        .padding(.trailing, 10)
                } else {
                    HStack {
                        Text("\(editViewModel.taggedUsers.count) people")
                            .font(.custom("MuseoSansRounded-300", size: 16))
                            .foregroundColor(.black)
                        
                        Image(systemName: "chevron.right")
                            .frame(width: 25, height: 25)
                            .foregroundColor(Color("Colors/AccentColor"))
                    }
                    .padding(.trailing, 10)
                }
            }
        }
    }
    private var hasUnsavedChanges: Bool {
            editViewModel.caption != post.caption ||
            (editViewModel.isFoodNA != (post.foodRating == nil) || (!editViewModel.isFoodNA && tempFoodRating != post.foodRating)) ||
            (editViewModel.isAtmosphereNA != (post.atmosphereRating == nil) || (!editViewModel.isAtmosphereNA && tempAtmosphereRating != post.atmosphereRating)) ||
            (editViewModel.isValueNA != (post.valueRating == nil) || (!editViewModel.isValueNA && tempValueRating != post.valueRating)) ||
            (editViewModel.isServiceNA != (post.serviceRating == nil) || (!editViewModel.isServiceNA && tempServiceRating != post.serviceRating)) ||
            !areTaggedUsersEqual(editViewModel.taggedUsers, post.taggedUsers)
        }

        private func areTaggedUsersEqual(_ users1: [PostUser], _ users2: [PostUser]) -> Bool {
            guard users1.count == users2.count else { return false }
            return Set(users1.map { $0.id }) == Set(users2.map { $0.id })
        }
    
    private func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

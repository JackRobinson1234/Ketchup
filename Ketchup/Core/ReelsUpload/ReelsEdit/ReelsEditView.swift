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

struct ReelsEditView: View {
    @StateObject private var editViewModel: ReelsEditViewModel
    @ObservedObject var feedViewModel: FeedViewModel
    @Binding var post: Post
    @Environment(\.dismiss) var dismiss
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    @State private var tempCaption: String
    @State private var tempFoodRating: Double
    @State private var tempAtmosphereRating: Double
    @State private var tempValueRating: Double
    @State private var tempServiceRating: Double
    @State private var showNoChangesAlert: Bool = false
    private let spacing: CGFloat = 20
    
    init(post: Binding<Post>, feedViewModel: FeedViewModel) {
        self._post = post
        self.feedViewModel = feedViewModel
        _editViewModel = StateObject(wrappedValue: ReelsEditViewModel(post: post.wrappedValue))
        _tempCaption = State(initialValue: post.wrappedValue.caption)
        _tempFoodRating = State(initialValue: post.wrappedValue.foodRating ?? 0)
        _tempAtmosphereRating = State(initialValue: post.wrappedValue.atmosphereRating ?? 0)
        _tempValueRating = State(initialValue: post.wrappedValue.valueRating ?? 0)
        _tempServiceRating = State(initialValue: post.wrappedValue.serviceRating ?? 0)
    }
    
    var body: some View {
        VStack {
            ScrollView {
                VStack {
                    restaurantInfoView
                    Divider()
                    captionInputView
                    Divider()
                    ratingsView
                    Divider()
                    Spacer()
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
    }
    
    private var restaurantInfoView: some View {
        VStack {
            RestaurantCircularProfileImageView(imageUrl: post.restaurant.profileImageUrl, size: .xLarge)
            Text(post.restaurant.name)
                .font(.custom("MuseoSansRounded-500", size: 20))
            if let cuisine = post.restaurant.cuisine, let price = post.restaurant.price {
                Text("\(cuisine), \(price)")
                    .font(.custom("MuseoSansRounded-300", size: 10))
                    .foregroundStyle(.primary)
            } else if let cuisine = post.restaurant.cuisine {
                Text(cuisine)
                    .font(.custom("MuseoSansRounded-300", size: 10))
                    .foregroundStyle(.primary)
            } else if let price = post.restaurant.price {
                Text(price)
                    .font(.custom("MuseoSansRounded-300", size: 10))
                    .foregroundStyle(.primary)
            }
            if let address = post.restaurant.address {
                Text(address)
                    .font(.custom("MuseoSansRounded-300", size: 10))
                    .foregroundStyle(.primary)
            }
        }
    }
    
    private var captionInputView: some View {
            VStack {
                ZStack(alignment: .topLeading) {
                    TextEditor(text: $tempCaption)
                        .font(.custom("MuseoSansRounded-300", size: 16))
                        .frame(height: 100)
                        .padding(.horizontal, 20)
                        .background(Color.white)
                        .cornerRadius(5)
                    if tempCaption.isEmpty {
                        Text("Enter a caption...")
                            .font(.custom("MuseoSansRounded-300", size: 16))
                            .foregroundColor(Color.gray)
                            .padding(.horizontal, 25)
                            .padding(.top, 8)
                    }
                }
                HStack {
                    Spacer()
                    Text("\(tempCaption.count)/300")
                        .font(.custom("MuseoSansRounded-300", size: 10))
                        .foregroundColor(.gray)
                        .padding(.horizontal, 10)
                }
            }
            .onChange(of: tempCaption) {oldValue, newValue in
                tempCaption = String(newValue.prefix(300))
            }
           
        }
    
    private var ratingsView: some View {
            VStack(spacing: 10) {
                OverallRatingView(rating: overallRating)
                RatingSliderGroup(label: "Food", rating: $tempFoodRating)
                RatingSliderGroup(label: "Atmosphere", rating: $tempAtmosphereRating)
                RatingSliderGroup(label: "Value", rating: $tempValueRating)
                RatingSliderGroup(label: "Service", rating: $tempServiceRating)
            }
        }
    private var overallRating: Double {
            let ratings = [tempFoodRating, tempAtmosphereRating, tempValueRating, tempServiceRating]
            let sum = ratings.reduce(0, +)
            let average = sum / Double(ratings.count)
            return (average * 10).rounded() / 10 // Round to one decimal place
        }
        
    
    private var saveButton: some View {
        Button {
            if hasUnsavedChanges {
                Task {
                    if let updatedPost = await editViewModel.updatePost(
                        newCaption: tempCaption,
                        foodRating: tempFoodRating,
                        atmosphereRating: tempAtmosphereRating,
                        valueRating: tempValueRating,
                        serviceRating: tempServiceRating,
                        overallRating: overallRating
                    ) {
                        // Update the post in the FeedViewModel
                        feedViewModel.updatePost(updatedPost)
                        // Update the binding
                        post = updatedPost
                        dismiss()
                    } else {
                        alertMessage = "Failed to update post. Please try again."
                        showAlert = true
                    }
                }
            } else {
                showNoChangesAlert = true
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
        .disabled(editViewModel.isLoading)
        .opacity(hasUnsavedChanges ? 1.0 : 0.5)
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Error"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
        .alert("No Changes", isPresented: $showNoChangesAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("There are no changes to save.")
        }
    }
    private var hasUnsavedChanges: Bool {
        tempCaption != post.caption ||
        tempFoodRating != (post.foodRating ?? 0) ||
        tempAtmosphereRating != (post.atmosphereRating ?? 0) ||
        tempValueRating != (post.valueRating ?? 0) ||
        tempServiceRating != (post.serviceRating ?? 0)
    }
    private func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

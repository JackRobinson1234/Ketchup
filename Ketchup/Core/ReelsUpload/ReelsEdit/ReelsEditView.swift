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
        _tempFoodRating = State(initialValue: post.wrappedValue.foodRating ?? 5.0)
        _tempAtmosphereRating = State(initialValue: post.wrappedValue.atmosphereRating ?? 5.0)
        _tempValueRating = State(initialValue: post.wrappedValue.valueRating ?? 5.0)
        _tempServiceRating = State(initialValue: post.wrappedValue.serviceRating ?? 5.0)
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
        .onChange(of: tempCaption) { oldValue, newValue in
            tempCaption = String(newValue.prefix(300))
        }
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
            if hasUnsavedChanges {
                Task {
                    if let updatedPost = await editViewModel.updatePost(
                        newCaption: tempCaption,
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
        (editViewModel.isFoodNA != (post.foodRating == nil) || (!editViewModel.isFoodNA && tempFoodRating != post.foodRating)) ||
        (editViewModel.isAtmosphereNA != (post.atmosphereRating == nil) || (!editViewModel.isAtmosphereNA && tempAtmosphereRating != post.atmosphereRating)) ||
        (editViewModel.isValueNA != (post.valueRating == nil) || (!editViewModel.isValueNA && tempValueRating != post.valueRating)) ||
        (editViewModel.isServiceNA != (post.serviceRating == nil) || (!editViewModel.isServiceNA && tempServiceRating != post.serviceRating))
    }
    
    private func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

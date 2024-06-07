//
//  EditRecipeView.swift
//  Ketchup
//
//  Created by Jack Robinson on 6/4/24.
//

import SwiftUI

struct EditRecipeView: View {
    @StateObject var uploadViewModel: UploadViewModel
    @State private var showCookingTimePicker = false
    @State private var showServingsPicker = false
    @State private var showDifficultyPicker = false
    @State private var selectedCookingTime = 0
    @State private var selectedServings = 0
    @State private var selectedDifficulty: RecipeDifficulty = .easy
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    ZStack(alignment: .bottomLeading) {
                        TabView {
                            if let url = uploadViewModel.videoURL?.absoluteString {
                                if let uiImage = MediaHelpers.generateThumbnail(path: url) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .scaledToFill()
                                    
                                }
                            } else if let images = uploadViewModel.images {
                                Image(uiImage: images[0])
                                    .resizable()
                                    .scaledToFill()
                                    
                            }
                        }
                        .frame(height: 300)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(uploadViewModel.recipeTitle)
                                .font(.title)
                                .bold()
                                .foregroundStyle(.white)
                            
                            Text("by: @\(AuthService.shared.userSession!.username)")
                                .font(.subheadline)
                                .foregroundStyle(.white)
                        }
                        .padding(.horizontal)
                        .padding(.bottom)
                        .background(LinearGradient(gradient: Gradient(colors: [Color.black.opacity(0.6), Color.clear]), startPoint: .bottom, endPoint: .top))
                    }
                    
                    // Red circle outline with white text for cooking time, difficulty, and serving number
                    VStack(alignment: .leading, spacing: 20) {
                        HStack(spacing: 10) {
                            Spacer()
                            Button {
                                showCookingTimePicker.toggle()
                            } label: {
                                if uploadViewModel.cookingTime != 0 {
                                    InfoCircle(text: "\(uploadViewModel.cookingTime) min", image: "clock")
                                        .onTapGesture {
                                            selectedCookingTime = uploadViewModel.cookingTime
                                            showCookingTimePicker.toggle()
                                        }
                                } else {
                                    InfoCircle(text: "N/A", image: "clock")
                                }
                            }
                            
                            Button {
                                showServingsPicker.toggle()
                            } label: {
                                if uploadViewModel.recipeServings != 0 {
                                    InfoCircle(text: "\(uploadViewModel.recipeServings) servings", image: "person.3")
                                        .onTapGesture {
                                            selectedServings = uploadViewModel.recipeServings
                                            showServingsPicker.toggle()
                                        }
                                } else {
                                    InfoCircle(text: "N/A", image: "person.3")
                                }
                            }
                            
                            if let difficulty = uploadViewModel.recipeDifficulty {
                                InfoCircle(text: difficulty.text, image: "star")
                                    .onTapGesture {
                                        selectedDifficulty = difficulty
                                        showDifficultyPicker.toggle()
                                    }
                            } else {
                                InfoCircle(text: "N/A", image: "flame")
                            }
                            Spacer()
                        }
                        .padding(.top)
                        
                        // Dietary restrictions
                        Text("Dietary Restrictions")
                            .font(.headline)
                        if !uploadViewModel.dietaryRestrictions.isEmpty {
                            VStack(alignment: .leading) {
                                HStack {
                                    ForEach(uploadViewModel.dietaryRestrictions, id: \.self) { restriction in
                                        DietaryRestrictionBox(text: restriction)
                                    }
                                }
                            }
                        } else {
                            Text("None Listed")
                                .font(.subheadline)
                        }
                        
                        // Ingredients
                        Text("Ingredients")
                            .font(.headline)
                        
                        if !uploadViewModel.ingredients.isEmpty {
                            VStack(alignment: .leading, spacing: 16) {
                                ForEach(uploadViewModel.ingredients, id: \.self) { ingredient in
                                    HStack(alignment: .top, spacing: 4) {
                                        Text(ingredient.quantity)
                                            .bold()
                                            .foregroundStyle(.gray)
                                            .frame(width: 100, alignment: .leading) // Adjust width as needed
                                        Text(ingredient.item)
                                    }
                                }
                            }
                        } else {
                            Text("None Listed")
                                .font(.subheadline)
                        }
                        
                        // Instructions
                        Text("Instructions")
                            .font(.headline)
                        
                        if !uploadViewModel.instructions.isEmpty {
                            VStack(alignment: .leading, spacing: 16) {
                                ForEach(uploadViewModel.instructions.indices, id: \.self) { index in
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Step \(index + 1)")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                            .padding(.bottom, 4)
                                        Text(uploadViewModel.instructions[index].title)
                                            .bold()
                                        Text(uploadViewModel.instructions[index].description)
                                    }
                                }
                            }
                        } else {
                            Text("None Listed")
                                .font(.subheadline)
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom, 16) // Add bottom padding to ensure last content is not cut off
            }
            .edgesIgnoringSafeArea(.top)
            .modifier(BackButtonModifier())
            .overlay(
                            Group {
                                if showCookingTimePicker {
                                    ModalOverlay {
                                        VStack {
                                            Picker("Cooking Time", selection: $uploadViewModel.cookingTime) {
                                                ForEach(Array(stride(from: 5, to: 125, by: 5)), id: \.self) { time in
                                                    Text("\(time) min").tag(time)
                                                }
                                            }
                                            .labelsHidden()
                                            .pickerStyle(WheelPickerStyle())
                                            Button("Done") {
                                                showCookingTimePicker.toggle()
                                            }
                                            .padding()
                                        }
                                    }
                                }
                                if showServingsPicker {
                                    ModalOverlay {
                                        VStack {
                                            Picker("Servings", selection: $uploadViewModel.recipeServings) {
                                                ForEach(1..<21, id: \.self) { servings in
                                                    Text("\(servings) servings").tag(servings)
                                                }
                                            }
                                            .labelsHidden()
                                            .pickerStyle(WheelPickerStyle())
                                            Button("Done") {
                                                showServingsPicker.toggle()
                                            }
                                            .padding()
                                        }
                                    }
                                }
                                if showDifficultyPicker {
                                    ModalOverlay {
                                        VStack {
                                            Picker("Difficulty", selection: $uploadViewModel.recipeDifficulty) {
                                                ForEach(RecipeDifficulty.allCases, id: \.self) { difficulty in
                                                    Text(difficulty.text).tag(difficulty)
                                                }
                                            }
                                            .labelsHidden()
                                            .pickerStyle(WheelPickerStyle())
                                            Button("Done") {
                                                showDifficultyPicker.toggle()
                                            }
                                            .padding()
                                        }
                                    }
                                }
                            }
                        )
            .navigationBarBackButtonHidden()
        }
    }
}

struct ModalOverlay<Content: View>: View {
    let content: () -> Content
    
    var body: some View {
        VStack {
            Spacer()
            VStack {
                content()
                    .padding()
                    .background(Color.white)
                    .cornerRadius(16)
                    .shadow(radius: 10)
            }
            .frame(maxWidth: .infinity)
            .background(Color.black.opacity(0.5))
            .onTapGesture {
                // Dismiss the modal overlay when tapping outside of it
            }
        }
        .edgesIgnoringSafeArea(.all)
    }
}


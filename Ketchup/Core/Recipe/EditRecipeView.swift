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
    @State private var showEditDietary = false
    @State private var showEditIngredients = false
    @State private var showEditInstructions = false
    @State private var selectedCookingTime = 0
    @State private var selectedServings = 0
    @State private var selectedDifficulty: RecipeDifficulty = .easy

    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
//                    ZStack(alignment: .bottomLeading) {
//                        TabView {
//                            if let url = uploadViewModel.videoURL?.absoluteString {
//                                if let uiImage = MediaHelpers.generateThumbnail(path: url) {
//                                    Image(uiImage: uiImage)
//                                        .resizable()
//                                        .scaledToFill()
//                                    
//                                }
//                            } else if let images = uploadViewModel.images {
//                                Image(uiImage: images[0])
//                                    .resizable()
//                                    .scaledToFill()
//                                
//                            }
//                        }
//                        .frame(height: 300)
//                        
//                        VStack(alignment: .leading, spacing: 4) {
//                            Text(uploadViewModel.recipeTitle)
//                                .font(.title)
//                                .bold()
//                                .foregroundStyle(.white)
//                            
//                            Text("by: @\(AuthService.shared.userSession!.username)")
//                                .font(.subheadline)
//                                .foregroundStyle(.white)
//                        }
//                        .padding(.horizontal)
//                        .padding(.bottom)
//                        .background(LinearGradient(gradient: Gradient(colors: [Color.black.opacity(0.6), Color.clear]), startPoint: .bottom, endPoint: .top))
//                    }
                    
                    // Red circle outline with white text for cooking time, difficulty, and serving number
                    
                        HStack(spacing: 10) {
                            Spacer()
                            Button {
                                showCookingTimePicker.toggle()
                            } label: {
                                    InfoCircle(text: "\(uploadViewModel.cookingTime) min", image: "clock", edit: true)
                                        .onTapGesture {
                                            selectedCookingTime = uploadViewModel.cookingTime
                                            showCookingTimePicker.toggle()
                                        }
                            }
                            
                            Button {
                                showServingsPicker.toggle()
                            } label: {
                                    InfoCircle(text: "\(uploadViewModel.recipeServings) servings", image: "person.3", edit: true)
                                        .onTapGesture {
                                            selectedServings = uploadViewModel.recipeServings
                                            showServingsPicker.toggle()
                                        }
                               
                            }
                            
                            Button {
                                showDifficultyPicker.toggle()
                            } label: {
                                InfoCircle(text: uploadViewModel.recipeDifficulty.text, image: "star", edit: true)
                                    .onTapGesture {
                                        selectedDifficulty = uploadViewModel.recipeDifficulty
                                        showDifficultyPicker.toggle()
                                    }
                            }
                            Spacer()
                        }
                        .padding(.top)
                        
                        // Dietary restrictions
                    VStack(alignment: .leading, spacing: 16) {
                        Button {
                            showEditDietary.toggle()
                        } label: {
                            HStack(spacing: 0){
                                Image(systemName: "pencil")
                                Text(" Edit Dietary Restrictions")
                                    .font(.headline)
                                    .foregroundStyle(.black)
                            }
                        }
                        if !uploadViewModel.dietaryRestrictions.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false){
                                HStack {
                                    ForEach(uploadViewModel.dietaryRestrictions, id: \.self) { restriction in
                                        DietaryRestrictionBox(text: restriction)
                                    }
                                }
                            }
                            
                        } else {
                            Text("No Dietary Restrictions Listed")
                                .font(.subheadline)
                                .foregroundStyle(.gray)
                        }
                    }
                        // Ingredients
                    VStack(alignment: .leading, spacing: 16) {
                        Button{
                            showEditIngredients.toggle()
                        } label: {
                            HStack(spacing: 0){
                                Image(systemName: "pencil")
                                Text(" Edit Ingredients")
                                    .font(.headline)
                                    .foregroundStyle(.black)
                            }
                        }
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
                            Text("No Ingredients Listed")
                                .font(.subheadline)
                                .foregroundStyle(.gray)
                        }
                    }
                    VStack(alignment: .leading, spacing: 16) {
                        // Instructions
                        Button{
                            showEditInstructions.toggle()
                        } label: {
                            HStack(spacing: 0){
                                Image(systemName: "pencil")
                                Text(" Edit Instructions")
                                    .font(.headline)
                                    .foregroundStyle(.black)
                            }
                        }
                        
                        if !uploadViewModel.instructions.isEmpty {
                            VStack(alignment: .leading, spacing: 16) {
                                ForEach(uploadViewModel.instructions.indices, id: \.self) { index in
                                    InstructionBoxView(stepNumber: (index + 1), title: uploadViewModel.instructions[index].title, description: uploadViewModel.instructions[index].description)
                                }
                            }
                        } else {
                            Text("No Instructions Listed")
                                .font(.subheadline)
                                .foregroundStyle(.gray)
                        }
                    }
                    
                }
                .padding() // Add bottom padding to ensure last content is not cut off
            }
            .navigationBarBackButtonHidden()
            .navigationTitle("Add a Recipe")
            .modifier(BackButtonModifier())
            .sheet(isPresented: $showCookingTimePicker) {
                
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
                    .presentationDetents([.height(UIScreen.main.bounds.height * 0.33)])
                
            }
            .sheet(isPresented: $showServingsPicker) {
                
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
                .presentationDetents([.height(UIScreen.main.bounds.height * 0.33)])
            }
            .sheet(isPresented: $showDifficultyPicker) {
                VStack {
                    let options: [RecipeDifficulty] = [.easy, .medium, .hard]
                    Picker("Difficulty", selection: $uploadViewModel.recipeDifficulty) {
                        ForEach(options, id: \.self) { difficulty in
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
                .presentationDetents([.height(UIScreen.main.bounds.height * 0.66)])
            }
            .sheet(isPresented: $showEditDietary) {
                EditDietaryRestrictions(uploadViewModel: uploadViewModel)
                    .presentationDetents([.height(UIScreen.main.bounds.height * 0.66)])
            }
            .sheet(isPresented: $showEditIngredients) {
                EditIngredientsView(uploadViewModel: uploadViewModel)
                    .presentationDetents([.height(UIScreen.main.bounds.height * 0.66)])
            }
            .sheet(isPresented: $showEditInstructions) {
                EditInstructionsView(uploadViewModel: uploadViewModel)
                    .presentationDetents([.height(UIScreen.main.bounds.height * 0.66)])
            }
        }
    }
}

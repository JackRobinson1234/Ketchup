//
//  Testing.swift
//  Foodi
//
//  Created by Joe Ciminelli on 4/15/24.
//

import SwiftUI


struct Testing: View {
    
    @StateObject var uploadViewModel = UploadViewModel()
    @State var showAddRecipe: Bool = false
    @State var showDietary: Bool = false 
    @State private var showTimePicker = false
    
    
    var body: some View {
        VStack {
            ScrollView{
                HStack {
                    //MARK: Recipe Title
                    VStack{
                        TextField("Add a Recipe Title...", text: $uploadViewModel.recipeTitle, axis: .vertical)
                            .font(.title)
                            .onChange(of: uploadViewModel.recipeTitle) {oldvalue, newValue in
                                // Limit the text to 150 characters
                                if newValue.count > 100 {
                                    uploadViewModel.recipeTitle = String(newValue.prefix(100))
                                }}
                        
                        HStack {
                            Spacer()
                            Text("\(uploadViewModel.recipeTitle.count)/100")
                                .foregroundColor(uploadViewModel.recipeTitle.isEmpty ? .red : .gray)
                                .font(.caption)
                                .padding(.horizontal)
                        }
                    }
                    Spacer()
                    //MARK: thumbnail
//                    if let uiImage = MediaHelpers.generateThumbnail(path: media.url.absoluteString) {
//                        Image(uiImage: uiImage)
//                            .resizable()
//                            .scaledToFill()
//                            .frame(width: 100, height: 125)
//                            .clipShape(RoundedRectangle(cornerRadius: 6))
//                    }
                    Rectangle()
                        .frame(width: 100, height: 125)
                        .cornerRadius(3.0)
                    
                }
                //MARK: Recipe Caption
                TextField("Enter your caption...", text: $uploadViewModel.caption, axis: .vertical)
                    .font(.subheadline)
                    .padding(.top, 60)
                    .onChange(of: uploadViewModel.caption) {oldvalue, newValue in
                        // Limit the text to 150 characters
                        if newValue.count > 500 {
                            uploadViewModel.caption = String(newValue.prefix(500))
                        }}
                HStack {
                    Spacer()
                    Text("\(uploadViewModel.caption.count)/500")
                        .foregroundColor(uploadViewModel.caption.isEmpty ? .red : .gray)
                        .font(.caption)
                        .padding(.horizontal)
                }
                Divider()
                VStack{
                    //MARK: Recipe Cuisine
                    TextField("Enter the cuisine...", text: $uploadViewModel.recipeCuisine, axis: .vertical)
                        .font(.subheadline)
                        .padding(.top, 30)
                        .onChange(of: uploadViewModel.recipeCuisine) {oldvalue, newValue in
                            // Limit the text to 150 characters
                            if newValue.count > 50 {
                                uploadViewModel.recipeCuisine = String(newValue.prefix(50))
                            }}
                    HStack {
                        Spacer()
                        Text("\(uploadViewModel.recipeCuisine.count)/50")
                            .foregroundColor(uploadViewModel.recipeCuisine.isEmpty ? .red : .gray)
                            .font(.caption)
                            .padding(.horizontal)
                    }
                }
                Divider()
                
                // MARK: Recipe Dietary
                Button{
                    showDietary.toggle()
                } label: {
                    HStack{
                        VStack (alignment: .leading) {
                            
                            if uploadViewModel.dietaryRestrictions.count > 0 && !uploadViewModel.dietaryRestrictions[0].isEmpty {
                                Text("Add Dietary Restrictions (Optional)")
                                    .font(.subheadline)
                                    .foregroundColor(.black)
                                
                                Text("\(uploadViewModel.dietaryRestrictions.joined(separator: ", "))")
                                    .lineLimit(1)
                                    .font(.caption)
                                    .foregroundStyle(.black)
                                    .bold()
                            } else {
                                Text("Add Dietary Restrictions (Optional)")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                Text("No Dietary Restrictions Added")
                                    .font(.caption)
                                    .foregroundStyle(.gray)
                            }
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                    }
                }
                .padding(.top, 30)
                Divider()
                
                //MARK: Add Recipe
                Button{
                    showAddRecipe.toggle()
                } label: {
                    HStack{
                        VStack (alignment: .leading) {
                            
                            // if the ingredients, instructions, or viewModel is empty, then it won't show that the user edited the recipe.
                            if uploadViewModel.ingredients.count > 0 && !uploadViewModel.ingredients[0].item.isEmpty ||
                                uploadViewModel.instructions.count > 0 && !uploadViewModel.instructions[0].title.isEmpty
                                
                            {
                                Text("Add your Recipe (Optional)")
                                    .font(.subheadline)
                                    .foregroundColor(.black)
                                Text("Recipe Added")
                                    .font(.caption)
                                    .foregroundStyle(.black)
                            }
                            else {
                                Text("Add your Recipe (Optional)")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                Text("No Recipe Added")
                                    .font(.caption)
                                    .foregroundStyle(.gray)
                            }
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                    }
                    
                }
                .padding(.top, 30)
                Divider()
                
                //MARK: Recipe Time
                Button{
                    showTimePicker.toggle()
                } label: {
                    HStack{
                        VStack (alignment: .leading) {
                            
                            // if hours/ minutes are 0, show correct logic
                            if uploadViewModel.recipeMinutes == 0 && uploadViewModel.recipeHours == 0{
                                Text("Add Total Recipe Time (Optional)")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                
                                
                                Text("No Time Added")
                                    .font(.caption)
                                    .foregroundStyle(.gray)
                            }
                            else {
                                Text("Add Total Recipe Time (Optional)")
                                    .font(.subheadline)
                                    .foregroundColor(.black)
                                
                                Text("\(uploadViewModel.recipeHours) hours, \(uploadViewModel.recipeMinutes) minutes")
                                    .font(.caption)
                                    .foregroundStyle(.black)
                                    .bold()
                            }
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                    }
                }
                .padding(.top, 30)
                
                Divider()
                
            }
            Spacer()
            
            Button {
//                //MARK: Post Button
//                Task {
//                    try await uploadViewModel.uploadRecipePost()
//                    if uploadViewModel.uploadSuccess{
//                        print("DEBUG: upload success")
//                    }
//                    else if uploadViewModel.uploadFailure{
//                        print("DEBUG: Mission failed, we'll get em next time")
//                    }
//
//                    uploadViewModel.reset()
//                    cover = false
//                    tabIndex = 0
//                }
            } label: {
                Text(uploadViewModel.isLoading ? "" : "Post")
                    .modifier(StandardButtonModifier())
                    .overlay {
                        if uploadViewModel.isLoading {
                            ProgressView()
                                .tint(.white)
                        }
                        
                    }
            }
            .disabled(uploadViewModel.isLoading)
            
        }
        .sheet(isPresented: $showAddRecipe){NewEditRecipeView(viewModel: uploadViewModel)}
        .sheet(isPresented: $showDietary){NewEditDietaryRestrictionsView(viewModel: uploadViewModel)}
        .sheet(isPresented: $showTimePicker) {NewRecipeTimePicker(viewModel: uploadViewModel)}
        .padding()
        .navigationTitle("Recipe Post")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden()
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    //dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                }
            }
        }
    }
}

struct NewEditRecipeView: View {
    @ObservedObject var viewModel: UploadViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack{
            //MARK: Ingredients
            ScrollView{
                
                
                HStack{
                    Spacer()
                    Text("Ingredients")
                        .font(.headline)
                        .padding()
                    Spacer()
                }
                ForEach($viewModel.ingredients.indices, id: \.self) { index in
                    HStack{
                        TextField("Quantity...", text: $viewModel.ingredients[index].quantity, axis: .vertical)
                            .frame(width: 80) // Set a fixed width for the quantity text field
                            .padding(8)
                            .font(.subheadline)
                        Divider()
                        TextField("Add Ingredient...", text: $viewModel.ingredients[index].item, axis: .vertical)
                            .font(.subheadline)
                            .padding(8)
                            .padding(.trailing)
                    }
                    Divider()
                }.padding(.leading)
                
                //MARK: Ingredients Adding
                
                
                if $viewModel.ingredients.count < 25 {
                    Button {
                        viewModel.addEmptyIngredient()
                    } label: {
                        VStack{
                            Image(systemName: "plus.circle")
                                .foregroundColor(.blue)
                                .font(.subheadline)
                                .opacity(viewModel.isLastIngredientEmpty ? 0.2 : 1.0)
                            Text("Add Another Ingredient")
                                .font(.caption)
                                .opacity(viewModel.isLastIngredientEmpty ? 0.2 : 1.0)
                        }
                    }
                    .padding(.top, 10)
                    .disabled(viewModel.isLastIngredientEmpty)
                }
                else {
                    Text("Maximum Ingredients Reached")
                        .font(.caption)
                }
                //MARK: Instructions
                HStack{
                    Spacer()
                    Text("Instructions")
                        .font(.headline)
                    
                        .padding(.top, 10)
                    Spacer()
                }
                .padding()
                ForEach($viewModel.instructions.indices, id: \.self) { index in
                    VStack{
                        HStack{
                            Text("Step \(Int(index)+1):")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .bold()
                            Spacer()
                            
                            TextField("Step \(Int(index)+1) Title...", text: $viewModel.instructions[index].title, axis: .vertical)
                                .font(.subheadline)
                        }
                        TextField("Step \(Int(index)+1) Description...", text: $viewModel.instructions[index].description, axis: .vertical)
                            .font(.subheadline)
                    }
                    
                    
                    Divider()
                } .padding(.leading)
                //MARK: ADD INSTRUCTION
                Button {
                    viewModel.addEmptyInstruction()
                } label: {
                    VStack{
                        Image(systemName: "plus.circle")
                            .foregroundColor(.blue)
                            .font(.subheadline)
                            .opacity(viewModel.isLastInstructionEmpty ? 0.2 : 1.0)
                        Text("Add a New Step")
                            .font(.caption)
                            .opacity(viewModel.isLastInstructionEmpty ? 0.2 : 1.0)
                    }
                }.padding()
                    .disabled(viewModel.isLastInstructionEmpty)
                
                Spacer()
            }
            
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle("Add a Recipe")
            .navigationBarBackButtonHidden()
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button{
                        dismiss()
                    } label: {
                        Text("Done")
                            .font(.subheadline)
                        
                    }
                }
            }
            .toolbar(.hidden, for: .tabBar)
            
        }
        
    }
}

struct NewEditDietaryRestrictionsView: View {
    @ObservedObject var viewModel: UploadViewModel
    @Environment(\.dismiss) var dismiss
    var body: some View {
        NavigationStack{
            //MARK: Title
            ScrollView{
                VStack{

                    HStack{
                        Text("Dietary Restrictions")
                            .font(.headline)
                            .padding()
                        Spacer()
                    }
                    //MARK: Adding Text Fields
                    ForEach($viewModel.dietaryRestrictions.indices, id: \.self) { index in
                        TextField("Add Dietary Restriction...", text: $viewModel.dietaryRestrictions[index], axis: .vertical)
                            .font(.subheadline)
                        Divider()
                    }.padding(.leading)
                    
                    //MARK: Adding Extra Restrictions
                    
                    
                    if $viewModel.dietaryRestrictions.count < 25 {
                        Button {
                            viewModel.addEmptyRestriction()
                        } label: {
                            VStack{
                                Image(systemName: "plus.circle")
                                    .foregroundColor(.blue)
                                    .font(.subheadline)
                                    .opacity(viewModel.isLastRestrictionEmpty ? 0.5 : 1.0)
                                Text("Add Another Dietary Restriction")
                                    .font(.caption)
                                    .opacity(viewModel.isLastRestrictionEmpty ? 0.5 : 1.0)
                            }
                        }
                        .padding(.top, 10)
                        .disabled(viewModel.isLastRestrictionEmpty)
                    }
                    else {
                        Text("Maximum Ingredients Reached")
                            .font(.caption)
                    }
                }
                .navigationBarTitleDisplayMode(.inline)
                .navigationTitle("Add Dietary Restrictions")
                .navigationBarBackButtonHidden()
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                            Button{
                                dismiss()
                            } label: {
                                Text("Done")
                                    .font(.subheadline)
                            
                        }
                    }
                }
                .toolbar(.hidden, for: .tabBar)
            }
        }
    }
}



#Preview {
    Testing()
}

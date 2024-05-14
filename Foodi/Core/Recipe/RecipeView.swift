//
//  JoeRecipeView.swift
//  Foodi
//
//  Created by Jack Robinson on 4/21/24.
//

import SwiftUI

struct RecipeView: View {
    
    @StateObject var uploadViewModel = UploadViewModel()
    @State var showAddRecipe: Bool = false
    @State var showDietary: Bool = false
    @State var showIngredients: Bool = false
    @State var showSteps: Bool = false
    @State private var showTimePicker = false
    @State var showServingsPicker = false
    
    @Environment(\.presentationMode) var presentationMode
    

    var body: some View {
            GeometryReader { geometry in
                
                
                ZStack {
                    Image("recipe-background")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geometry.size.width)
                        .edgesIgnoringSafeArea(.bottom)
                    
                    ScrollView {
                        VStack(spacing: 0) {
                            
                            // TITLE STUFF
                            VStack(alignment: .leading, spacing:0) {
                                Text("Overview")
                                    .foregroundColor(Color.black)
                                    .font(.custom("Marker Felt", size: 18))
                                    .opacity(0.6)
                                    .padding(.horizontal, 15)
                                    .padding(.bottom, 5)
                                
                                VStack(spacing: 0) {
                                    
                                    TextField("Recipe Title", text: $uploadViewModel.recipeTitle)
                                        .font(.title2)
                                        .multilineTextAlignment(.center)
                                        .frame(maxWidth: 320)
                                        .frame(height: 50)
                                    
                                    Divider()
                                        .frame(width: 320)
                                    
                                    HStack(spacing: 0) {
                                        Button{
                                            showTimePicker.toggle()
                                        } label: {
                                            HStack {
                                                
                                                
                                                // if hours/ minutes are 0, show correct logic
                                                if uploadViewModel.recipeMinutes == 0 && uploadViewModel.recipeHours == 0{
                                                    Text("Total Time")
                                                        .font(.subheadline)
                                                        .foregroundColor(.gray)
                                                        .opacity(0.65)
                                                    
                                                    Image(systemName: "plus.circle")
                                                        .foregroundColor(.gray)
                                                        .opacity(0.65)
                                                }
                                                else {
                                                    Text("\(uploadViewModel.recipeHours) hrs, \(uploadViewModel.recipeMinutes) min")
                                                        .font(.subheadline)
                                                        .foregroundStyle(.black)
                                                        .bold()
                                                }
                                                
                                            }
                                            .frame(width: 160, height: 45)
                                        }
                                        
                                        Divider()
                                            .frame(height: 45)
                                        // Number of servings drop down menu
                                        Button{
                                            showServingsPicker.toggle()
                                        } label: {
                                            HStack {
                                                
                                                // if hours/ minutes are 0, show correct logic
                                                if uploadViewModel.recipeServings == 0 {
                                                    Text("Servings")
                                                        .font(.subheadline)
                                                        .foregroundColor(.gray)
                                                        .opacity(0.65)
                                                    
                                                    Image(systemName: "plus.circle")
                                                        .foregroundColor(.gray)
                                                        .opacity(0.65)
                                                    
                                                }
                                                else {
                                                    Text("\(uploadViewModel.recipeServings) servings")
                                                        .font(.subheadline)
                                                        .foregroundStyle(.black)
                                                        .bold()
                                                }
                                                
                                            }
                                            .frame(width: 160, height: 45)
                                        }
                                    }
                                }
                                .background(Color.white.opacity(0.4))
                                .cornerRadius(7)
                            }
                            .padding(.bottom, 15)
                            
                            // DESCRIPTION STUFF
                            VStack(alignment: .leading, spacing:0) {
                                Text("Description")
                                    .foregroundColor(Color.black)
                                    .font(.custom("Marker Felt", size: 18))
                                    .opacity(0.6)
                                    .padding(.horizontal, 15)
                                    .padding(.bottom, 5)
                                
                                // DESCRIPTION STUFF
                                VStack(spacing: 0) {
                                    
                                    TextField("Enter Cuisine Type...", text: $uploadViewModel.recipeCuisine)
                                        .frame(width: 320, height: 45)
                                        .multilineTextAlignment(.center)
                                    
                                    
                                    Divider()
                                        .frame(width: 320)
                                    
                                    Button{
                                        showDietary.toggle()
                                    } label: {
                                        HStack {
                                            
                                            if uploadViewModel.dietaryRestrictions.count > 0 && !uploadViewModel.dietaryRestrictions[0].isEmpty {
                                                
                                                Text("\(uploadViewModel.dietaryRestrictions.joined(separator: ", "))")
                                                    .lineLimit(1)
                                                    .font(.subheadline)
                                                    .foregroundStyle(.black)
                                                    .bold()
                                                
                                            } else {
                                                Text("Dietary Restrictions")
                                                    .font(.subheadline)
                                                    .opacity(0.65)
                                                    .foregroundColor(.gray)
                                                
                                                Image(systemName: "plus.circle")
                                                    .foregroundColor(.gray)
                                                    .opacity(0.65)
                                            }
                                        }
                                        .frame(width: 320, height: 45)
                                    }
                                }
                                .background(Color.white.opacity(0.4))
                                .cornerRadius(7)
                            }
                            .padding(.bottom, 15)
                            
                            // INGREDIENTS
                            VStack(alignment: .leading, spacing:0) {
                               
                                Text("Ingredients")
                                    .foregroundColor(Color.black)
                                    .font(.custom("Marker Felt", size: 18))
                                    .opacity(0.6)
                                    .padding(.horizontal, 15)
                                    .padding(.bottom, 5)
                                
                                VStack(spacing:0) {
                                    ForEach($uploadViewModel.ingredients.indices, id: \.self) { index in
                                        if !uploadViewModel.ingredients[index].item.isEmpty || !uploadViewModel.ingredients[index].quantity.isEmpty {
                                            VStack(spacing: 0) {
                                                HStack(spacing:0){
                                                    
                                                    TextField("", text: $uploadViewModel.ingredients[index].quantity, axis: .vertical)
                                                        .frame(width: 100)
                                                        .font(.subheadline)
                                                        .multilineTextAlignment(.center)
                                                    
                                                    Divider()
                                                        .frame(height: 45)
                                                    
                                                    TextField("", text: $uploadViewModel.ingredients[index].item, axis: .vertical)
                                                        .frame(width: 220)
                                                        .font(.subheadline)
                                                        .multilineTextAlignment(.center)
                                                    
                                                }
                                                
                                                Divider()
                                                    .frame(width: 320)
                                            }
                                        }
                                    }
                                    
                                    if $uploadViewModel.ingredients.count < 25 {
                                        Button{
                                            showIngredients.toggle()
                                        } label: {
                                            HStack {

                                                Text("Add Ingredient")
                                                    .font(.subheadline)
                                                    .opacity(0.65)
                                                    .foregroundColor(.gray)
                                                
                                                Image(systemName: "plus.circle")
                                                    .foregroundColor(.gray)
                                                    .opacity(0.65)
                                                
                                            }
                                            .frame(width: 320, height: 45)
                                        }
                                    }
                                }
                                .background(Color.white.opacity(0.4))
                                .cornerRadius(7)
                            }
                            .padding(.bottom, 15)
                            
                            // STEPS
                            VStack(alignment: .leading, spacing:0) {
                                Text("Steps")
                                    .foregroundColor(Color.black)
                                    .font(.custom("Marker Felt", size: 18))
                                    .opacity(0.6)
                                    .padding(.horizontal, 15)
                                    .padding(.bottom, 5)
                                
                                VStack(spacing:0) {
                                    ForEach($uploadViewModel.instructions.indices, id: \.self) { index in
                                        
                                        
                                        if !uploadViewModel.instructions[index].description.isEmpty {
                                            VStack(spacing: 0) {
                                                HStack(spacing:0){
                                                    
                                                    Text("Step \(index + 1)")
                                                        .frame(width: 100)
                                                        .font(.subheadline)
                                                        .bold()
                                                        .multilineTextAlignment(.center)
                                                    
                                                    Divider()
                                                        .frame(minHeight: 45)
                                                    
                                                    TextField("", text: $uploadViewModel.instructions[index].description, axis: .vertical)
                                                        .frame(width: 220)
                                                        .font(.subheadline)
                                                        .multilineTextAlignment(.center)
                                                    
                                                }
                                                
                                                Divider()
                                                    .frame(width: 320)
                                            }
                                        }
                                    }
                                    
                                    
                                    Button{
                                        showSteps.toggle()
                                    } label: {
                                        HStack {
                                            
                                            Text("Add Step")
                                                .font(.subheadline)
                                                .opacity(0.65)
                                                .foregroundColor(.gray)
                                            
                                            Image(systemName: "plus.circle")
                                                .foregroundColor(.gray)
                                                .opacity(0.65)
                                            
                                        }
                                        .frame(width: 320, height: 45)
                                    }
                                    
                                }
                                .background(Color.white.opacity(0.4))
                                .cornerRadius(7)
                                
                                
                            }
                            .padding(.bottom, 15)
                            
                            Button {
                                uploadViewModel.savedRecipe = true
                                self.presentationMode.wrappedValue.dismiss()
                            } label: {
                                Text("Save")
                                    .foregroundColor(.white)
                                    .frame(width: 90, height: 45)
                                    .background(Color.blue)
                                    .cornerRadius(7)
                            }
                            
                        }
                        .frame(width: geometry.size.width)
                        .padding(.vertical)
                    }
                }

                
                

            }
            .sheet(isPresented: $showTimePicker) {NewRecipeTimePicker(viewModel: uploadViewModel)}
            .sheet(isPresented: $showServingsPicker) {RecipeServingsPicker(viewModel: uploadViewModel)}
            .sheet(isPresented: $showDietary){NewEditDietaryRestrictionsView(viewModel: uploadViewModel)}
            .sheet(isPresented: $showIngredients) {IngregientsView(viewModel: uploadViewModel)}
            .sheet(isPresented: $showSteps) {StepsView(viewModel: uploadViewModel)}
            

        
    }
}

struct IngregientsView: View {
    
    @ObservedObject var viewModel: UploadViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        
        NavigationStack {
            ScrollView {
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
                }
                .padding(.leading)
                
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
                
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle("Add Ingredients")
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
        }
    }
}


struct StepsView: View {
    
    @ObservedObject var viewModel: UploadViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                ForEach($viewModel.instructions.indices, id: \.self) { index in
                    VStack{
                        
                        HStack{
                            
                            Text("Step \(Int(index)+1): ")
                                .font(.subheadline)
                                .bold()
                            
                            TextField("Description...", text: $viewModel.instructions[index].description, axis: .vertical)
                                .font(.subheadline)
                        }
                        
                        
                    }
                    
                    
                    Divider()
                }
                .padding(.leading)
                
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
            .navigationTitle("Add Steps")
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
        }
    }
}


struct RecipeServingsPicker: View {
    @ObservedObject var viewModel: UploadViewModel
    @Environment(\.dismiss) var dismiss
    var body: some View {
        NavigationStack{
            VStack{
                HStack{
                    Spacer()
                    Button{
                        dismiss()
                    } label: {
                        Text("Done")
                            .font(.subheadline)
                    }
                    
                }
                .padding()
                Spacer()
                VStack{
                    Text("Select Recipe Servings")
                        .font(.subheadline)
                    HStack {
                        // Hours Picker
                        Picker("Servings", selection: $viewModel.recipeServings) {
                            ForEach(0..<11) { servings in
                                Text("\(servings)")
                            }
                        }
                        .pickerStyle(WheelPickerStyle())
                        .frame(width: 80)
                        .padding(.top, 30)
                        
                        Text("servings")
                    }
                    .padding()
                    Spacer()
                }
            }
        }
    }
}

struct NewRecipeTimePicker: View {
    @ObservedObject var viewModel: UploadViewModel
    @Environment(\.dismiss) var dismiss
    var body: some View {
        NavigationStack{
            VStack{
                HStack{
                    Spacer()
                    Button{
                        dismiss()
                    } label: {
                        Text("Done")
                            .font(.subheadline)
                    }
                    
                }
                .padding()
                Spacer()
                VStack{
                    Text("Select a Total Recipe Time")
                        .font(.subheadline)
                    HStack {
                        // Hours Picker
                        Picker("Hours", selection: $viewModel.recipeHours) {
                            ForEach(0..<24) { hour in
                                Text("\(hour)")
                            }
                        }
                        .pickerStyle(WheelPickerStyle())
                        .frame(width: 80)
                        .padding(.top, 30)
                        
                        Text("hours")
                        
                        // Minutes Picker
                        Picker("Minutes", selection: $viewModel.recipeMinutes) {
                            ForEach(0..<60) { minute in
                                Text("\(minute)")
                            }
                        }
                        .pickerStyle(WheelPickerStyle())
                        
                        .padding(.top, 30)
                        
                        Text("minutes")
                    }
                    .padding()
                    Spacer()
                }
            }
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
    RecipeView()
}

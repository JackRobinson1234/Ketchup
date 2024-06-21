//
//  EditIngredientsView.swift
//  Ketchup
//
//  Created by Jack Robinson on 6/8/24.
//

import SwiftUI

struct EditIngredientsView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var quantityInput: String = ""
    @State private var ingredientInput: String = ""
    @State private var isSaveButtonEnabled: Bool = false
    @State private var isQuantityLimitReached: Bool = false
    @State private var isIngredientLimitReached: Bool = false
    @ObservedObject var uploadViewModel: UploadViewModel

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    HStack{
                        Text("Edit Ingredients")
                            .font(.title2)
                            .fontWeight(.semibold)
                        Spacer()
                    }
                    HStack{
                        Text("(Max 15)")
                            .font(.caption)
                        Spacer()
                    }
                    if uploadViewModel.ingredients.count >= 15 {
                                           Text("Maximum ingredients reached")
                                               .foregroundColor(.red)
                                               .bold()
                                               .padding()
                    } else {
                        HStack(alignment: .top) {
                            VStack(alignment: .leading) {
                                TextField("Quantity", text: $quantityInput)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .frame(width: 100)
                                    .onChange(of: quantityInput) {oldValue, newValue in
                                        if newValue.count >= 20 {
                                            quantityInput = String(newValue.prefix(20))
                                            isQuantityLimitReached = true
                                        } else {
                                            isQuantityLimitReached = false
                                        }
                                        updateSaveButtonState()
                                    }
                                if isQuantityLimitReached {
                                    Text("Max characters reached")
                                        .foregroundColor(.red)
                                        .font(.caption)
                                }
                            }
                            VStack(alignment: .leading) {
                                TextField("Ingredient", text: $ingredientInput)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .onChange(of: ingredientInput) {oldValue, newValue in
                                        if newValue.count >= 30 {
                                            ingredientInput = String(newValue.prefix(30))
                                            isIngredientLimitReached = true
                                        } else {
                                            isIngredientLimitReached = false
                                        }
                                        updateSaveButtonState()
                                    }
                                if isIngredientLimitReached {
                                    Text("Max characters reached")
                                        .foregroundColor(.red)
                                        .font(.caption)
                                }
                            }
                            
                            Button(action: saveIngredient) {
                                Image(systemName: "plus")
                                    .padding(6)
                                    .foregroundColor(.white)
                                    .background(isSaveButtonEnabled ? Color("Colors/AccentColor") : Color.gray)
                                    .cornerRadius(8)
                            }
                            .disabled(!isSaveButtonEnabled)
                        }
                        .padding(.vertical)
                    }
                        
                    ForEach(uploadViewModel.ingredients, id: \.self) { ingredient in
                        HStack(spacing: 4) {
                            Button(action: {
                                if let index = uploadViewModel.ingredients.firstIndex(of: ingredient) {
                                    deleteIngredient(at: IndexSet(integer: index))
                                }
                            }) {
                                Image(systemName: "xmark")
                                    .foregroundColor(Color("Colors/AccentColor"))
                                    .font(.headline)
                                    .padding()
                            }
                            Text(ingredient.quantity)
                                .bold()
                                .foregroundStyle(.gray)
                                .frame(width: 100, alignment: .leading) // Adjust width as needed
                            Text(ingredient.item)
                        }
                    }
                    .onDelete(perform: deleteIngredient)
                }
                .padding()
            }
            .modifier(BackButtonModifier())
        }
    }

    private func saveIngredient() {
        if uploadViewModel.ingredients.count < 15 {
            let ingredient = Ingredient(quantity: quantityInput, item: ingredientInput)
            uploadViewModel.ingredients.append(ingredient)
            
            quantityInput = ""
            ingredientInput = ""
            updateSaveButtonState()
        }
    }
    
    private func deleteIngredient(at offsets: IndexSet) {
        uploadViewModel.ingredients.remove(atOffsets: offsets)
        updateSaveButtonState()
    }
    
    private func updateSaveButtonState() {
        isSaveButtonEnabled = !quantityInput.isEmpty && !ingredientInput.isEmpty && uploadViewModel.ingredients.count < 15
    }
}

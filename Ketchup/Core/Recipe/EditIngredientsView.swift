//
//  EditIngredientsView.swift
//  Ketchup
//
//  Created by Jack Robinson on 6/8/24.
//

import SwiftUI

struct EditIngredientsView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var ingredients: [Ingredient] = []
    @State private var quantityInput: String = ""
    @State private var ingredientInput: String = ""
    @State private var isSaveButtonEnabled: Bool = false
    
    var body: some View {
        NavigationView {
            VStack {
                HStack {
                    TextField("Quantity", text: $quantityInput)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 100)
                        .onChange(of: quantityInput) {
                            updateSaveButtonState()
                        }
                    
                    TextField("Ingredient", text: $ingredientInput)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .onChange(of: ingredientInput) {
                            updateSaveButtonState()
                        }
                    Button(action: saveIngredient) {
                        Text("Add")
                            .padding(.horizontal)
                            .foregroundColor(.white)
                            .background(isSaveButtonEnabled ? Color.blue : Color.gray)
                            .cornerRadius(8)
                    }
                    .disabled(!isSaveButtonEnabled)
                }
                .padding()
                
                List {
                    ForEach(ingredients.indices, id: \.self) { index in
                        Text("\(ingredients[index].quantity) \(ingredients[index].item)")
                    }
                    .onDelete(perform: deleteIngredient)
                }
                .listStyle(PlainListStyle())
                
                Spacer()
            }
            
        }
    }
    
    private func saveIngredient() {
        let ingredient = Ingredient(quantity: quantityInput, item: ingredientInput)
        ingredients.append(ingredient)
        
        quantityInput = ""
        ingredientInput = ""
        updateSaveButtonState()
    }
    
    private func deleteIngredient(at offsets: IndexSet) {
        ingredients.remove(atOffsets: offsets)
    }
    
    private func updateSaveButtonState() {
        isSaveButtonEnabled = !quantityInput.isEmpty && !ingredientInput.isEmpty
    }
}

#Preview {
    EditIngredientsView()
}

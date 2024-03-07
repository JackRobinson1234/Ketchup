//
//  MenuView.swift
//  Foodi
//
//  Created by Jack Robinson on 3/4/24.
//

import SwiftUI

struct EditRecipeView: View {
    @ObservedObject var viewModel: UploadPostViewModel
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
                    TextField("Add Ingredient...", text: $viewModel.ingredients[index], axis: .vertical)
                        .font(.subheadline)
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
                                .opacity(viewModel.isLastIngredientEmpty ? 0.5 : 1.0)
                            Text("Add Another Ingredient")
                                .font(.caption)
                                .opacity(viewModel.isLastIngredientEmpty ? 0.5 : 1.0)
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
                            .opacity(viewModel.isLastInstructionEmpty ? 0.5 : 1.0)
                        Text("Add a New Step")
                            .font(.caption)
                            .opacity(viewModel.isLastInstructionEmpty ? 0.5 : 1.0)
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


#Preview {
    EditRecipeView(viewModel: UploadPostViewModel(service: UploadPostService(), restaurant: nil))
}

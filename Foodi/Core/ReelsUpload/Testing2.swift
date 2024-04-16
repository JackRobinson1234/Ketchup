//
//  Testing2.swift
//  Foodi
//
//  Created by Joe Ciminelli on 4/15/24.
//

import SwiftUI

struct Testing2: View {
    @State private var recipeName: String = ""
    @State private var ingredients: String = ""
    @State private var steps: String = ""
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Edit Recipe")
                    .font(.title)
                    .bold()
                
                TextField("Recipe Name", text: $recipeName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                
                TextEditor(text: $ingredients)
                    .frame(height: 150)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray, lineWidth: 1))
                    .padding(.horizontal)
                    .background(Color.white) // Optional: for better visibility
                
                TextEditor(text: $steps)
                    .frame(height: 300)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray, lineWidth: 1))
                    .padding(.horizontal)
                    .background(Color.white) // Optional: for better visibility
                
                Button("Save") {
                    // Handle save action here
                    print("Recipe saved!")
                }
                .padding()
                .foregroundColor(.white)
                .background(Color.blue)
                .cornerRadius(8)
            }
            .padding()
        }
        .background(Image("recipe-background")
            .resizable()
            .scaledToFill()
            .opacity(0.6)) // Set a background that mimics a cookbook page
    }
}

#Preview {
    Testing2()
}

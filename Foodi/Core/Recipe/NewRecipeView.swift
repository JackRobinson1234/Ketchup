//
//  NewRecipeView.swift
//  Ketchup
//
//  Created by Jack Robinson on 6/3/24.
//

import SwiftUI

struct NewRecipeView: View {
    var post: Post
    var recipe: PostRecipe

    var body: some View {
        NavigationStack{
            ScrollView {
                VStack {
                    ZStack(alignment: .bottomLeading) {
                        ListingImageCarouselView(images: [post.thumbnailUrl])
                            .frame(height: 300) // Adjust height as needed
                            .clipped()
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text(recipe.name)
                                .font(.title)
                                .bold()
                                .foregroundColor(.white)
                            
                            HStack {
                                Text("by: @\(post.user.username)")
                                    .font(.subheadline)
                                    .foregroundColor(.white)
                                Spacer()
                                HStack(spacing: 0) {
                                    Image(systemName: "heart")
                                        .foregroundColor(.red)
                                    Text("\(post.likes)")
                                        .foregroundColor(.white)
                                }
                            }
                        }
                        .padding()
                        .background(LinearGradient(gradient: Gradient(colors: [Color.black.opacity(0.6), Color.clear]), startPoint: .bottom, endPoint: .top))
                    }
                    
                    // Red circle outline with white text for cooking time, difficulty, and serving number
                    HStack(spacing: 20) {
                        if let cookingTime = recipe.cookingTime{
                            InfoCircle(text: "\(cookingTime) min", image: "clock")
                        } else {
                            InfoCircle(text: "N/A", image: "clock")
                        }
                        if let servings = recipe.servings{
                            InfoCircle(text: "\(servings) servings", image: "person.3")
                        } else {
                            InfoCircle(text: "N/A", image: "person.3")
                        }
                        if let difficulty = recipe.difficulty{
                            InfoCircle(text: difficulty.text, image: "star")
                        } else {
                            InfoCircle(text: "N/A", image: "flame")
                        }
                    }
                    //.padding()
                    .padding(.horizontal)
                    .padding(.top)
                    
                    // Add more content as needed
                    if let ingredients = recipe.ingredients{
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Ingredients")
                                .font(.headline)
                            ForEach(ingredients, id: \.self) { ingredient in
                                HStack(alignment: .top, spacing: 4) {
                                    Text(ingredient.quantity)
                                        .bold()
                                        .foregroundStyle(.gray)
                                        .frame(width: 100, alignment: .leading) // Adjust width as needed
                                    Text(ingredient.item)
                                }
                                
                            }
                            if let instructions = recipe.instructions {
                                Text("Instructions")
                                    .font(.headline)
                                ForEach(instructions.indices, id: \.self) { index in
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Step \(index + 1)") // Index starts from 0, so add 1 for step count
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                            .padding(.bottom, 4)
                                        Text(instructions[index].title)
                                            .bold()
                                        Text(instructions[index].description)
                                    }
                                    
                                }
                                
                            }
                        }
                        .padding()
                    }
                }
                
            }
            .edgesIgnoringSafeArea(.all)
            .modifier(BackButtonModifier())
        }
       
    }
}
#Preview {
    NewRecipeView(post: DeveloperPreview.posts[0], recipe: DeveloperPreview.samplePostRecipe)
}



struct InfoCircle: View {
    var text: String
    var image: String
    
    var body: some View {
        VStack {
            Image(systemName: image)
                .font(.title)
                .foregroundColor(.black)
            
            Text(text)
                .foregroundColor(.black)
                .font(.subheadline)
        }
        .frame(width: 100, height: 100)
        .overlay(
                    Circle()
                        .stroke(Color("Colors/AccentColor"), lineWidth: 2)
                )
        
    }
}


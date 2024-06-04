//
//  NewRecipeView.swift
//  Ketchup
//
//  Created by Jack Robinson on 6/3/24.
//

import SwiftUI

struct NewRecipeView: View {
    var post: Post
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading) {
                    if let recipe = post.recipe {
                        ZStack(alignment: .bottomLeading) {
                            ListingImageCarouselView(images: [post.thumbnailUrl])
                                .frame(height: 300) // Adjust height as needed
                                .clipped()
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text(recipe.name)
                                    .font(.title)
                                    .bold()
                                    .foregroundColor(.white)
                                    .padding(.horizontal)
                                
                                HStack {
                                    Text("by: @\(post.user.username)")
                                        .font(.subheadline)
                                        .foregroundColor(.white)
                                    Spacer()
                                    HStack(spacing: 0) {
                                        Image(systemName: "heart")
                                            .foregroundColor(Color("Colors/AccentColor"))
                                        Text("\(post.likes)")
                                            .foregroundColor(.white)
                                    }
                                }
                                .padding(.horizontal)
                            }
                            .padding()
                            .background(LinearGradient(gradient: Gradient(colors: [Color.black.opacity(0.6), Color.clear]), startPoint: .bottom, endPoint: .top))
                        }
                        
                        // Red circle outline with white text for cooking time, difficulty, and serving number
                        HStack(spacing: 20) {
                            Spacer()
                            if let cookingTime = recipe.cookingTime {
                                InfoCircle(text: "\(cookingTime) min", image: "clock")
                            } else {
                                InfoCircle(text: "N/A", image: "clock")
                            }
                            if let servings = recipe.servings {
                                InfoCircle(text: "\(servings) servings", image: "person.3")
                            } else {
                                InfoCircle(text: "N/A", image: "person.3")
                            }
                            if let difficulty = recipe.difficulty {
                                InfoCircle(text: difficulty.text, image: "star")
                            } else {
                                InfoCircle(text: "N/A", image: "flame")
                            }
                            Spacer()
                        }
                        .padding(.horizontal)
                        .padding(.top)
                        
                        // Dietary restrictions
                        if let dietaryRestrictions = recipe.dietary, !dietaryRestrictions.isEmpty {
                            VStack(alignment: .leading) {
                                Text("Dietary Restrictions")
                                    .font(.headline)
                                HStack {
                                    ForEach(dietaryRestrictions, id: \.self) { restriction in
                                        DietaryRestrictionBox(text: restriction)
                                    }
                                }
                                .padding(.horizontal)
                                .padding(.horizontal)
                            }
                            .padding(.top)
                        } else {
                            Text("Dietary Restrictions")
                                .font(.headline)
                                .padding(.horizontal)
                                .padding(.horizontal)
                        }
                        
                        // Ingredients
                        Text("Ingredients")
                            .font(.headline)
                            .padding(.horizontal)
                            .padding(.horizontal)
                        if let ingredients = recipe.ingredients, !ingredients.isEmpty {
                            VStack(alignment: .leading, spacing: 16) {
                                
                                ForEach(ingredients, id: \.self) { ingredient in
                                    HStack(alignment: .top, spacing: 4) {
                                        Text(ingredient.quantity)
                                            .bold()
                                            .foregroundStyle(.gray)
                                            .frame(width: 100, alignment: .leading) // Adjust width as needed
                                        Text(ingredient.item)
                                    }
                                    .padding(.horizontal)
                                    .padding(.horizontal)
                                }
                            }
                            .padding(.top)
                        } else {
                            Text("None Listed")
                                .font(.subheadline)
                                .padding(.horizontal)
                                .padding(.horizontal)
                        }
                        
                        // Instructions
                        Text("Instructions")
                            .font(.headline)
                            .padding(.horizontal)
                            .padding(.horizontal)
                        if let instructions = recipe.instructions, !instructions.isEmpty {
                            VStack(alignment: .leading, spacing: 16) {
                                
                                ForEach(instructions.indices, id: \.self) { index in
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Step \(index + 1)")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                            .padding(.bottom, 4)
                                        Text(instructions[index].title)
                                            .bold()
                                        Text(instructions[index].description)
                                    }
                                    .padding(.horizontal)
                                    .padding(.horizontal)
                                }
                            }
                            .padding(.top)
                        } else {
                            Text("Instructions: None Listed")
                                .font(.subheadline)
                                .padding(.horizontal)
                                .padding(.horizontal)
                        }
                    }
                }
                .padding(.bottom, 16) // Add bottom padding to ensure last content is not cut off
            }
            .edgesIgnoringSafeArea(.top)
            .modifier(BackButtonModifier())
        }
    }
}
#Preview {
    NewRecipeView(post: DeveloperPreview.posts[0])
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

struct DietaryRestrictionBox: View {
    var text: String
    
    var body: some View {
        Text(text)
            .font(.subheadline)
            .padding(8)
            .background(Color.gray.opacity(0.2))
            .cornerRadius(8)
    }
}

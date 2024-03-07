//
//  RecipeView.swift
//  Foodi
//
//  Created by Jack Robinson on 3/7/24.
//
import SwiftUI
import Kingfisher

struct RecipeView: View {
    var post: Post
    @Environment(\.dismiss) var dismiss
    var body: some View {
        NavigationStack{
            ScrollView {
                // Thumbnail Image
                KFImage(URL(string: post.thumbnailUrl))
                    .resizable()
                    .scaledToFill()
                    .frame(height: 200)
                    .clipped()
                
                VStack(alignment: .leading, spacing: 16) {
                    // Recipe Title and User
                    Text(post.recipe?.name ?? "")
                        .font(.title)
                        .bold()
                    
                    Text("By: \(post.user.fullname)")
                        .font(.subheadline)
                    
                    // Cuisine, Time, and Dietary Restrictions
                    HStack {
                        Text(post.recipe?.cuisine ?? "Cuisine not specified")
                        Spacer()
                        Text("Time: \(formattedTime(time: post.recipe?.time ?? 0))")
                        Spacer()
                        Text("Dietary: \(formattedDietaryRestrictions(dietary: post.recipe?.dietary ?? []))")
                    }
                    .font(.subheadline)
                    
                    // Ingredients
                    Text("Ingredients:")
                        .font(.headline)
                    
                    ForEach(post.recipe?.ingredients ?? [], id: \.self) { ingredient in
                        Text("- \(ingredient)")
                    }
                    
                    // Instructions
                    Text("Instructions:")
                        .font(.headline)
                    
                    ForEach(post.recipe?.instructions ?? [], id: \.self) { instruction in
                        VStack(alignment: .leading) {
                            Text(instruction.title)
                                .font(.subheadline)
                                .bold()
                            
                            Text(instruction.description)
                                .font(.body)
                        }
                    }
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarTitle("Recipe Details", displayMode: .inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .foregroundStyle(.black)
                    }
                }
            }

        }
    }
    
    // Helper function to format time in hours and minutes
    private func formattedTime(time: Int) -> String {
        let hours = time / 60
        let minutes = time % 60
        var timeString = ""
        
        if hours > 0 {
            timeString += "\(hours)h"
        }
        
        if minutes > 0 {
            timeString += " \(minutes)m"
        }
        
        return timeString.isEmpty ? "Not specified" : timeString
    }
    
    // Helper function to format dietary restrictions
    private func formattedDietaryRestrictions(dietary: [String]) -> String {
        return dietary.isEmpty ? "Not specified" : dietary.joined(separator: ", ")
    }
}
#Preview {
    RecipeView(post: DeveloperPreview.posts[0])
}

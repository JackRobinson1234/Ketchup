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
                
                VStack(spacing: 16) {
                    // Recipe Title and User
                    Text(post.recipe?.name ?? "Title")
                        .font(.title)
                        .bold()
                    
                    
                    Text("By: \(post.user.fullname)")
                        .font(.subheadline)
                }
                    // Cuisine, Time, and Dietary Restrictions
                HStack {
                    VStack(alignment: .leading) {
                        Text("Cuisine: \(post.recipe?.cuisine ?? "Not specified")")
                        
                        Text("Time: \(formattedTime(time: post.recipe?.time ?? 0))")
                        
                        Text("Dietary: \(formattedDietaryRestrictions(dietary: post.recipe?.dietary ?? []))")
                    }
                    .font(.subheadline)
                    Spacer()
                }
                .padding()
                    // Ingredients
                VStack{
                    
                    Text("Ingredients")
                        .font(.title3)
                        .bold()
                    
                }
                .padding(.horizontal)
                VStack{
                    ForEach(post.recipe?.ingredients ?? [], id: \.self) { ingredient in
                        Text("- \(ingredient)")
                    }
                }
                    
                    // Instructions
                    Text("Instructions")
                        .font(.title3)
                        .bold()
                    
                if let instructions = post.recipe?.instructions {
                    ForEach(instructions.indices, id: \.self) { index in
                        VStack{
                            HStack{
                                Text("Step \(Int(index)+1): \(instructions[index].title)")
                                    .font(.subheadline)
                                    .foregroundColor(.black)
                                    .bold()
                                Spacer()
                                
                            }
                            Text("Step \(Int(index)+1) Description:  \(instructions[index].description)")
                                .font(.subheadline)
                        }
                        
                        
                        Divider()
                    }
                    .padding(.leading)
                }
                
                
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

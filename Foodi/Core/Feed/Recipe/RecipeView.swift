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
                
                VStack(spacing: 4) {
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
                        
                        Text("Dietary Restrictions: \(formattedDietaryRestrictions(dietary: post.recipe?.dietary ?? []))")
                        
                    }
                    .font(.subheadline)
                    Spacer()
                }
                .padding(.horizontal)
                    // Ingredients
                HStack{
                    
                    Text("Ingredients")
                        .font(.title2)
                        .bold()
                    Spacer()
                    
                }
                .padding([.horizontal, .top])
                HStack{
                    VStack (alignment: .leading){
                        ForEach(post.recipe?.ingredients ?? [], id: \.self) { ingredient in
                            Text("- \(ingredient)")
                                .font(.subheadline)
                        }
                    }
                    Spacer()
                }
                .padding(.horizontal)
                    
                HStack{
                    Text("Instructions")
                        .font(.title2)
                        .bold()
                    Spacer()
                }
                .padding([.horizontal,.top])
                VStack{
                    if let instructions = post.recipe?.instructions {
                        ForEach(instructions.indices, id: \.self) { index in
                            VStack{
                                HStack{
                                    Text("Step \(Int(index)+1)")
                                        .font(.title3)
                                        .bold()
                                    Spacer()
                                }
                                HStack{
                                    Text("\(instructions[index].title)")
                                        .font(.subheadline)
                                        .foregroundColor(.black)
                                        .bold()
                                        
                                    Spacer()
                                }
                                HStack{
                                    Text("\(instructions[index].description)")
                                        .font(.caption)
                                    Spacer()
                                }
                                
                            }
                            .padding([.horizontal])
                            
                            
                            Divider()
                        }
                    }
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
    RecipeView(post: DeveloperPreview.posts[1])
}

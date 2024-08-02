//
//  CaptionBox.swift
//  Foodi
//
//  Created by Jack Robinson on 5/14/24.
//

import SwiftUI

struct CaptionBox: View {
    @Binding var caption: String
    @Binding var isEditingCaption: Bool
    var title: String = "Enter a caption..."
    let maxCharacters = 150
    
    
    var body: some View {
        VStack {
            ScrollView {
                ZStack(alignment: .leading) {
                    
                    TextEditor(text: $caption)
                        .foregroundColor(caption.isEmpty ? .clear : .primary) // Hide text editor text when empty and showing placeholder
                        .disabled(true)  // Disables editing directly in this view
                        .frame(maxHeight: .infinity) // Allows for flexible height
                        .multilineTextAlignment(.leading)
                        .onTapGesture {
                            isEditingCaption = true // Activate editing mode
                        }
                    
                    
                    if caption.isEmpty {
                        Text(title)
                            .foregroundColor(.gray)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 8)
                    }
                }
            }
            .frame(height: 80)
            .padding(.horizontal)
            
            HStack {
                Spacer()
                Text("\(maxCharacters - caption.count) characters remaining")
                    .font(.custom("MuseoSansRounded-300", size: 10))
                    .foregroundColor(caption.count > maxCharacters ? Color("Colors/AccentColor") : .gray)
                    .padding(.horizontal, 10)
            }
        }
    }
}


//
//  CapationEditorView.swift
//  Foodi
//
//  Created by Jack Robinson on 5/14/24.
//

import SwiftUI

struct CaptionEditorView: View {
    @Binding var caption: String
    @Binding var isEditingCaption: Bool
    let maxCharacters = 150
    @FocusState var isFocused: Bool
    var title: String = "Caption"

    
    var body: some View {
        VStack {
            ZStack {
                VStack {
                    
                    HStack() {
                        Text(title)
                            .fontWeight(.bold)
                        
                        Spacer()
                        
                        Button {
                            isEditingCaption = false
                            isFocused = false
                        } label: {
                            Text("Done")
                                .fontWeight(.bold)
                                
                        }
                        .padding(8)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .padding(.horizontal, 10)
                        
                    }
                    .padding(.top, 10)
                    .frame(width: 330)
                    
                    Divider()
                    
                    TextEditor(text: $caption)
                        .font(.subheadline)
                        .background(Color.white)
                        .frame(width: 330, height: 150)
                        .focused($isFocused)
                    
                    HStack {
                        Spacer()
                        
                        Text("\(maxCharacters - caption.count) characters remaining")
                            .font(.caption)
                            .foregroundColor(caption.count > maxCharacters ? Color("Colors/AccentColor") : .gray)
                            .padding(.horizontal, 10)
                    }
                    
                }
                .onChange(of: caption) {
                    if caption.count > maxCharacters {
                        caption = String(caption.prefix(maxCharacters))
                    }
                }
                .padding(.bottom, 5)
                .frame(width: 350)
                .background(Color.white)
                .cornerRadius(10)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.8))
    }
}


//#Preview {
//    CapationEditorView()
//}

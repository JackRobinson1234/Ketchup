//
//  ReelsUploadView.swift
//  Foodi
//
//  Created by Joe Ciminelli on 4/6/24.
//

import SwiftUI

struct ReelsUploadView: View {
    
    @ObservedObject var cameraModel: ReelsCameraViewModel
    @State var caption: String = ""
    @State var postType: String = "At Home Post"
    
    @State private var selection = "Select Post Type"
    let postTypeOptions = ["At Home Post", "Going out Post"]
    @State private var dropdownShown = true
    
    
    var body: some View {
        
        
        ZStack {
            ScrollView {
                VStack {
                    
                    Rectangle()
                        .fill(.black)
                        .cornerRadius(30)
                        .frame(width: 200, height: 300)
                        .padding([.top, .bottom])
                    
                    CaptionBox(caption: $caption)
                    
                    Rectangle()
                        .frame(width: .infinity, height: 0.5)
                        .background(Color.white)
                        .foregroundColor(Color.black.opacity(0.3))
                    
                    Spacer()
                }
                .padding(.top, 60)
                .blur(radius: dropdownShown ? 10 : 0)
            }
        
            //  SELECT POST TYPE DROP DOWN
            VStack(spacing: 0) {
                // Dropdown header
                Button(action: {
                    if selection != "Select Post Type" {
                        dropdownShown.toggle()
                    } else {
                        print("ERROR PLEASE SELECT POST TYPE")
                    }
                }) {
                    HStack {
                        
                        Image(systemName: "chevron.down") // Downward arrow indicating a dropdown
                            .foregroundColor(.black)
                            .rotationEffect(.degrees(dropdownShown ? 180 : 0))
                            .hidden()
                        
                        Text(selection) // Displays the current selection
                            .font(.headline)
                            .foregroundColor(.black)
                        
                        
                        Image(systemName: "chevron.down") // Downward arrow indicating a dropdown
                            .foregroundColor(.black)
                            .rotationEffect(.degrees(dropdownShown ? 180 : 0)) // Arrow flips when dropdown is shown
                    }
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: 60) // Defines size of the clickable header area
                    .background(Color.white) // Sets background color of the dropdown header
                }
                
                if dropdownShown {
                    VStack(spacing: 0) {
                        
                        ForEach(postTypeOptions, id: \.self) { posttype in
                            
                            ZStack {
                                
                                Rectangle()
                                    .frame(width: .infinity, height: 1)
                                    .background(Color.white)
                                    .foregroundColor(Color.black.opacity(0.2))
                                
                            }

                            
                            Button(action: {
                                selection = posttype
                                if selection != "Select Post Type" {
                                    dropdownShown = false
                                }
                            }) {
                                if selection == posttype {
                                    HStack(spacing: 0) {
                                        
                                        Spacer()
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.black)
                                            .frame(maxWidth: .infinity, alignment: .center)
                                            .hidden()
                                        
                                        Text(posttype)
                                            .foregroundColor(.black)
                                            .frame(maxWidth: .infinity, alignment: .center)
                                            .padding(.top)
                                            .padding(.bottom)
                                        
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.black)
                                            .frame(maxWidth: .infinity, alignment: .center)
                                        Spacer()
                                    }
                                } else {
                                    Text(posttype)
                                        .foregroundColor(.black)
                                        .frame(maxWidth: .infinity, alignment: .center)
                                        .padding()
                                        
                                }
                            }
                            .background(Color.white)
                        }
                    }
                }
                
                Rectangle()
                    .frame(width: .infinity, height: 1)
                    .background(Color.white)
                    .foregroundColor(Color.black.opacity(0.1))
                
                Spacer() // Pushes everything else down
            }
        }
        .onAppear {
            withAnimation {
                dropdownShown = true
            }
        }
        .preferredColorScheme(.light)
    }
}

struct CaptionBox: View {
    
    @Binding var caption: String
    let maxCharacters = 150
    let maxLines = 8

    var body: some View {
        VStack {
            
            TextEditor(text: $caption)
                .font(.subheadline)
                .padding(5)
                .frame(height: 100)
                .background(Color.white)
                .cornerRadius(10)
                .overlay(
                    HStack {
                        VStack {
                            if caption.isEmpty {
                                Text("Enter your caption here...")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                    .padding(.top, 14)
                                    .padding(.horizontal, 10)
                                    .transition(.opacity)
                                    .allowsHitTesting(false)
                            }
                            Spacer()
                        }
                        Spacer()
                    }
                    
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.gray, lineWidth: 0.3)
                )
                .onChange(of: caption) { old, newValue in
                    let lineCount = newValue.components(separatedBy: "\n").count
                    if lineCount > maxLines || newValue.count > maxCharacters {
                        caption = String(caption.prefix(maxCharacters))
                        if caption.components(separatedBy: "\n").count > maxLines {
                            caption = caption.components(separatedBy: "\n")
                                            .prefix(maxLines)
                                            .joined(separator: "\n")
                        }
                    }
                }
                .padding(.bottom, 5)
                .padding(.horizontal, 20)

            
            HStack{
                Spacer()
                
                Text("\(maxCharacters - caption.count) characters remaining")
                    .font(.caption)
                    .foregroundColor(caption.count > maxCharacters ? .red : .gray)
                    .padding(.horizontal, 30)
                    .padding(.bottom, 10)
            }

            Spacer()
        }
        .frame(maxHeight: 150)
    }
}






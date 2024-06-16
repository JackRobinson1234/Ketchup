//
//  PostTypeMenuView.swift
//  Foodi
//
//  Created by Jack Robinson on 5/14/24.
//

import SwiftUI

struct PostTypeMenuView: View {
    
    @ObservedObject var uploadViewModel: UploadViewModel
    @Binding var showPostTypeMenu: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            Divider()
            
            Text("Select Post Type")
                .font(.headline)
                .fontWeight(.bold)
                .frame(height: 50)
            
            Divider()
                .frame(width: 260)
            
            HStack(spacing: 0) {
                Button(action: {
                    uploadViewModel.postType = .cooking
                    showPostTypeMenu = false
                }) {
                    VStack {
                        Image(systemName: "house.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 40)
                            .foregroundColor(.primary)
                            .opacity(0.6)
                                    
                        Text("Cooking Post")
                            .font(.subheadline)
                            .foregroundColor(.primary)
                    }
                    .frame(width: 130, height: 100)
                }
                
                Divider()
                    .frame(height: 100)
                
                Button(action: {
                    uploadViewModel.postType = .dining
                    showPostTypeMenu = false
                }) {
                    VStack {
                        Image(systemName: "fork.knife")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 40)
                            .foregroundColor(.primary)
                            .opacity(0.6)
                        
                        Text("Dining Post")
                            .font(.subheadline)
                            .foregroundColor(.primary)
                    }
                    .frame(width: 130, height: 100)
                }
            }
            
            Divider()
        }
        .frame(width: 260)
        .background(Color.white)
        .cornerRadius(10)
        .shadow(radius: 5)
    }
}


//#Preview {
//    PostTypeMenuView()
//}

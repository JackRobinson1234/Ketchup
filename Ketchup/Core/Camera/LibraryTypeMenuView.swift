//
//  LibraryTypeMenuView.swift
//  Ketchup
//
//  Created by Jack Robinson on 7/8/24.
//

import SwiftUI

struct LibraryTypeMenuView: View {
    
    @ObservedObject var uploadViewModel: UploadViewModel
    @Binding var showLibraryTypeMenu: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            Divider()
            
            Text("Select Media Type")
                .font(.custom("MuseoSansRounded-300", size: 18))
                .fontWeight(.bold)
                .frame(height: 50)
            
            Divider()
                .frame(width: 260)
            
            HStack(spacing: 0) {
                Button(action: {
                    showLibraryTypeMenu = false
                }) {
                    VStack {
                        Image(systemName: "video")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 40)
                            .foregroundColor(.black)
                            .opacity(0.6)
                                    
                        Text("Upload Videos")
                            .font(.custom("MuseoSansRounded-300", size: 16))
                            .foregroundColor(.black)
                    }
                    .frame(width: 130, height: 100)
                }
                
                Divider()
                    .frame(height: 100)
                
                Button(action: {
                    showLibraryTypeMenu = false
                }) {
                    VStack {
                        Image(systemName: "photo")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 40)
                            .foregroundColor(.black)
                            .opacity(0.6)
                        
                        Text("Upload Photos")
                            .font(.custom("MuseoSansRounded-300", size: 16))
                            .foregroundColor(.black)
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

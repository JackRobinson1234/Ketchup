//
//  InfoCircle.swift
//  Ketchup
//
//  Created by Jack Robinson on 6/8/24.
//

import SwiftUI

struct InfoCircle: View {
    var text: String
    var image: String
    var edit: Bool?
    
    var body: some View {
        VStack {
            VStack {
                Image(systemName: image)
                    .font(.title)
                    .foregroundColor(.primary)
                
                Text(text)
                    .foregroundColor(.primary)
                    .font(.subheadline)
            }
            .frame(width: 100, height: 100)
            .overlay(
                Circle()
                    .stroke(Color("Colors/AccentColor"), lineWidth: 2)
            )
            
            if let edit = edit, edit {
                Text("Edit")
                    .foregroundColor(.primary)
                    .font(.subheadline)
            }
        }
    }
}
#Preview {
    InfoCircle(text: "N/A", image: "flame", edit: true)
}

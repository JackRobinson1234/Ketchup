//
//  CreatePostSelection.swift
//  Foodi
//
//  Created by Jack Robinson on 2/5/24.
//

import SwiftUI

struct CreatePostSelection: View {
    var body: some View {
        HStack(spacing: 10){
            Image(systemName: "camera")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 50)
                .foregroundColor(.black)
            VStack (alignment: .leading){
                Text("Create a Post")
                    .font(.title3)
                    .bold()
                    .multilineTextAlignment(.leading)
                Text("Posts appear on the Discover Feed and on the selected restaurant's profile")
                    .font(.subheadline)
                    .multilineTextAlignment(.leading)
            }
            Image(systemName: "chevron.right")
                .foregroundStyle(.black)
            
        }
        .padding()
    }
}

#Preview {
    CreatePostSelection()
}

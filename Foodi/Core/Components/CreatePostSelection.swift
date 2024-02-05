//
//  CreatePostSelection.swift
//  Foodi
//
//  Created by Jack Robinson on 2/5/24.
//

import SwiftUI

struct CreatePostSelection: View {
    var body: some View {
        HStack{
            Image(systemName: "camera")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 50)
                .foregroundColor(.black)
            Text("Create a Post")
        }
    }
}

#Preview {
    CreatePostSelection()
}

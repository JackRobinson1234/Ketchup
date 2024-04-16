//
//  CreateCollectionButton.swift
//  Foodi
//
//  Created by Jack Robinson on 4/15/24.
//

import SwiftUI

struct CreateCollectionButton: View {
    var body: some View {
        HStack{
            Image(systemName: "plus")
                .resizable()
                .scaledToFit()
                .frame(width: 30, height: 30)
            VStack(alignment: .leading){
                Text("Create a New Collection")
                    .font(.title3)
            }
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundStyle(.black)
                .padding(.horizontal)
        }
        .padding(.horizontal)
    }
}

#Preview {
    CreateCollectionButton()
}

//
//  AddItemCollectionButton.swift
//  Foodi
//
//  Created by Jack Robinson on 4/15/24.
//

import SwiftUI

struct AddItemCollectionButton: View {
    var width: CGFloat
    var body: some View {
        ZStack{
            Rectangle()
                .frame(width: width, height: width + 25) // Height of the caption background, same as the individual cells
                .foregroundColor(Color.gray.opacity(0.1)) // Light yellow background with opacity
                .clipShape(RoundedRectangle(cornerRadius: 10))
            VStack{
                Image(systemName: "plus")
                    .padding()
            }
        }
    }
}

#Preview {
    AddItemCollectionButton(width : 20)
}

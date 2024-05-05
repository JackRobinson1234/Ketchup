//
//  ImageView.swift
//  Foodi
//
//  Created by Joe Ciminelli on 4/26/24.
//

import SwiftUI
import Kingfisher

struct ImageView: View {
    var urlStrings: [String]
    @State private var currentPage = 0

    var body: some View {
        
        ZStack {
            TabView(selection: $currentPage) {
                ForEach(urlStrings, id: \.self) { imageUrl in
                    KFImage(URL(string: imageUrl))
                        .resizable()
                        .scaledToFill()
                        .clipShape(Rectangle())  // Ensuring image fits within its container
                        .tag(urlStrings.firstIndex(of: imageUrl) ?? 0)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)  // Use full available space
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
            
            
            Button {
                print("tesetpres")
            } label: {
                Text("Hello button")
            }
        }
        
    }
}

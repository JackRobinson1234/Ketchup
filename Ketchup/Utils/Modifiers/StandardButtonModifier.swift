//
//  StandardButtonModifier.swift
//  Foodi
//
//  Created by Jack Robinson on 2/2/24.
//

import Foundation
import SwiftUI

struct StandardButtonModifier: ViewModifier {
    var width: CGFloat = 350
    func body(content: Content) -> some View {
        content
            .font(.custom("MuseoSansRounded-300", size: 16))
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .frame(width: width, height: 44)
            .background(Color("Colors/AccentColor"))
            .cornerRadius(8)
    }
}

struct OutlineButtonModifier: ViewModifier {
    var width: CGFloat = 350
    var borderColor: Color = Color("Colors/AccentColor")
    var borderWidth: CGFloat = 1

    func body(content: Content) -> some View {
        content
            .font(.custom("MuseoSansRounded-300", size: 16))
            .fontWeight(.semibold)
            .foregroundColor(.red)  // Set the text color to red
            .frame(width: width, height: 44)
            .background(Color.clear)  // Set the background to clear
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(borderColor, lineWidth: borderWidth)  // Add a red border
            )
            .cornerRadius(8)
    }
}

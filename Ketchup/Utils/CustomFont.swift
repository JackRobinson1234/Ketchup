//
//  CustomFont.swift
//  Ketchup
//
//  Created by Jack Robinson on 6/23/24.
//


import SwiftUI

struct CustomFont: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.custom("MuseoSansRounded-300", size: 16)) // Replace "MuseoSans" with the actual font name
    }
}

extension View {
    func customFont() -> some View {
        self.modifier(CustomFont())
    }
}

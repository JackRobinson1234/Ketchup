//
//  MapModifiers.swift
//  Foodi
//
//  Created by Jack Robinson on 4/9/24.
//

import Foundation
import SwiftUI
struct OverlayModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.custom("MuseoSans-500", size: 16))
            .foregroundColor(.primary)
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .foregroundColor(Color.white)
                    .opacity(0.5)
            )
    }
}

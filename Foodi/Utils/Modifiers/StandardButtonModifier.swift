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
            .font(.subheadline)
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .frame(width: width, height: 44)
            .background(Color(.systemBlue))
            .cornerRadius(8)
    }
}

//
//  StandardTextFieldModifier.swift
//  Foodi
//
//  Created by Jack Robinson on 2/2/24.
//

import Foundation
import SwiftUI

struct StandardTextFieldModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.custom("MuseoSans-500", size: 16))
            .padding(12)
            .background(Color(.systemGray6))
            .cornerRadius(10)
            .padding(.horizontal, 24)
    }
}

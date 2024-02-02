//
//  CollapsibleFilterViewModifier.swift
//  Foodi
//
//  Created by Jack Robinson on 2/2/24.
//

import Foundation
import Foundation
import SwiftUI

struct CollapsibleFilterViewModifier: ViewModifier {
    var frame: CGFloat = 120
    func body(content: Content) -> some View {
        content
            .frame(height: frame)
            .padding()
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding()
            .shadow(radius: 10)
    }
}

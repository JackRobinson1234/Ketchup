//
//  CollapsableDestination.swift
//  Foodi
//
//  Created by Jack Robinson on 2/2/24.
//

import Foundation
import SwiftUI

struct StandardFilterModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding()
            .frame(height: 180)
            .background(.white)
            .cornerRadius(12)
            .padding()
            .shadow(radius: 10)
    }
}

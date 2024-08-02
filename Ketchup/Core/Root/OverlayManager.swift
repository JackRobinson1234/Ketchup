//
//  OverlayManager.swift
//  Ketchup
//
//  Created by Jack Robinson on 8/1/24.
//

import Foundation
import SwiftUI
class OverlayManager: ObservableObject {
    @Published var isOverlayPresented = false
    
    func dismissOverlay() {
        withAnimation {
            isOverlayPresented = false
        }
    }
}

//
//  LockScreenView.swift
//  Ketchup
//
//  Created by Jack Robinson on 8/1/24.
//

import SwiftUI

struct LockScreenView: View {
    @EnvironmentObject var overlayManager: OverlayManager
    
    var body: some View {
        Color.black.edgesIgnoringSafeArea(.all)
            .overlay(
                VStack {
                    Text("This is the lock screen")
                        .foregroundColor(.white)
                    Button("Unlock") {
                        ////print("LockScreenView: Unlock button tapped")
                        overlayManager.dismissOverlay()
                    }
                    .foregroundColor(.green)
                }
            )
            .onAppear {
                ////print("LockScreenView: Appeared")
            }
    }
}

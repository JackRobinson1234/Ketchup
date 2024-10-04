//
//  PermissionDeniedView.swift
//  Ketchup
//
//  Created by Jack Robinson on 7/8/24.
//

import SwiftUI

struct PermissionDeniedView: View {
    
    var body: some View {
        VStack {
            Spacer()
            Text("Allow Ketchup to access camera and microphone")
                .font(.custom("MuseoSansRounded-300", size: 22))
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .foregroundColor(.red)
            
            Text("This will let you use the in app camera")
                .multilineTextAlignment(.center)
                .foregroundColor(.red)
                .opacity(0.8)
                .padding()
            Button(action: {
                openAppSettings()
            }) {
                Text("Open Settings")
                    .foregroundColor(Color("Colors/AccentColor"))
            }
            Spacer()
        }
    }
    
    func openAppSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
    
}
#Preview {
    PermissionDeniedView()
}

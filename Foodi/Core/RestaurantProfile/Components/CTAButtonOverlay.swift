//
//  CTAButtonOverlay.swift
//  Foodi
//
//  Created by Jack Robinson on 2/1/24.
//

import SwiftUI

struct CTAButtonOverlay: View {
    var body: some View {
        HStack{
            Spacer()
                Button{
                // Add Functionality
                } label: {
                    Text("Order Now")
                        .modifier(StandardButtonModifier(width: 175))
                }
            Button{
             // Add Functionality
            } label: {
                Text("Make a Reservation")
                    .modifier(StandardButtonModifier(width: 175))
            }
            Spacer()
        }
        .background(.white)
        .padding(.top)
    }
}

#Preview {
    CTAButtonOverlay()
}

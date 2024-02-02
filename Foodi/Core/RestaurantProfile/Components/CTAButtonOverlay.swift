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
                Button{
                    
                } label: {
                    Text("Order Now")
                        .modifier(StandardButtonModifier(width: 175))
                }
            Button{
                
            } label: {
                Text("Make a Reservation")
                    .modifier(StandardButtonModifier(width: 175))
            }
            
        }
        .background(.white)
    }
}

#Preview {
    CTAButtonOverlay()
}

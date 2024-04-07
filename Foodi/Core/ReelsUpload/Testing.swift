//
//  Testing.swift
//  Foodi
//
//  Created by Joe Ciminelli on 4/7/24.
//

import SwiftUI

struct Testing: View {
    
    @State var caption = ""
    @State var isPickingRestaurant = false
    
    var body: some View {
        
        VStack {
            CaptionBox(caption: $caption)
            
            Button {
                isPickingRestaurant.toggle()
            } label: {
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.gray, lineWidth: 5)
                    .padding()
                    
            }
            Spacer()
            
        }
        .sheet(isPresented: $isPickingRestaurant, content: {
            ScrollView {
                SearchView(userService: UserService(), searchConfig: .restaurants(restaurantListConfig: .upload))
            }
        })
        
        
    }
}




#Preview {
    Testing()
}

//
//  Testing.swift
//  Foodi
//
//  Created by Joe Ciminelli on 4/4/24.
//

import SwiftUI


struct TestView: View {
    var body: some View {
        
        ZStack {
            Rectangle()
                .frame(width: 400, height: 400)
            
            
            
            
            
            
            Circle()
                .stroke(.white, lineWidth: 5)
                .frame(width: 70, height: 70)
            
            Circle()
                .fill(.red)
                .frame(width: 60, height: 60)
        }
    }
}
    




struct Testing_Preview: PreviewProvider {
    static var previews: some View {
        TestView()
    }
}


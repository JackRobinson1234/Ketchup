//
//  RestaurantProfileView.swift
//  Foodi
//
//  Created by Jack Robinson on 2/2/24.
//

import SwiftUI

struct RestaurantProfileView: View {
    @Environment(\.dismiss) var dismiss
    @State var currentSection: Section
    init(currentSection: Section = .posts) {
        self._currentSection = State(initialValue: currentSection)}
    var body: some View {
        
        VStack{
            RestaurantProfileHeaderView(currentSection: $currentSection)
        }
        .navigationBarBackButtonHidden()
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .foregroundStyle(.black)
                }
            }
        }
        
        .overlay(alignment: .bottom) {
            CTAButtonOverlay()
    
        }
    }
}

#Preview {
    RestaurantProfileView()
}

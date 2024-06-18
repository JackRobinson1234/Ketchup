//
//  testing.swift
//  Ketchup
//
//  Created by Joe Ciminelli on 6/14/24.
//

import Foundation
import SwiftUI

struct TestView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        VStack {
            // Custom scrollable tabs
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    TabBarButton(text: "Video", isSelected: selectedTab == 0)
                        .onTapGesture {
                            withAnimation {
                                selectedTab = 0
                            }
                        }
                    TabBarButton(text: "Photo", isSelected: selectedTab == 1)
                        .onTapGesture {
                            withAnimation {
                                selectedTab = 1
                            }
                        }
                    TabBarButton(text: "Written", isSelected: selectedTab == 2)
                        .onTapGesture {
                            withAnimation {
                                selectedTab = 2
                            }
                        }
                }
                .padding()
                .background(Color.blue)
            }
            
            // Main content based on selected tab
            Group {
                if selectedTab == 0 {
                    Text("Camera View")
                } else if selectedTab == 1 {
                    Text("Story View")
                } else if selectedTab == 2 {
                    Text("Template View")
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

struct TabBarButton: View {
    let text: String
    let isSelected: Bool
    
    var body: some View {
        VStack {
            Text(text)
                .foregroundColor(isSelected ? .white : .gray)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
            if isSelected {
                Circle()
                    .frame(width: 6, height: 6)
                    .foregroundColor(.white)
            } else {
                Circle()
                    .frame(width: 6, height: 6)
                    .foregroundColor(.clear)
            }
        }
    }
}


#Preview {
    TestView()
}

//
//  ClusterCell.swift
//  Foodi
//
//  Created by Jack Robinson on 5/23/24.
//

import SwiftUI
import MapKit



struct ClusterCell: View {
    let cluster: ExampleClusterAnnotation
    var selectedRestaurantId: String?
    @State private var scale: CGFloat = 1.0
    @State private var opacity: CGFloat = 1.0
    @State private var strokeWidth: CGFloat = 2.0
    
    private var containsSelectedRestaurant: Bool {
        guard let selectedId = selectedRestaurantId else { return false }
        return cluster.memberAnnotations.contains { $0.restaurant.id == selectedId }
    }
    
    var body: some View {
        ZStack {
            // Background pulse effect
            Circle()
                .stroke(Color("Colors/AccentColor").opacity(0.3), lineWidth: strokeWidth)
                .frame(width: 30, height: 30)
                .scaleEffect(scale)
                .opacity(opacity)
            
            // Main cluster circle
            Circle()
                .fill(Color.white)
                .frame(width: 30, height: 30)
                .overlay(
                    Circle()
                        .stroke(Color("Colors/AccentColor"), lineWidth: 2)
                )
            
            Text("\(cluster.count)")
                .foregroundColor(.black)
                .font(.custom("MuseoSansRounded-300", size: 12))
        }
        .onChange(of: containsSelectedRestaurant) { isSelected in
            if isSelected {
                animateSelection()
            } else {
                resetAnimation()
            }
        }
    }
    
    private func animateSelection() {
        // Reset states
        scale = 1.0
        opacity = 1.0
        strokeWidth = 2.0
        
        // Subtle scale up with fade
        withAnimation(.easeInOut(duration: 0.3)) {
            scale = 1.15
            strokeWidth = 3.0
        }
        
        // Pulse effect
        withAnimation(
            .easeInOut(duration: 1.2)
            .repeatForever(autoreverses: true)
        ) {
            scale = 1.25
            opacity = 0.5
            strokeWidth = 1.0
        }
    }
    
    private func resetAnimation() {
        withAnimation(.easeOut(duration: 0.2)) {
            scale = 1.0
            opacity = 1.0
            strokeWidth = 2.0
        }
    }
}

struct LargeClusterCell: View {
    let cluster: LargeClusterAnnotation
    var selectedRestaurantId: String?
    @State private var scale: CGFloat = 1.0
    @State private var opacity: CGFloat = 1.0
    @State private var glowOpacity: CGFloat = 0.0
    
    private var containsSelectedRestaurant: Bool {
        guard let selectedId = selectedRestaurantId else { return false }
        return cluster.memberAnnotations.contains { $0.id == selectedId }
    }
    
    var body: some View {
        ZStack {
            // Outer glow effect
            Circle()
                .fill(Color("Colors/AccentColor"))
                .frame(width: 48, height: 48)
                .blur(radius: 8)
                .opacity(glowOpacity)
            
            // Main cluster circle
            Circle()
                .fill(Color("Colors/AccentColor"))
                .frame(width: 40, height: 40)
                .overlay(
                    Circle()
                        .stroke(Color.white, lineWidth: 2)
                )
            
            Text("\(cluster.count)")
                .foregroundColor(.white)
                .font(.custom("MuseoSansRounded-500", size: 14))
        }
        .scaleEffect(scale)
        .onChange(of: containsSelectedRestaurant) { isSelected in
            if isSelected {
                animateSelection()
            } else {
                resetAnimation()
            }
        }
    }
    
    private func animateSelection() {
        // Initial quick highlight
        withAnimation(.easeInOut(duration: 0.3)) {
            scale = 1.1
            glowOpacity = 0.4
        }
        
        // Continuous subtle pulse
        withAnimation(
            .easeInOut(duration: 1.5)
            .repeatForever(autoreverses: true)
        ) {
            scale = 1.15
            glowOpacity = 0.2
        }
    }
    
    private func resetAnimation() {
        withAnimation(.easeOut(duration: 0.2)) {
            scale = 1.0
            glowOpacity = 0.0
        }
    }
}
